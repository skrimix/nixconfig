# Taken from PR https://github.com/NixOS/nixpkgs/pull/294641
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkPackageOption mkOption mkIf types optionalString;
  cfg = config.services.sunshine;

  # ports used are offset from a single base port, see https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port
  generatePorts = port: offsets: map (offset: port + offset) offsets;
  defaultPort = 47989;

  appsFormat = pkgs.formats.json { };
  settingsFormat = pkgs.formats.keyValue { };

  appsFile = appsFormat.generate "apps.json" cfg.applications;
  configFile = settingsFormat.generate "sunshine.conf" (cfg.settings // (if cfg.applications.apps == [ ] then { } else { file_apps = appsFile; }));
in
{
  options = {
    services.sunshine = with types; {
      enable = mkEnableOption "Sunshine, a self-hosted game stream host for Moonlight";
      package = mkPackageOption pkgs "sunshine" { };
      openFirewall = mkOption {
        type = bool;
        default = false;
        description = ''
          Whether to automatically open ports in the firewall.
        '';
      };
      settings = mkOption {
        default = { };
        description = ''
          Settings to be rendered into the configuration file. If this is set, no configuration is possible from the web UI.

          See https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#configuration for syntax.
        '';
        example = ''
          {
            sunshine_name = "nixos";
          }
        '';
        type = submodule (settings: {
          freeformType = settingsFormat.type;
          options.port = mkOption {
            type = port;
            default = defaultPort;
            description = ''
              Base port -- others used are offset from this one, see https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port for details.
            '';
          };
        });
      };
      applications = mkOption {
        default = { };
        description = ''
          Configuration for applications to be exposed to Moonlight. If this is set, no configuration is possible from the web UI, and must be by the `settings` option.
        '';
        example = ''
          {
            env = {
              PATH = "$(PATH):$(HOME)/.local/bin";
            };
            apps = [
              {
                name = "1440p Desktop";
                prep-cmd = [
                  {
                    do = "''${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-4.mode.2560x1440@144";
                    undo = "''${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor output.DP-4.mode.3440x1440@144";
                  }
                ];
                exclude-global-prep-cmd = "false";
                auto-detach = "true";
              }
            ];
          }
        '';
        type = submodule {
          options = {
            env = mkOption {
              default = { };
              description = ''
                Environment variables to be set for the applications.
              '';
              type = attrsOf str;
            };
            apps = mkOption {
              default = [ ];
              description = ''
                Applications to be exposed to Moonlight.
              '';
              type = listOf attrs;
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = generatePorts cfg.settings.port [ (-5) 0 1 21 ];
      allowedUDPPorts = generatePorts cfg.settings.port [ 9 10 11 13 21 ];
    };

    boot.kernelModules = [ "uinput" ];

    services.udev.extraRules = ''
      KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
    '';

    security.wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${cfg.package}/bin/sunshine";
    };

    systemd.user.services.sunshine = {
      description = "Self-hosted game stream host for Moonlight";

      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];

      startLimitIntervalSec = 500;
      startLimitBurst = 5;

      serviceConfig = {
        # only add configFile if an application or a setting other than the default port is set to allow configuration from web UI
        ExecStart = "${config.security.wrapperDir}/sunshine"
          + (optionalString (cfg.applications.apps != [ ] || (builtins.length (builtins.attrNames cfg.settings) > 1 || cfg.settings.port != defaultPort)) " ${configFile}");
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
