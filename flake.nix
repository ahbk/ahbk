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
        db_uri="postgresql+asyncpg://ahbk-api@/ahbk";
        log_level="warning";
        env="prod";
        api_home="${ahbk-api}/";
      };

      ahbk-api = let
        app = mkPoetryApplication {
          projectDir = "${self}/api";
          postInstall = ''
            cp -r ./alembic* $out/
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
      inherit (self.packages.${system}) ahbk-bin ahbk-web ahbk-env ahbk-api;
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
          systemPackages = [ ahbk-bin ];
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
                root = "${ahbk-web}";
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

        services.postgresql = {
          enable = true;
          ensureDatabases = [ "ahbk" ];
          ensureUsers = [
            {
              name = "ahbk-api";
              ensurePermissions = {
                "DATABASE ahbk" = "ALL PRIVILEGES";
              };
            }
          ];
        };

        systemd.services.ahbk-web = {
          description = "manage ahbk-web";
          serviceConfig = {
            ExecStart = "${pkgs.nodejs_18}/bin/node ${ahbk-web}/build";
            User = "ahbk-web";
            Group = "ahbk-web";
            EnvironmentFile="${ahbk-env}";
          };
          wantedBy = [ "multi-user.target" ];
        };

        systemd.services.ahbk-migrations = {
          description = "migrate ahbk-db";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${ahbk-api}/bin/setup";
            User = "ahbk-api";
            Group = "ahbk-api";
            EnvironmentFile="${ahbk-env}";
          };
          wantedBy = [ "multi-user.target" ];
          before = [ "ahbk-api.service" ];
        };

        systemd.services.ahbk-api = {
          description = "manage ahbk-api";
          serviceConfig = {
            ExecStart = "${ahbk-api}/bin/uvicorn ahbk_api.main:app";
            User = "ahbk-api";
            Group = "ahbk-api";
            EnvironmentFile="${ahbk-env}";
          };
          wantedBy = [ "multi-user.target" ];
        };
      };
    };
  };
}
