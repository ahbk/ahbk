{
  description = "build svelte with nginx";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = rec {

      default = pkgs.stdenv.mkDerivation {
        name = "ahbk";
        src = self;
        buildInputs = [
          ahbk-web
        ];
        installPhase =
          let
            bin = ''
              #!/usr/bin/env bash
              ${pkgs.nodejs_18}/bin/node ${ahbk-web}/build
            '';
          in ''
            mkdir -p $out/bin
            echo '${bin}' > $out/bin/ahbk
            chmod +x $out/bin/ahbk
          '';
      };

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

        users.users."ahbk-web" = {
          isSystemUser = true;
          group = "ahbk-web";
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
        systemd.services.ahbk-web = {
          enable = true;
          description = "manage ahbk-web";
          unitConfig = {
            Type = "simple";
            After = [ "network-online.target" ];
            Requires = [ "network-online.target" ];
          };
          serviceConfig = {
            ExecStart = "${pkgs.nodejs_18}/bin/node ${self.packages.${system}.ahbk-web}/build";
            User = "ahbk-web";
            Group = "ahbk-web";
          };
          wantedBy = [ "multi-user.target" ];
        };
      };
    };
  };
}
