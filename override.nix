{pkgs ? import <nixpkgs> {
    inherit system;
}, system ? builtins.currentSystem, nodejs ? pkgs."nodejs_20"}:

let
  nodePackages = import ./node2nix_generated/default.nix {
    inherit pkgs system;
    nodejs = nodejs;
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
