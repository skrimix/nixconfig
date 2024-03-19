#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

_echo() {
    echo -e "\e[1;1m$1\e[0m"
}

_echo_success() {
    echo -e "\e[1;32m$1\e[0m"
}

_echo_fail() {
    echo -e "\e[1;31m$1\e[0m"
}

# check for changes and --no-git flag
if [ -z "$(git status --porcelain)" ] || [ "$1" == "--no-git" ]; then
    _echo "No changes to commit or no-git flag used"
    _echo "Rebuilding NixOS..."
    (sudo nixos-rebuild switch --flake path:/home/skrimix/.nix && _echo_success "Rebuild successful") || (_echo_fail "Rebuild failed" && exit 1)
    exit 0
fi


git diff --color -U0
_echo "Rebuilding NixOS..."
(sudo nixos-rebuild switch --flake path:/home/skrimix/.nix && _echo_success "Rebuild successful, committing to git") || (_echo_fail "Rebuild failed" && exit 1)
gen=$(nixos-rebuild list-generations --flake path:/home/skrimix/.nix | grep current | awk '{print $1}')
git add -A
git commit -am "generation $gen"
git push --quiet && _echo "Pushed to git"
