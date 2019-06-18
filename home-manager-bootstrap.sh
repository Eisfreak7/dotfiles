#!/usr/bin/env bash

set -e
set -o pipefail

if [ $# -le 0 ]; then
	# TODO more modes
	echo -e "Usage: $0 {headless-vm,}"
	exit 1
fi

mode="$1"
case mode in
	"headless-vm")
		mkdir -p ~/.config/nixpkgs/home-configuration
		touch ~/.config/nixpkgs/home-configuration/{save-space,headless}
		touch ~/.config/nixpkgs/mutt/.mutt/personal # not needed
		mkdir -p ~/state
		touch ~/state/rss-urls # not needed
		;;
esac

# latest version of everything
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update
export NIX_PATH="nixpkgs=$HOME/.nix-defexpr/channels/nixos":$NIX_PATH # https://github.com/NixOS/nix/issues/2033

# home-manager needs this configuration at a particular place
NIXPKGS_CONFIG="${XDG_CONFIG_DIR:-$HOME/.config}/nixpkgs"
DOTFILES="$PWD"
mkdir -p "$NIXPKGS_CONFIG"
ln -T -s "$DOTFILES" "$NIXPKGS_CONFIG"

nix run nixpkgs.home-manager -c home-manager switch
