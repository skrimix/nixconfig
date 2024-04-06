{ lib, pkgs, config, ... }:
let cfg = config.services.corefreq;
in {
  options.services.corefreq = {
    enable = lib.mkEnableOption "corefreqd";
    package = lib.mkOption {
      default = config.boot.kernelPackages.corefreq;
      type = lib.types.package;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      packages = [ cfg.package ];
      services.corefreqd.wantedBy = [ "multi-user.target" ];
    };

    boot.kernelModules = [ cfg.package.moduleName ];
    boot.extraModulePackages = [ cfg.package ];

    environment.systemPackages = [ cfg.package ];
  };
}
