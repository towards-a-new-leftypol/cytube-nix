with import <nixpkgs> {};

stdenv.mkDerivation {
    name = "cytube_shell";
    buildInputs = [
        nodejs
        nodePackages.node2nix
    ];
    shellHook = ''
        export PATH="$PWD/node_modules/.bin/:$PATH"
    '';
}
