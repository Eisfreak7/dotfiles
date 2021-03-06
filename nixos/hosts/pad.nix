{ config
, pkgs
, lib
, ...
}:

{
  networking.hostName = "desk";

  # mount /tmp in RAM. Don't do this on pad, as the machine tends to run out of ram.
  boot.tmpOnTmpfs = true;

  # enable powertop autotuning when using the laptop
  powerManagement.powertop.enable = true;

  services.xserver.dpi = 120;

    hardware.bluetooth = {
      enable = true;
      package = pkgs.bluezFull;
      # config = {};
    };

  services.xserver.libinput = {
    enable = true;
    touchpad = {
      disableWhileTyping = true;
      scrollButton = 2;
      scrollMethod = "twofinger";
    };
  };


  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "18.03";
}
