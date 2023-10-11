{
  description = "ahbk";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      name = "ahbk";
      src = self;
      installPhase = ''
        mkdir $out
        cp -R ./public $out/
        '';
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
            root = "${self.packages.${system}.default.out}/public";
          };
        };
        security.acme = {
          acceptTerms = true;
          defaults.email = "alxhbk@proton.me";
        };
      };
    };
  };
}
