{ config
, pkgs # nixpkgs is pinned
, ...
}:

let
  # This is done implicitly on the second run by setting nixPath. Doing it
  # directly leads to quirky behaviour because the NixOS module would still
  # come from the old nixpkgs.
  # pkgs = import (import ./nixpkgs.nix) {};
  homeipv6 = builtins.readFile ./homeipv6; # not version controlled

  wireguard = {
    port = 51822;
    publicKey = {
      rpi = "gxkt8JC7F2ExSQkA41sY7e94qag693Cf9y3UiFOGQRE=";
      pad = "YoUI02AyBRNM7//UTzUlO90mCx7wHX+Jzxf2uaFR3gg=";
      desk = "d5KwIeKll+z5ZyAVRotC69RXuwM4VLwNtZoRoQEbTjo=";
    };
    ip = {
      rpi = "10.10.10.1";
      pad = "10.10.10.2";
      desk = "10.10.10.3";
      phone = "10.10.10.4";
    };
  };

  inherit (pkgs) lib;
in
{
  imports = [
    ./hardware-configuration.nix
    # Different file for each host. Symlink one of the files in `hosts`, e.g.
    # `ln -s hosts/desk.nix host.nix`. The symlink is not version controlled.
    # Needs to set `networking.hostName` and `system.stateVersion`.
    ./host.nix
  ];

  services.autorandr.enable = true;

  services.grocy = {
    enable = true;
    hostName = "localhost";
    nginx.enableSSL = false;
    settings = {
      currency = "EUR";
    };
  };

  nix = {
    useSandbox = true;
    daemonIONiceLevel = 5;
    daemonNiceLevel = 10;
    nixPath = [
      # Fix the nixpkgs this configuration was built with. To switch to a new
      # revision, explicitly pass it through NIX_PATH once and then it will be
      # set as the new default.
      "nixpkgs=/run/current-system/nixpkgs"
      "nixos-config=/etc/nixos/configuration.nix"
    ];
  };
  # downgrading to read lock on '/nix/var/nix/temproots/18942'
  # copied source '/nix/store/azqqifyxvlgf48lgqh7zmyj0f4az03v9-nixpkgs-e89b21504f3e61e535229afa0b121defb52d2a50' -> '/nix/store/033x58cj9xx3r1i3y39jvywvw338kabg-azqqifyxvlgf48lgqh7zmyj0f4az03v9-nixpkgs-e89b21504f3e61e535229afa0b121defb52d2a50'
  # acquiring write lock on '/nix/var/nix/temproots/18942
  system.extraSystemBuilderCmds = let
    # make sure store paths are not copied to the store again, which leads to
    # long filenames (https://github.com/NixOS/nix/issues/1728)
    nixpkgs_str = if lib.isStorePath pkgs.path then builtins.storePath pkgs.path else pkgs.path;
  in ''
    ln -sv '${nixpkgs_str}' "$out/nixpkgs"
    echo '${pkgs.path}'
  '';

  # install man pages
  environment.extraOutputsToInstall = [ "man" ];

  # only some administrative packages are installed at the system level
  environment.systemPackages = (with pkgs; [
    manpages
    # android-udev-rules
    # noto-fonts
    # dhcpcd
    acpi
    gnupg
    psmisc # killall
    git
    vim
    ranger
    tree
    htop
    rsync
    ripgrep
    home-manager # manage user configurations
  ]);

  # disable system sounds
  xdg.sounds.enable = false;


  # firejail needs to run setuid
  security.wrappers.firejail = {
    program = "firejail";
    source = "${pkgs.firejail.out}/bin/firejail";
    owner = "root";
    group = "root";
    setuid = true;
    setgid = true;
  };

  programs.adb.enable = true;
  # programs.command-not-found.enable = true;

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      source-code-pro
      inconsolata
      terminus_font
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  boot.kernel.sysctl = {
    # https://wiki.archlinux.org/index.php/zswap
    "zswap.enabled" = 1;
    "kernel.sysrq" = 1; # enable "magic sysrq" to force OOM reaper
  };

  boot.cleanTmpDir = true;

  virtualisation.virtualbox.host = {
    enable = true;
    # enableExtensionPack = true; # unfree
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
    ports = [ 2143 ];
  };

  # internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de";

  time.timeZone = "Europe/Berlin";

  networking = {
    # use cloudflare dns which is uncensored (in contrast to that of my isp)
    nameservers = [ "1.1.1.1" ];
    networkmanager.insertNameservers = [ "1.1.1.1" ];

    # use networkmanager for easy wifi setup
    networkmanager.enable = true;

    # block all non-whitelisted connections
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22000 # syncthing sharing
        8200 # proxy
      ];
      allowedUDPPorts = [
        21027 # syncthing discovery
        wireguard.port
        22
        8200 # proxy
      ];
    };
  };

  powerManagement = {
    # support suspend-to-ram, save power
    enable = true;

    # log boots and wakes from suspend
    powerUpCommands = "date -Ih >> /var/log/power_up.log";
  };

  services.snapper = {
    snapshotInterval = "hourly";
    # configs.home = {
    #   subvolume = "/home";
    #   # snapshots are pretty much only used in case I accidentally delete or override something, which usually is caught pretty soon
    #   extraConfig = ''
    #     TIMELINE_CREATE=yes
    #     TIMELINE_CLEANUP=yes
    #     TIMELINE_LIMIT_HOURLY=16
    #     TIMELINE_LIMIT_DAILY=5
    #     TIMELINE_LIMIT_WEEKLY=1
    #     TIMELINE_LIMIT_MONTHLY=1
    #     TIMELINE_LIMIT_YEARLY=0
    #   '';
    # };
  };

  # TODO make it possible to set this dynamically on the laptop
  # services.logind.extraConfig = "HandleLidSwitch=ignore";

  networking.hosts = {
    # give names to devices in my home network
    "192.168.0.22" = [ "desk-local" ];
    "${wireguard.ip.desk}" = [ "desk" ];
    "192.168.0.38" = [ "rpi-local" ];
    "${wireguard.ip.rpi}" = [ "rpi" ];
    "${wireguard.ip.pad}" = [ "pad" ];
    "192.168.0.21" = [ "opo" ];
    "192.168.0.20" = [ "laptop" ];
    "192.168.0.26" = [ "kindle" ];
    "192.168.0.45" = [ "par" ];
    "192.168.0.1" = [ "rooter" ];
    "192.168.0.100" = [ "eb" ];
  };

  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;
    layout = "de";
    xkbOptions = "eurosign:e";
    displayManager = {
      # use sddm (KDE) for login
      sddm.enable = true;
      # job.preStart = "${pkgs.xorg.setxkbmap}/bin/setxkbmap de";
      # sddm.stopScript # executed when stopping the x server
      sessionCommands = "/home/timo/.xprofile"; # TODO setupCommands?
    };
  };

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];

  # scanner support
  hardware.sane.enable = true;

  hardware.cpu.intel.updateMicrocode = true;

  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    # extraConfig = ''
    #   unload-module module-stream-restore
    # '';
  };

  # boot.extraModprobeConfig = ''
  #   options snd_hda_intel index=1,0
  # '';

  # necessary to generate /etc/zsh (so that users can use zsh as a login shell)
  programs.zsh.enable = true;

  # environment.variables = {
  #   EDITOR = "nvim";
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.timo = {};
  users.users.timo = {
    isNormalUser = true;
    group = "timo";
    extraGroups = [
      "wheel"
      "networkmanager"
      "adbusers"
      "scanner"
      "docker"
      "vboxusers"
      "wireshark"
      "video" # brightnessctl
    ];
    uid = 1000;
    shell = "${pkgs.zsh}/bin/zsh";
    # needs to be changed, default is for VMs
    initialPassword = "password";
  };

  systemd.services.channelUpdate  = {
    description = "Updates the unstable channel";
    script = "${pkgs.nix.out}/bin/nix-channel --update";
    startAt = "daily";
    environment.HOME = "/root";
  };


  systemd.services.suspend = {
    description = "Suspend the computer";
    script = ''
      ${pkgs.libudev}/bin/systemctl suspend
    '';
  };

  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "6G";
    MemoryMax = "7G";
  };

  system.autoUpgrade = {
    enable = true;
    dates = "daily";
  };

  # nix.buildMachines = [{
  #   hostName = "desk";
  #   sshKey = TODO;
  #   maxJobs = 4;
  #   systems = [
  #     "x86_64-linux"
  #     "x686-linux"
  #   ];
  #   speedFactor = 2;
  # }];

  # nix.requireSignedBinaryCaches = false;
  # nix.trustedUsers = [ "timo" ];
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "aarch64.nixos.community";
      maxJobs = 64;
      sshKey = "/root/id_aarch64-builder";
      sshUser = "timokau";
      system = "aarch64-linux";
      supportedFeatures = [ "big-parallel" ];
    }
  ];
  nix.trustedUsers = [ "@wheel" ];
  programs.ssh.knownHosts = {
    aarch64-community-builder = {
      hostNames = [ "aarch64.nixos.community" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds";
    };
  };
  programs.ssh.extraConfig = ''
    Host aarch64-nix-community
      Hostname aarch64.nixos.community
      User timokau
      IdentityFile /root/id_aarch64-builder
  '';

  nix.optimise = {
    automatic = true;
    dates = [ "19:00" ];
  };

  nix.extraOptions = ''
    min-free = 2147483648 # automatically collect garbage when <2 GiB free
    max-free = 3221225472 # stop at 3 GiB
    max-silent-time = 1800
    builders-use-substitutes = true
  '';

  nix.buildCores = 0; # use all available CPUs
  nix.maxJobs = 4; # number of jobs (builds) in parallel

  # create a virtual homenet
  networking.wireguard.interfaces.wg0 = {
    ips = [ "${wireguard.ip.${config.networking.hostName}}/24" ];
    listenPort = wireguard.port;
    privateKeyFile = "/home/timo/wireguard-keys/private"; # FIXME location
    peers = [
      {
        publicKey = wireguard.publicKey.rpi;
        allowedIPs = [
          "${wireguard.ip.rpi}/32"
          "${wireguard.ip.pad}/32"
          "${wireguard.ip.desk}/32"
          "${wireguard.ip.phone}/32"
        ];
        # endpoint = "${dyndns}:${toString wireguard.port}";
        endpoint = "${homeipv6}:${toString wireguard.port}";
      }
    ];
  };
}
