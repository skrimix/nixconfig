#!/usr/bin/env bash
set -e
pushd "$(dirname "$0")" > /dev/null

_echo() {
    echo -e "\e[1;32m$1\e[0m"
}

# check for changes and --no-git flag
if [ -z "$(git status --porcelain)" ] || [ "$1" == "--no-git" ]; then
    _echo "No changes to commit or no-git flag used."
    _echo "Rebuilding NixOS..."
    sudo nixos-rebuild switch --flake path:/home/skrimix/.nix
    exit 0
fi


git diff --color -U0
_echo "Rebuilding NixOS..."
sudo nixos-rebuild switch --flake path:/home/skrimix/.nix
gen=$(nixos-rebuild list-generations --flake path:/home/skrimix/.nix | grep current | awk '{print $1}')
git add -A
git commit -am "generation $gen"
git push > /dev/null && _echo "Pushed to git"
