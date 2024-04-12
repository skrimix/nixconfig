{ lib, pkgs, config, ... }:
let cfg = config.services.noisetorch;
in {
  options.services.noisetorch = {
    enable = lib.mkEnableOption "noisetorch";
    deviceUnit = lib.mkOption {
      type = lib.types.str;
      description = "Systemd unit to start noisetorch after";
    };
    deviceId = lib.mkOption {
      type = lib.types.str;
      description = "Input device ID";
    };
    afterPipewire = lib.mkOption {
      type = lib.types.bool;
      default = config.services.pipewire.enable;
      description = "Start noisetorch after pipewire";
    };
    afterPulseaudio = lib.mkOption {
      type = lib.types.bool;
      default = config.hardware.pulseaudio.enable;
      description = "Start noisetorch after pulseaudio";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.noisetorch.enable = true;
    systemd.user.services.noisetorch = {
      description = "Noisetorch Noise Cancelling";
      requires = [ cfg.deviceUnit ];
      after = [ cfg.deviceUnit ]
        ++ lib.optionals cfg.afterPipewire [ "pipewire.service" ]
        ++ lib.optionals cfg.afterPulseaudio [ "pulseaudio.service" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "/run/wrappers/bin/noisetorch -i -s ${cfg.deviceId} -t 90";
        ExecStop = "/run/wrappers/bin/noisetorch -u";
        Restart = "on-failure";
        RestartSec = "3";
      };
    };
  };
}
