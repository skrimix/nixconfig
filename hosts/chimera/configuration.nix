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
      options = "--delete-older-than 7d";
    };

    daemonCPUSchedPolicy = "idle";
  };

  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelPackages = pkgs.linuxPackagesOverride pkgs.linuxPackages_zen;
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
    hostName = "chimera";
    networkmanager = {
      enable = true;
      # randomize MAC address (per connection and boot)
      ethernet.macAddress = "stable";
      wifi.macAddress = "stable";
      settings.connection."connection.stable-id" = ''''${CONNECTION}/''${BOOT}"'';
    };
    
    firewall.enable = false;
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

    user.services = { };
    user.timers = { };
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

    systembus-notify.enable = true; # for earlyoom notifications

    earlyoom = {
      enable = true;
      enableNotifications = true;
      freeMemThreshold = 5;
      freeSwapThreshold = 5;
      freeMemKillThreshold = 2;
      freeSwapKillThreshold = 2;
    };

    fstrim.enable = true;
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
    cht-sh
    mission-center
    jq
    p7zip
    filezilla
    meld
    libreoffice-qt
    onlyoffice-bin_latest
    openrgb-with-all-plugins
    xwaylandvideobridge
    ddcutil
    aria
    rclone
    squirreldisk
    any-nix-shell # keep zsh in nix-shell
    libnotify # notify-send
    usbutils # lsusb
    pulseaudio # pactl for output switching
    qpwgraph # Qt graph manager for PipeWire
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
    atuin # shell history
    dust # better df/du
    bat # better cat

    # Media
    spotify
    (mpv.override { scripts = with mpvScripts; [ thumbfast uosc sponsorblock mpris quality-menu ]; })
    mpv-handler
    yt-dlp
    duplicacy

    # Browsers
    brave
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
    jetbrains.rider
    dotnetCorePackages.sdk_8_0
    imhex
    # Drag and drop does not work in Wayland
    # https://github.com/microsoft/vscode/issues/156723
    (vscode.override { commandLineArgs = "-enable-features=UseOzonePlatform --ozone-platform=x11"; }).fhs
    arduino-ide
    diffuse # graphical file compare tool

    # Wallets
    monero-gui
    electrum
    electrum-ltc

    # Gaming
    wineWowPackages.waylandFull
    winetricks

    # Hardware monitoring
    lm_sensors
    dmidecode

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
    ];
  };

  virtualisation = {
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
    corefreq.enable = true;
  };

  programs = {
    dconf.enable = true;
    adb.enable = true;
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
    appimage = {
      enable = true;
      binfmt = true;
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

