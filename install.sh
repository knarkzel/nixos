#!/usr/bin/env bash

set -Eeuo pipefail

git clone --bare https://github.com/knarkzel/nixos /home/odd/.cfg
git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ checkout -f
git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ config status.showUntrackedFiles no
mkdir -p /home/odd/downloads
mkdir -p /home/odd/source


