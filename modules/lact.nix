{ self, pkgs, ... }: {
  environment.systemPackages = [pkgs.lact];
  
  # Enable lactd service
  systemd = {
    packages = [ pkgs.lact ];
    services.lactd.wantedBy = [ "graphical.target" ];
  };
}
