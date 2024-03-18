#!/usr/bin/env bash
set -e
pushd "$(dirname "$0")" > /dev/null

# check for changes
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit"
    echo "Rebuilding NixOS..."
    sudo nixos-rebuild switch --flake /home/skrimix/.nix
    exit 0
fi

git diff --color -U0
echo "Rebuilding NixOS..."
sudo nixos-rebuild switch --flake /home/skrimix/.nix
gen=$(nixos-rebuild list-generations --flake /home/skrimix/.nix | grep current | awk '{print $1}')
git add -A
git commit -am "generation $gen"
#git push