# This is dumb, but the issue with XKB is dumber (20 years!)
# https://gitlab.freedesktop.org/xorg/xserver/-/issues/258
# https://github.com/xkbcommon/libxkbcommon/issues/420
{ config, lib, pkgs, ... }:

let
  script = pkgs.writers.writePython3 "kb-switch"
    {
      libraries = with pkgs.python311Packages; [ dbus-python evdev ];
      flakeIgnore = [ "E501" "E265" ];
    }
    (builtins.readFile ./kb-switch.py);
in
{
  config.systemd.services.kb-switch = {
    enable = true;
    description = "Keyboard layout switch daemon";

    wantedBy = [ "graphical.target" ];
    wants = [ "graphical.target" ];
    after = [ "graphical.target" ];

    path = with pkgs; [ procps ];

    serviceConfig = {
      ExecStart = "${script}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
