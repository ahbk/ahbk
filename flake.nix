{
  description = "ahbk";

  inputs = {
  };

  outputs = { self }: {
    nixosModules.default = { config, lib, ... }: {
      options.ahbk = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
      config = {};
    };
  };
}
