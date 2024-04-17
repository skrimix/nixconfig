# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };

    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;
  system.autoUpgrade = {
    enable = true;
    randomizedDelaySec = "30min";
    #flake = "path:${inputs.self.outPath}";
    flake = "path:/home/skrimix/.nix";
    flags = [
      "-L" # print build logs
      "--update-input"
      "nixpkgs"
      "--commit-lock-file"
    ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackagesOverride pkgs.linuxPackages_zen;
    extraModulePackages = with config.boot.kernelPackages; [ vmware ];
    tmp.cleanOnBoot = true;
    supportedFilesystems = [ "ntfs" ];
    loader = {
      timeout = 0;
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        editor = false;
      };
    };

    kernelModules = [ "tcp_bbr" "i2c-dev" ];
    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "cake";
      "net.core.wmem_max" = 1073741824;
      "net.core.rmem_max" = 1073741824;
      "net.ipv4.tcp_rmem" = "4096 87380 1073741824";
      "net.ipv4.tcp_wmem" = "4096 87380 1073741824";

      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.core.netdev_max_backlog" = 16384;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.ip_unprivileged_port_start" = 0;

      # SysRq
      # enable control of keyboard (SAK, unraw)
      # enable sync command
      # enable remount read-only
      # enable signalling of processes (term, kill, oom-kill)
      # allow reboot/poweroff
      "kernel.sysrq" = 246;

      "kernel.hung_task_timeout_secs" = 20;
    };
  };

  time.timeZone = "Asia/Yekaterinburg";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "ru_RU.UTF-8";
      LC_MEASUREMENT = "ru_RU.UTF-8";
      LC_MONETARY = "ru_RU.UTF-8";
      LC_NAME = "ru_RU.UTF-8";
      LC_PAPER = "ru_RU.UTF-8";
      LC_TELEPHONE = "ru_RU.UTF-8";
      LC_TIME = "ru_RU.UTF-8";
    };
  };

  networking = {
    hostName = "nyx";
    networkmanager.enable = true;
    firewall.enable = false;

    proxy = {
      default = "http://127.0.0.1:10080/";
      noProxy = "127.0.0.1,localhost,internal.domain,.lan";
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    opengl.driSupport32Bit = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true; # enable device power reporting
        };
      };
    };
    sane = {
      enable = true;
      brscan4.enable = true;
      #extraBackends = [ pkgs.sane-airscan ];
      netConf = "192.168.1.146";
      disabledDefaultBackends = [ "escl" ];
    };
  };

  services.udev = {
    packages = with pkgs; [ ];
    extraRules = ''
      # Enable TRIM for external SSD
      ACTION=="add|change", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="9210", SUBSYSTEM=="block", ATTR{../../scsi_disk/*/provisioning_mode}="unmap"

      # NVMe SSD
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
    '';
  };

  systemd = {
    extraConfig = ''
      DefaultTimeoutStopSec=20s
    '';

    additionalUpstreamSystemUnits = [
      "soft-reboot.target"
      "systemd-soft-reboot.service"
    ];

    # disable service
    services.ollama.wantedBy = lib.mkForce [ ];

    services.nixos-upgrade.environment = lib.mkForce {
      all_proxy = "";
      ftp_proxy = "";
      http_proxy = "";
      https_proxy = "";
      rsync_proxy = "";
    };

    services.docker.environment = lib.mkForce {
      all_proxy = "";
      ftp_proxy = "";
      http_proxy = "";
      https_proxy = "";
      rsync_proxy = "";
    };

    user.services = {
      conky = {
        description = "Conky daemon";
        #wantedBy = [ "graphical-session.target" ];
        #partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.conky}/bin/conky -c /home/skrimix/.config/conky/lean-conky-config/conky.conf";
        };
        path = [ pkgs.fontconfig pkgs.iproute2 pkgs.util-linux pkgs.wget pkgs.amdgpu_top pkgs.coreutils-full pkgs.python3 ];
      };

      /* fsearch_update_database = {
        description = "FSearch - Update database";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.fsearch}/bin/fsearch --update-database";
        };
      }; */

      sillytavern = {
        description = "SillyTavern";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          WorkingDirectory = "/mnt/netac/textgen/SillyTavern";
          ExecStart = "/run/current-system/sw/bin/nix-shell -p nodejs_20 --command \"node server.js --disableCsrf\"";
        };
      };

      duplicacy-backup-user = {
        description = "Duplicacy backup for user directory";
        serviceConfig = {
          Type = "simple";
          WorkingDirectory = "%h";
          ExecStart = "${pkgs.duplicacy}/bin/duplicacy backup -stats -threads 16";
        };
      };
    };

    user.timers = {
      /* fsearch_update_database = {
        description = "FSearch - Periodically update database";
        wantedBy = [ "basic.target" ];
        timerConfig = {
          OnBootSec = "1h";
          OnUnitActiveSec = "3h";
          Unit = "fsearch_update_database.service";
        };
      }; */
      duplicacy-backup-user = {
        description = "Run daily Duplicacy backup for user directory";
        wantedBy = [ "basic.target" ];
        timerConfig = {
          Persistent = true;
          OnCalendar = "daily";
          Unit = "duplicacy-backup-user.service";
        };
      };
    };
  };


  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/disable-idle-timeout.conf" ''
        monitor.alsa.rules = [
          {
            matches = [
              { node.name = "~alsa_input.*" }
              { node.name = "~alsa_output.*" }
            ]
            actions = {
              update-props = {
                session.suspend-timeout-seconds = 0
              }
            }
          }
        ]
      '')
    ];
  };


  services = {
    # replace kernel console with kmscon
    kmscon = {
      enable = true;
      hwRender = true;
    };

    # SDDM + Plasma 6
    xserver.enable = true;
    displayManager = {
      sddm = {
        enable = true;
        autoNumlock = true;
        settings = {
          Autologin = {
            # auto-lock right after login instead
            Session = "plasma.desktop";
            User = "skrimix";
          };
        };
        wayland.enable = true;
      };
      defaultSession = "plasma";
    };
    desktopManager.plasma6.enable = true;

    zerotierone = {
      enable = true;
      joinNetworks = [ "d5e5fb653733c070" ];
    };

    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };

    earlyoom = {
      enable = true;
      enableNotifications = false; # waiting for https://github.com/NixOS/nixpkgs/pull/280054
      freeMemThreshold = 5;
      freeSwapThreshold = 5;
      freeMemKillThreshold = 2;
      freeSwapKillThreshold = 2;
    };
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # enable wayland for programs that support it
    SSH_ASKPASS_REQUIRE = "prefer"; # use askpass even in terminal
  };

  xdg.portal = {
    enable = true;

    # fix opening links in vscode-fhs
    config.common.default = "*";
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk # needed for gnome apps in flatpak?
    ];
  };

  # fix Plasma integration in Brave Browser
  environment.etc."chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  # Outdated application menu is better than Plasma falling apart
  #system.userActivationScripts.rebuildSycoca = lib.mkForce "";

  users = {
    users.skrimix = {
      isNormalUser = true;
      extraGroups = [ "wheel" "adbusers" "networkmanager" "scanner" "libvirtd" "gamemode" "dialout" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGknvPNFi62TmeSZBGklGX+nlM+tSaLJizResYf81Itd skrimix"
      ];
      packages = with pkgs; [
      ];
    };
  };


  environment.systemPackages = with pkgs; [
    vim
    wget
    rar
    zip
    unzip
    lsof
    htop
    btop
    file
    glances
    gparted
    btdu
    compsize
    telegram-desktop
    neofetch
    fzf
    zoxide
    tree
    nekoray
    cht-sh
    mission-center
    jq
    p7zip
    filezilla
    meld
    libreoffice-qt
    onlyoffice-bin_latest
    openrgb-with-all-plugins
    sidequest
    xwaylandvideobridge
    ddcutil
    aria
    rclone
    squirreldisk
    any-nix-shell # keep zsh in nix-shell
    libnotify # notify-send
    usbutils # lsusb
    wl-clipboard # For WayDroid clipboard sharing
    pulseaudio # pactl for output switching
    vesktop # Discord
    ((nnn.override { withNerdIcons = true; }).overrideAttrs (finalAttrs: previousAttrs: {
      # "Buffer overflow detected" crash
      hardeningDisable = [ "fortify3" ];
    }))
    fsearch
    distrobox
    resources
    ookla-speedtest
    discover-wrapped # KDE Discover (Flatpak only)
    kdiskmark

    # Media
    spotify
    (mpv.override { scripts = with mpvScripts; [ thumbfast uosc sponsorblock mpris quality-menu ]; })
    mpv-handler
    vlc
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-vkcapture
      ];
    })
    yt-dlp
    gimp
    upscayl
    duplicacy

    # Browsers
    brave
    chromium
    firefox-esr
    (librewolf.override { nativeMessagingHosts = [ kdePackages.plasma-browser-integration ]; })

    # Dev
    (python3.withPackages (python-pkgs: [
      python-pkgs.pip
      python-pkgs.requests
    ]))
    nixpkgs-fmt
    git
    gh
    github-desktop
    burpsuite
    android-studio
    #(jetbrains.plugins.addPlugins jetbrains.rider [ "github-copilot" ])
    jetbrains.rider
    dotnetCorePackages.sdk_8_0
    imhex
    jadx
    ghidra
    # Drag and drop does not work in Wayland
    # https://github.com/microsoft/vscode/issues/156723
    (vscode.override { commandLineArgs = "-enable-features=UseOzonePlatform --ozone-platform=x11"; }).fhs
    mongodb-compass
    arduino-ide
    diffuse # graphical file compare tool

    # Wallets
    monero-gui
    electrum
    electrum-ltc
    feather

    # Gaming
    wineWowPackages.waylandFull
    winetricks
    #bottles
    mangohud
    protontricks
    lutris
    protonup-qt
    goverlay

    # Hardware monitoring
    #(conky.override { waylandSupport = true; })
    lm_sensors
    dmidecode

    # AMD GPU
    nvtopPackages.amd
    amdgpu_top

    # KDE Info Center deps
    pciutils
    mesa-demos
    clinfo
    vulkan-tools
    wayland-utils
  ] ++ (with pkgs.kdePackages; [
    baloo
    ktexteditor
    kate
    yakuake
    spectacle
    ksystemlog
    kalk
    kcalc
    skanpage
    skanlite
    kleopatra
    ktorrent
    filelight
    krdc
    isoimagewriter
  ]);

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      #corefonts
      roboto
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      (nerdfonts.override { fonts = [ "CascadiaCode" "JetBrainsMono" ]; })

      # Custom packages
      apple-fonts
      windows-fonts
      #leanconkyconfig-font
    ];
  };

  virtualisation = {
    waydroid.enable = true;
    vmware.host.enable = true;
    libvirtd = {
      enable = true;
      onBoot = "ignore";
    };
    docker = {
      enable = true;
      autoPrune.enable = true;
      # rootless = {
      #   enable = true;
      #   setSocketVariable = true;
      # };
    };
  };

  services = {
    printing.enable = true;
    dbus.enable = true;
    flatpak.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
    sunshine.enable = true;
    ollama = {
      enable = true;
      #acceleration = "rocm";
    };
    #hardware.openrgb.enable = true;
    corefreq.enable = true;
    noisetorch = {
      enable = true;
      deviceUnit = "sys-devices-pci0000:00-0000:00:08.1-0000:2a:00.4-sound-card1-controlC1.device";
      deviceId = "alsa_input.pci-0000_2a_00.4.analog-stereo";
    };
  };

  programs = {
    dconf.enable = true;
    adb.enable = true;
    chromium = {
      enable = true;
      enablePlasmaBrowserIntegration = true;
    };
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "skrimix" ];
    };
    partition-manager.enable = true;
    kdeconnect.enable = true;
    zsh.enable = true;
    nix-index = {
      enable = true;
      enableZshIntegration = false;
      enableFishIntegration = false;
      enableBashIntegration = false;
    };
    steam.enable = true;
    ssh.startAgent = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        fuse3
        icu
        zlib
        nss
        openssl
        curl
        expat
        fontconfig
        xorg.libX11
        xorg.libICE
        xorg.libSM
      ];
    };
    virt-manager.enable = true;
    direnv.enable = true;
    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          desiredgov = "powersave";
          renice = 5;
        };
        gpu = {
          gpu_device = 1;
          apply_gpu_optimisations = "accept-responsibility";
          amd_performance_level = "high";
        };
      };
    };
    coolercontrol.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
      # fix warning until 291577 is merged
      package = pkgs.appimage-run.overrideAttrs (oldAttrs: {
        meta.mainProgram = "appimage-run";
      });
    };
  };

  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (
          subject.isInGroup("users")
            && (
              action.id == "org.freedesktop.login1.reboot" ||
              action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
              action.id == "org.freedesktop.login1.power-off" ||
              action.id == "org.freedesktop.login1.power-off-multiple-sessions"
            )
          )
        {
          return polkit.Result.YES;
        }
      })
    '';
  };


  # Do not change without a good reason
  system.stateVersion = "23.11";
}

