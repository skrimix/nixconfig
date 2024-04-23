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
    initrd.availableKernelModules = [ "xhci_pci" "nvme" "uas" "sd_mod" ];
    initrd.kernelModules = [ "i915" ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = with config.boot.kernelPackages; [ ];
    kernelParams = [
      "i915.enable_fbc=1"
      "i915.fastboot=1"
    ];
  };

  environment.variables = {
    VDPAU_DRIVER = "va_gl";
  };

  hardware = {
    opengl = {
      extraPackages = with pkgs; [
        intel-vaapi-driver
        libvdpau-va-gl
        intel-media-driver
      ];
    };
    system76.power-daemon.enable = true;
  };

  services = {
    thermald.enable = true;
    power-profiles-daemon.enable = false;
    undervolt = {
      enable = true;
      coreOffset = -90;
      gpuOffset = -100;
      p2.limit = 30;
      p2.window = 25;
      p1.limit = 20;
      p1.window = 120;
    };
  };
  zramSwap.enable = true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/2ca4dd1e-e134-4e1d-af1d-857721b97263";
      fsType = "btrfs";
      options = [
        "subvol=root"
      ] ++ btrfsOpts;
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/2ca4dd1e-e134-4e1d-af1d-857721b97263";
      fsType = "btrfs";
      options = [
        "subvol=home"
      ] ++ btrfsOpts;
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/2ca4dd1e-e134-4e1d-af1d-857721b97263";
      fsType = "btrfs";
      options = [
        "subvol=nix"
      ] ++ btrfsOpts;
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/1B29-505D";
      fsType = "vfat";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
