{ self, system, ... }: {
  services.greetd.enable = true;

  programs.regreet.enable = true;

  security.pam.services.greetd.kwallet.enable = true;
}