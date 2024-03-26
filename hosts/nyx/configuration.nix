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
    kernelPackages = pkgs.linuxPackages_zen;
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

      # SysRq
      # enable control of keyboard (SAK, unraw)
      # enable sync command
      # enable signalling of processes (term, kill, oom-kill)
      # allow reboot/poweroff
      "kernel.sysrq" = 212;

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
          # Enable device power reporting
          Experimental = true;
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

  services.udev.extraRules = ''
    # Enable TRIM for external SSD
    ACTION=="add|change", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="9210", SUBSYSTEM=="block", ATTR{../../scsi_disk/*/provisioning_mode}="unmap"

    # NVMe SSD
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
  '';

  systemd = {
    extraConfig = ''
      DefaultTimeoutStopSec=20s
    '';

    # Disable service
    services.ollama.wantedBy = lib.mkForce [ ];

    services.nixos-upgrade.environment = lib.mkForce {
      http_proxy = "";
      https_proxy = "";
    };

    user.services = {
      conky = {
        description = "Conky daemon";
        #wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.conky}/bin/conky -c /home/skrimix/.config/conky/lean-conky-config/conky.conf";
        };
        path = [ pkgs.fontconfig pkgs.iproute2 pkgs.util-linux pkgs.wget pkgs.amdgpu_top pkgs.coreutils-full pkgs.python3 ];
      };
      fsearch_update_database = {
        description = "FSearch - Update database";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.fsearch}/bin/fsearch --update-database";
        };
      };
    };

    user.timers = {
      fsearch_update_database = {
        description = "FSearch - Periodically update database";
        wantedBy = [ "basic.target" ];
        timerConfig = {
          OnBootSec = "20min";
          OnUnitActiveSec = "1h";
          Unit = "fsearch_update_database.service";
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
  };


  services = {
    # Replace kernel console with kmscon
    kmscon = {
      enable = true;
      hwRender = true;
    };

    # SDDM + Plasms 6
    xserver = {
      enable = true;
      displayManager = {
        sddm = {
          enable = true;
          autoNumlock = true;
          settings = {
            Autologin = {
              Session = "plasma.desktop";
              User = "skrimix";
            };
          };
          wayland.enable = true;
        };
        defaultSession = "plasma";
      };
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
  };

  environment.sessionVariables = {
    # Enable wayland for programs that support it
    NIXOS_OZONE_WL = "1";
    # Use askpass even in terminal
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  xdg.portal = {
    enable = true;

    # Fix opening links in vscode-fhs
    config.common.default = "*";
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    xdgOpenUsePortal = true;
  };

  # Fix Plasma integration in Brave Browser
  environment.etc."chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  users = {
    users.skrimix = {
      isNormalUser = true;
      extraGroups = [ "wheel" "adbusers" "networkmanager" "scanner" "libvirtd" ];
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
    libsForQt5.kio # Needed for file picker in some apps (e.g. Monero GUI)
    wl-clipboard # For WayDroid clipboard sharing
    pulseaudio # pactl for output switching
    vesktop # Discord
    ((nnn.override { withNerdIcons = true; }).overrideAttrs (finalAttrs: previousAttrs: {
      # "Buffer overflow detected" crash
      hardeningDisable = [ "fortify3" ];
    }))
    fsearch

    # Media
    spotify
    mpv
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-vkcapture
      ];
    })
    vlc
    gimp
    upscayl
    duplicacy

    # Browsers
    brave
    chromium
    tor-browser
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
    imhex
    #jadx # fails to build
    ghidra
    # Drag and drop does not work in Wayland
    # https://github.com/microsoft/vscode/issues/156723
    (vscode.override { commandLineArgs = "-enable-features=UseOzonePlatform --ozone-platform=x11"; }).fhs

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
    heroic

    # Hardware monitoring
    (conky.override { waylandSupport = true; })
    lm_sensors

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
    #discover
    ksystemlog
    kalk
    kcalc
    skanpage
    skanlite
    kleopatra
    #kompare
    ktorrent
    filelight
    krdc
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
      leanconkyconfig-font
    ];
  };

  virtualisation = {
    waydroid.enable = true;
    vmware.host.enable = true;
    libvirtd = {
      enable = true;
      onBoot = "ignore";
    };
  };

  services = {
    printing.enable = true;
    dbus.enable = true;
    flatpak.enable = true;
    #packagekit.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
    sunshine.enable = true;
    ollama = {
      enable = true;
      acceleration = "rocm";
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
    };
    noisetorch.enable = true;
    coolercontrol.enable = true;
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


  #system.copySystemConfiguration = true;

  # DO NOT CHANGE
  system.stateVersion = "23.11";
}

