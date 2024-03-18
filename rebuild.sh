#!/usr/bin/env bash
set -e
pushd "$(dirname "$0")" > /dev/null

# check for changes and --no-git flag
if [ -z "$(git status --porcelain)" ] || [ "$1" == "--no-git" ]; then
    echo "No changes to commit or no-git flag used."
    echo "Rebuilding NixOS..."
    sudo nixos-rebuild switch --flake path:/home/skrimix/.nix
    exit 0
fi


git diff --color -U0
echo "Rebuilding NixOS..."
sudo nixos-rebuild switch --flake path:/home/skrimix/.nix
gen=$(nixos-rebuild list-generations --flake path:/home/skrimix/.nix | grep current | awk '{print $1}')
git add -A
git commit -am "generation $gen"
git push
