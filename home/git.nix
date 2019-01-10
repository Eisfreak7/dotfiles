{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    aliases = {
      co = "checkout";
      find-merge = ''
        "!sh -c 'commit=$0 && branch=''${1:-HEAD} && (git rev-list $commit..$branch --ancestry-path | cat -n; git rev-list $commit..$branch --first-parent | cat -n) | sort -k2 -s | uniq -f1 -d | sort -n | tail -1 | cut -f2'"
      '';
      track = ''
        "!git push --set-upstream timokau \"$(git symbolic-ref --short HEAD)\""
      '';
    };
    extraConfig = {
      # use ssh-ident to start ssh-agent as necessary
      core.sshCommand = "BINARY_SSH=${pkgs.openssh}/bin/ssh ${pkgs.ssh-ident}/bin/ssh-ident";
      commit.verbose = true; # show diff when committing
    };
    # signing = TODO
    userEmail = "timokau@zoho.com";
    userName = "Timo Kaufmann";
  };
}
