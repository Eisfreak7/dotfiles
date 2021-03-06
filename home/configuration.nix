{ config
, pkgs # nixpkgs is pinned through nixPath in the system config
, lib
, ...
}:
let
  cfg = config.home;
in
  # TODO cleanup services
  # fd --no-ignore --changed-before 7d . ~/.cache --exec rm -f {}
  # fd --no-ignore --changed-before 1d --type f --type e . ~/.config --exec trash-put {}
  # TODO something similar .local?
with pkgs.lib; {
  imports = [
    ./neovim.nix # editor
    ./taskwarrior.nix # todo list and task management
    ./newsboat.nix # rss reader
    ./git.nix
    ./ranger.nix # file manager
    ./mutt.nix # mail
    ./scripts.nix
    ./herbstluftwm.nix # window manager
    ./kitty.nix # terminal emulator
    ./redshift.nix # shift screen light to red (away from blue) in the evening to tell the brain its night time
  ];

  options.home = {
    graphical = mkOption {
      type = types.bool;
      default = true;
      description = "Weather to install a graphical environment or not";
    };
    full = mkOption {
      type = types.bool;
      default = true;
      description = "Weather to install all packages, regardless of space";
    };
  };

  config = {
    herbstluftwm.enable = cfg.graphical;
    kitty.enable = cfg.graphical;
    redshift.enable = cfg.graphical;

    # only tools I use directly
    # tools used in scripts should be listed somewhere else
    home.packages = let
      nix-bisect = pkgs.python3.pkgs.buildPythonPackage rec {
        pname = "nix-bisect";
        version = "0.4.1";
        # src = lib.cleanSource /home/timo/repos/nix-bisect;
        src = pkgs.fetchFromGitHub {
          owner = "timokau";
          repo = "nix-bisect";
          rev = "v${version}";
          sha256 = "1z5j7qjzsxq7i9kklvwn8dv327zrs21k1nwwif54lslck7gy6nyk";
        };
        propagatedBuildInputs = with pkgs.python3.pkgs; [
          appdirs
          pexpect
          numpy
        ];
      };
    in with pkgs; [
      pdfpc # latex beamer presentations
      entr # run command on file changes (nicer interface than inotify)
      skim # fzf clone in rust
      # Disabled since its broken on master (2020-07-27) and not currently used.
      # vagrant # VM management
      moreutils # usefull stuff like `vidir` bulk renaming
      ltrace # trace library calls
      gdb
      # superTuxKart # disabled since its broken on master (2020-10-20)
      teeworlds
      brightnessctl # controlling brightness on my laptop
      tmux
      loc # SLOC language summary
      htop # system monitoring
      pdfgrep # search through pdfs
      imagemagick # cli image editing
      graphviz # for pycallgraph, TODO add as upstream dependency
      dot2tex # graphviz <-> latex
      gnuplot # plot generation in latex
      # for quick python experiments
      (python3.withPackages (pkgs: with pkgs; [
        nix-bisect # bisect nix packages
        # rl algorithms
        black # python formatting
        pycallgraph # profiling
        notmuch # notmuch python api to sort mails
        ipython # better interactive python
        numpy # number squashing
        matplotlib
        tkinter # matplotlib backend
        pillow # FIXME necessary for ranger image preview with kitty
      ] ++ optionals cfg.full [
      ]))
      ncdu # where is my space gone?
      translate-shell # translate
      unar
      nix-index
      tldr # quick usage examples
      mpv # audio and video player
      youtube-dl # media downloader (not just youtube)
      ffmpeg # cli media editor
      ncmpcpp # tui mpd music player
      wget
      zathura # minimal pdf viewer with vim contorls
      trash-cli # gentle rm replacement
      firejail # sandboxing
      httpie # cli http client
      exa # "modern" ls replacement
      fd # "modern" find replacement
      psmisc # `killall` command
      khard # calendar
      speedtest-cli # connection speed test
      fasd # cli navigation
      mpd
      mpc_cli # mpd cli client
      jq # cli json handling
      pass # password manager
      nix-review # reviewing nix PRs
      sshfs # mount dirs from other machines
      # TODO
      # highlight
      # sshfs-fuse
      # xsel
      # ssh-ident
      # moreutils
      home-manager
      sbt # scala build manager, needed for university lecture
      radare2 # reverse engineering
      source-code-pro # needed for gui neovim (FIXME)
      direnv # directory specific environments (used by lorri)
      bat # "cat" clone in rust with some nice additional features
    ] ++ (optionals cfg.full [
      # to find "offenders":
      # nix-store -q --requisites $( home-manager build ) | while read line; do du -hs "$line"; done | uniq | sort -h
      pandoc # convert between markup formats (pandoc -> ghc -> ~1.4G space)
      texlive.combined.scheme-full # latex
      # https://github.com/NixOS/nixpkgs/issues/92518
      # sageWithDoc # math software
    ]) ++ (optionals cfg.graphical [
      libreoffice
      anki # flash cards
      xclip # x11 clipboard management
      okular # feature-full pdf viewer
      gimp # image editing
      tdesktop # telegram chat
      spotify # music
      digikam # picture management
      scrot # screenshots
      evince # more fully featured (and bloated) pdf viewer
      pavucontrol # volume
      sxiv # image viewer
      calibre # ebook management
      xcape # keyboard management
      xdotool # x automation
      chromium # fallback browser
      autorandr
      libnotify # notify-send
      xorg.xbacklight
      radare2-cutter # radare gui
      wireshark # network sniffing
      # TODO add simple wrapper that sets XDG_DESKTOP_DIR="$HOME/
      # https://bugzilla.mozilla.org/show_bug.cgi?id=1082717
      firefox
    ]);

    fonts.fontconfig.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      # work around https://github.com/rycee/home-manager/issues/908
      extraConfig = ''
        pinentry-program ${pkgs.pinentry.gtk2}/bin/pinentry
      '';
      # defaultCacheTtl = 86400;
      # allow-loopback-pinentry
      # defaultCacheTtlSsh = TODO;
    };

    # services.mbsync.enable = TODO

    # services.polybar = TODO

    # services.screen-locker = TODO

    # project-specific nix-envs with direnv and good caching support
    services.lorri.enable = true;
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };

    nixpkgs.config = {
      allowUnfreePredicate = (pkg: elem (pkg.pname or (builtins.parseDrvName pkg.name).name) [
        # unfree whitelist
        "spotify"
        "spotify-unwrapped"
        "steam-runtime" # not actually used, but needed by steam-run
      ]);
      firefox = {
        enableTridactylNative = true;
      };
    };

    programs.zsh = {
      enable = true;
      initExtra = (builtins.readFile ../zsh/.zshrc) +
      # temporary workaround for https://github.com/NixOS/nixpkgs/issues/45662#issuecomment-453253372
      ''
        export GI_TYPELIB_PATH=${lib.makeSearchPath "lib/girepository-1.0" (with pkgs; [
          gtk3
          pango.out
          gdk_pixbuf
          librsvg
          atk
        ])}
        export GDK_PIXBUF_MODULE_FILE="$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)"
        export XDG_DESKTOP_DIR="$HOME/Downloads" # because firefox creates this on start
      '';
      shellAliases = {
        # use ssh-ident to start ssh-agent as necessary
        ssh = "BINARY_SSH=${pkgs.openssh}/bin/ssh ${pkgs.ssh-ident}/bin/ssh-ident";
        scp = "BINARY_SSH=${pkgs.openssh}/bin/scp ${pkgs.ssh-ident}/bin/ssh-ident";
        rsync = "BINARY_SSH=${pkgs.rsync}/bin/rsync ${pkgs.ssh-ident}/bin/ssh-ident";
        cat = "${pkgs.bat}/bin/bat";
        # privacy / security / when my addons break something
      } // (
        if (cfg.full) then {
          fx = "${pkgs.firefox}/bin/firefox --new-instance --profile \"$(mktemp -d)\"";
          cx = "${pkgs.chromium}/bin/chromium --user-data-dir=\"$(mktemp -d)\"";
        } else {}
      );
    };

    programs.fish = {
      enable = true;
      shellAliases = {
        cat = "${pkgs.bat}/bin/bat";
      };
      shellInit = ''
        export EDITOR=nvim
      '';
      plugins = [
        {
          name = "z";
          src = pkgs.fetchFromGitHub {
            owner = "jethrokuan";
            repo = "z";
            rev = "ddeb28a7b6a1f0ec6dae40c636e5ca4908ad160a";
            sha256 = "0c5i7sdrsp0q3vbziqzdyqn4fmp235ax4mn4zslrswvn8g3fvdyh";
          };
        }
      ];
      promptInit = ''
        set -l nix_shell_info (
          if test -n "$IN_NIX_SHELL"
            echo -n "<nix-shell> "
          end
        )
        echo -n -s "$nix_shell_info ~>"
      '';
    };

    programs.tmux = {
      enable = true;
      keyMode = "vi";
      newSession = true;
      extraConfig = ''
        set -g mouse on
      '';
    };

    xdg.enable = true;
    # make the sage colorscheme readable
    home.file.".sage/init.sage".text = ''
      %colors Linux
    '';

    xdg.configFile."sxhkd/sxhkdrc".source = ../sxhkd/.config/sxhkd/sxhkdrc;

    # TODO bag script

    services.dunst = {
      # TODO
      enable = cfg.graphical;
    };
    xdg.configFile."mpv" = {
      source = ../mpv/.config/mpv;
      recursive = true;
    };

    # services.gpg-agent = TODO
    xdg.configFile."dunst/dunstrc".source = ../dunst/.config/dunst/dunstrc;
    xdg.dataFile."applications/element.desktop".text = optionalString cfg.graphical ''
      [Desktop Entry]
      Encoding=UTF-8
      Version=1.0
      Type=Application
      Terminal=false
      Exec=${pkgs.chromium}/bin/chromium --class 'Element' --app=https://app.element.io
      Name=Element messenger
    '';
    xdg.dataFile."applications/slack.desktop".text = optionalString cfg.graphical ''
      [Desktop Entry]
      Encoding=UTF-8
      Version=1.0
      Type=Application
      Terminal=false
      Exec=${pkgs.chromium}/bin/chromium --class 'Slack' --app=https://app.slack.com/client/
      Name=Slack messenger
    '';
    xdg.dataFile."applications/zulip-upb.desktop".text = optionalString cfg.graphical ''
      [Desktop Entry]
      Encoding=UTF-8
      Version=1.0
      Type=Application
      Terminal=false
      Exec=${pkgs.chromium}/bin/chromium --class 'Zulip UPB' --app=https://chat.cs.upb.de/
      Name=Zulip messenger hosted by UPB
    '';

    home.file.".latexmkrc".text = ''
      # no interaction, enable synctex for vimtex integratoin
      $pdflatex = "pdflatex -synctex=1 -interaction=nonstopmode -halt-on-error %O %S";

      $pdf_previewer = 'start zathura';
      $pdf_mode = 1; # build pdf by default
      $failure_cmd = 'echo $"\a"; latexmk -C' # ring bell
    '';

    services.syncthing = {
      # TODO add config
      enable = true;
    };

    xdg.configFile."tridactyl/tridactylrc".source = ../tridactyl/.config/tridactyl/tridactylrc;

    # hide mouse cursor when not moving
    services.unclutter = {
      enable = cfg.graphical;
    };

    systemd.user.services.xautolock = {
      Unit = {
        Description = "Lock screen on inactivity";
        After = [ "graphical-session-pre.target" ];
      };

      Service = {
        # FIXME script path
        ExecStart = ''
          ${pkgs.xautolock}/bin/xautolock \
            -detectsleep \
            -time 180 \
            -locker /home/timo/bin/lock \
            -notify 60 \
            -notifier '${pkgs.libnotify}/bin/notify-send --urgency=low "The screen will lock in 60s"' \
            -noclose
        '';
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.keyboardconfig = {
      Unit = {
        Description = "Adjust keyboard layout";
        After = [ "graphical-session-pre.target" ];
      };

      Service = {
        ExecStart = ''
          ${config.home.file."bin/keyboardconfig".source}
        '';
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # TODO udiskie, unclutter, xscreensaver

    programs.command-not-found.enable = true;

    # TODO try skim instead
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      changeDirWidgetCommand = "bash -c 'fasd -ld; fd --hidden --follow --no-ignore-vcs --type d'"; # Alt-C
      changeDirWidgetOptions = [ "--ansi" "--preview 'tree -C {} | head -200'" ];
      defaultCommand = "fd --type f";
      fileWidgetCommand = "bash -c 'fasd -l; fd --color=always --hidden --follow --no-ignore-vcs'";
      # try skim instead
      fileWidgetOptions = [ "--ansi" ];
      # defaultOptions = [ "--height 40%" "--border" ]
    };

    # programs.home-manager.enable = true;

    programs.htop = {
      enable = true;
      highlightBaseName = true;
      showProgramPath = false;
      treeView = true;
      sortKey = "PERCENT_MEM"; # usually the bottleneck
    };

    programs.rofi.enable = cfg.graphical;

    # programs.ssh.enable = true; TODO

    # programs.termite.enable = true; #TODO

    xsession.initExtra = optionalString cfg.graphical ''
      # no monitor timeout (handled by xautolock)
      ${pkgs.xorg.xset}/bin/xset s off -dpms
    '';
  };
}
