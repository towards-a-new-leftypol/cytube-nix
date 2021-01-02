{pkgs ? import <nixpkgs> {
    inherit system;
}, system ? builtins.currentSystem}:

let
  nodePackages = import ./node2nix_generated/default.nix {
    inherit pkgs system;
  };

  # everything to do with this bloody patch file is an ugly hack
  # because node2nix only gives us the preRebuild to override and we
  # have to implement patching in this phase ourselves.
  patchFile = builtins.readFile ./configfile_env.patch;
in
nodePackages // {
  package = nodePackages.package.override {
    buildInputs = [
      pkgs.nodePackages.node-pre-gyp
      pkgs.libtool
      pkgs.autoconf
      pkgs.automake
    ] ++ nodePackages.args.buildInputs;

    preRebuild = ''
      echo '${patchFile}' | patch -p0
    '';
  };
}
