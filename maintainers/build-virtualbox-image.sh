#! /bin/sh -e
export NIXOS_CONFIG=$(readlink -f $(dirname $0)/..)/nix/virtualbox-image-nixops.nix
version=$(nix-instantiate --eval-only '<nixos>' -A config.system.nixosVersion | sed s/'"'//g)
echo "version = $version"
nix-build '<nixos>' -A config.system.build.virtualBoxImage
name=virtualbox-nixops-$version.vdi.xz
xz < ./result/disk.vdi > $name
scp -p $name root@nixos.org:/data/releases/nixos/virtualbox-nixops-images/
sha256sum $name
