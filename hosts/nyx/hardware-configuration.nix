{ config, lib, pkgs, modulesPath, ... }:

let
  btrfsOpts = [
    "noatime"
    "compress-force=zstd:3"
  ];
  ntfsOpts = [
    "rw"
    "nosuid"
    "relatime"
    "uid=1000"
    "gid=100"
    "dmask=022"
    "fmask=133"
    "iocharset=utf8"
    "windows_names"
    "nofail"
  ];
in
{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [
      "kvm-amd"
      # Alternative Ryzen CPU metrics
      "zenpower"
      # Motherboard sensors
      "nct6775"
    ];
    # zenpower replaces k10temp
    blacklistedKernelModules = [ "k10temp" ];
    extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    kernelParams = [
      "video=DP-2:2560x1440@75" # set mode early on the main display
      "video=HDMI-A-1:1920x1080@75" # overclock secondary display
      "zswap.enabled=0" # zram is used instead of zswap
      "amdgpu.ppfeaturemask=0xffffffff" # unlock AMDGPU controls
      #"amdgpu.ppfeaturemask=0xffffbfff" # no overdrive
      "amdgpu.gpu_recovery=1" # enable AMDGPU recovery
      "psi=1"
      "amd_pstate=active" # let the cpu manage its frequency
      "transparent_hugepage=never" # avoid excessive CPU load when using VMware
    ];
  };

  zramSwap.enable = true;

  environment.sessionVariables = { VDPAU_DRIVER = "radeonsi"; };

  # RADV driver seems to be better than AMDVLK
  # hardware.opengl = {
  #   extraPackages = with pkgs; [
  #     amdvlk
  #   ];
  #   extraPackages32 = with pkgs; [
  #     driversi686Linux.amdvlk
  #   ];
  # };

  # Default "modesetting" driver is better
  #services.xserver.videoDrivers = [ "amdgpu" ];

  # Disable secondary display in SDDM
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-1 --off --output DP-2 --refresh 75
  '';

  networking.interfaces.enp34s0.wakeOnLan.enable = true;

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/44DF-CCB6";
      fsType = "vfat";
    };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/12f5d45b-8882-42f4-92ca-9bcb1871feaf";
      fsType = "btrfs";
      options = [
        "subvol=root"
      ] ++ btrfsOpts;
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/12f5d45b-8882-42f4-92ca-9bcb1871feaf";
      fsType = "btrfs";
      options = [
        "subvol=home"
      ] ++ btrfsOpts;
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/12f5d45b-8882-42f4-92ca-9bcb1871feaf";
      fsType = "btrfs";
      options = [
        "subvol=nix"
      ] ++ btrfsOpts;
    };

  fileSystems."/mnt/arch" =
    {
      device = "/dev/disk/by-uuid/6d2e5dd1-bd7f-411d-a2e5-135f4149750a";
      fsType = "btrfs";
      options = btrfsOpts;
    };

  fileSystems."/mnt/870evo_btrfs" =
    {
      device = "/dev/disk/by-uuid/18541afc-50b3-40de-9888-a2b8acdbe888";
      fsType = "btrfs";
      options = btrfsOpts;
    };

  fileSystems."/mnt/kingston_btrfs" =
    {
      device = "/dev/disk/by-uuid/81b2e3bc-b353-40e9-ada7-f0e32ce21b02";
      fsType = "btrfs";
      options = btrfsOpts;
    };

  fileSystems."/mnt/windows" =
    {
      device = "/dev/disk/by-uuid/01D9BFE2C6CB8100";
      fsType = "ntfs3";
      options = ntfsOpts;
    };

  fileSystems."/mnt/hdd" =
    {
      device = "/dev/disk/by-uuid/DA48F97B48F9572B";
      fsType = "ntfs3";
      options = ntfsOpts;
    };

  fileSystems."/mnt/kingston_ntfs" =
    {
      device = "/dev/disk/by-uuid/44D04AD2D04ACA3E";
      fsType = "ntfs3";
      options = ntfsOpts;
    };

  fileSystems."/mnt/netac" =
    {
      device = "/dev/disk/by-uuid/01D93E48F1271CA0";
      fsType = "ntfs3";
      options = ntfsOpts;
    };

  fileSystems."/mnt/870evo_ntfs" =
    {
      device = "/dev/disk/by-uuid/368E3EE68E3E9E75";
      fsType = "ntfs3";
      options = ntfsOpts;
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp34s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
