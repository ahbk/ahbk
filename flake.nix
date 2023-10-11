{
  description = "ahbk";

  inputs = {
  };

  outputs = { self }: {
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
          systemPackages = [ ];
        };
        services.nginx = {
          enable = true;
          virtualHosts."ahbk.ddns.net" = {
            addSSL = true;
            enableACME = true;
            root = "/var/www/ahbk.ddns.net";
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
