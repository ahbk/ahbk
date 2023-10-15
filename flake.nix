{
  description = "build nginx with proxies for svelte and uvicorn";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";

    poetry2nix = {
      url = "github:ahbk/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs = { self, nixpkgs, poetry2nix, ... }: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (poetry2nix.legacyPackages.${system}) mkPoetryApplication;
  in {
    packages.${system} = rec {

      default = ahbk-bin;

      ahbk-bin = pkgs.substituteAll {
        src = "${self}/bin/ahbk";
        dir = "bin";
        isExecutable = true;
        nodejs_18=pkgs.nodejs_18;
        ahbk_web=ahbk-web;
        ahbk_api=ahbk-api;
        ahbk_env=ahbk-env;
      };

      ahbk-env = pkgs.substituteAll {
        src = "${self}/env/.env";
        secret_key = "732ac51775b8761c1a1c553a737ce297352496a5f1f56e96";
        db_uri="postgresql-asyncpg://ahbk:secret@localhost:5432/ahbk";
        loglevel=0;
      };

      ahbk-api = let
        app = mkPoetryApplication {
          projectDir = "${self}/api";
          postInstall = ''
            echo 'asdf > $out/asdf
            '';
        };
      in app.dependencyEnv;

      ahbk-web = pkgs.yarn2nix-moretea.mkYarnPackage rec {
        name = "ahbk-web";
        src = "${self}/web";
        offlineCache = pkgs.fetchYarnDeps {
          yarnLock = src + "/yarn.lock";
          hash = "sha256-Aktm+nQOoj0bLjjNsm182u3R0bJQLQzVidDh3794evs=";
        };
        distPhase = "true";
        configurePhase = ''
          ln -s $node_modules node_modules
        '';
        buildPhase = ''
          export HOME=$(mktemp -d)
          yarn --offline build
        '';
        installPhase = ''
          cp -r . $out
          '';

        nativeBuildInputs = [
          pkgs.nodejs_18
          pkgs.yarn
        ];
      };
    };

    nixosModules.default = { config, lib, ... }:
    let
      inherit (lib) mkOption types mkIf;
      cfg = config.ahbk;
    in {

      options.ahbk = {
        enable = mkOption {
          type = types.bool;
          default = false;
        };
      };

      config = mkIf cfg.enable {
        environment = {
          systemPackages = [ self.packages.${system}.default ];
        };

        services.nginx = {
          enable = true;
          virtualHosts."ahbk.ddns.net" = {
            addSSL = true;
            enableACME = true;
            locations = {
              "/" = {
                recommendedProxySettings = true;
                proxyPass = "http://localhost:3000";
              };
              "/api" = {
                recommendedProxySettings = true;
                proxyPass = "http://localhost:8000";
              };
              "/public" = {
                root = "/var/www/ahbk.ddns.net";
              };
              "/static" = {
                root = "${self.packages.${system}.ahbk-web}";
              };
            };
          };
        };
        security.acme = {
          acceptTerms = true;
          defaults.email = "alxhbk@proton.me";
        };
        networking.firewall.allowedTCPPorts = [ 80 443 ];

        users = rec {
          users."ahbk-web" = {
            isSystemUser = true;
            group = "ahbk-web";
            uid = 993;
          };
          groups."ahbk-web".gid = users."ahbk-web".uid;

          users."ahbk-api" = {
            isSystemUser = true;
            group = "ahbk-api";
            uid = 994;
          };
          groups."ahbk-api".gid = users."ahbk-api".uid;
        };

        systemd.services.ahbk-web = {
          enable = true;
          description = "manage ahbk-web";
          serviceConfig = {
            ExecStart = "${pkgs.nodejs_18}/bin/node ${self.packages.${system}.ahbk-web}/build";
            User = "ahbk-web";
            Group = "ahbk-web";
          };
          wantedBy = [ "multi-user.target" ];
        };

        systemd.services.ahbk-api = {
          enable = true;
          description = "manage ahbk-api";
          serviceConfig = {
            ExecStart = "${self.packages.${system}.ahbk-api}/bin/uvicorn ahbk_api.main:app";
            User = "ahbk-api";
            Group = "ahbk-api";
          };
          wantedBy = [ "multi-user.target" ];
        };
      };
    };
  };
}
