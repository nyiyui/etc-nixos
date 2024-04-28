{ pkgs ? import <nixpkgs> { } }:
let config = {
  imports = [ <nixpkgs/nixos/modules/virtualisation/oci-image.nix> ];
};
in
(pkgs.nixos config).OCIImage

