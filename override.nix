{pkgs ? import <nixpkgs> {
    inherit system;
}, system ? builtins.currentSystem}:

let
  nodePackages = import ./node2nix_generated/default.nix {
    inherit pkgs system;
  };
in
nodePackages // {
  package = nodePackages.package.override {
    buildInputs = [
      pkgs.nodePackages.node-pre-gyp
      pkgs.libtool
      pkgs.autoconf
      pkgs.automake
    ] ++ nodePackages.args.buildInputs;
  };
}
