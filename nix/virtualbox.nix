{ config, pkgs, ... }:

with pkgs.lib;

let

  # Do the fetching and unpacking of the VirtualBox guest image
  # locally so that it works on non-Linux hosts.
  pkgsNative = import <nixpkgs> { system = builtins.currentSystem; };

in

{

  ###### interface

  options = {

    deployment.virtualbox.memorySize = mkOption {
      default = 512;
      type = types.int;
      description = ''
        Memory size (M) of virtual machine.
      '';
    };

    deployment.virtualbox.headless = mkOption {
      default = false;
      description = ''
        If set, the VirtualBox instance is started in headless mode,
        i.e., without a visible display on the host's desktop.
      '';
    };

    deployment.virtualbox.disks = mkOption {
      default = {};
      example =
        { big-disk = {
            port = 1;
            size = 1048576;
          };
        };
      type = types.attrsOf types.optionSet;
      description = "Definition of the virtual disks attached to this instance.";

      options = {

        port = mkOption {
          example = 1;
          type = types.uniq types.int;
          description = "SATA port number to which the disk is attached.";
        };

        size = mkOption {
          type = types.uniq types.int;
          description = "Size (in megabytes) of this disk.";
        };

        baseImage = mkOption {
          default = null;
          example = "/home/alice/base-disk.vdi";
          type = types.nullOr types.path;
          description = ''
            If set, this disk is created as a clone of the specified
            disk image (and the <literal>size</literal> attribute is
            ignored).
          '';
        };

      };
    };

  };


  ###### implementation

  config = mkIf (config.deployment.targetEnv == "virtualbox") {

    nixpkgs.system = mkOverride 900 "x86_64-linux";

    deployment.virtualbox.disks.disk1 =
      { port = 0;
        size = 0;
        baseImage = mkDefault (
          let
            unpack = name: sha256: pkgsNative.runCommand "virtualbox-nixops-${name}.vdi" {}
              ''
                xz -d < ${pkgsNative.fetchurl {
                  url = "http://nixos.org/releases/nixos/virtualbox-nixops-images/virtualbox-nixops-${name}.vdi.xz";
                  inherit sha256;
                }} > $out
              '';
          in if config.nixpkgs.system == "x86_64-linux" then
            unpack "13.09pre-0408858-f2e4efc" "f8b530958d428011008dfcc29c6e98fd907ee310f6f033a5d3cb202b8ae93bd4"
          else
            throw "Unsupported VirtualBox system type!"
        );
      };
  };

}
