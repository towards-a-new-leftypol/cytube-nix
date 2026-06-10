with import <nixpkgs> {};

stdenv.mkDerivation {
    name = "cytube_shell";
    buildInputs = [
        nodejs_22
    ];
    shellHook = ''
        export PATH="$PWD/node_modules/.bin/:$PATH"
    '';
}
