{ pkgs ? import <nixpkgs> {}
, lib ? pkgs.lib
}:

let
  nodejs = pkgs.nodejs_20;
in
pkgs.buildNpmPackage rec {
  pname = "cytube";
  version = "3.86.0";

  # Keep this to avoid the EACCES cache error during npm install
  makeCacheWritable = true;

  src = pkgs.fetchFromGitHub {
    owner = "towards-a-new-leftypol";
    repo = "sync";
    rev = "74dbdf0e50ce48bcff7869e813a943d9d5103e4c";
    hash = "sha256-rw0pOHuPcDLelL9fRu3Mxt52rtFEWATX2Y0czEqWS/M=";
  };

  npmDepsHash = "sha256-pDHzcuYYiPID7qMUwsuoPH2FST3+OAePnx/uUDYrlBc=";

  inherit nodejs;

  env = {
    npm_config_build_from_source = "true";
  };

  nativeBuildInputs = [
    pkgs.node-pre-gyp
    pkgs.libtool
    pkgs.autoconf
    pkgs.automake
    pkgs.python3 
    pkgs.pkg-config
    pkgs.makeWrapper
  ];

  buildInputs = [
    pkgs.ffmpeg
    pkgs.yt-dlp
  ];

  # Patch ALL scripts in the repository to use Nix's node instead of /usr/bin/env
  postPatch = ''
    patchShebangs .
  '';

  buildPhase = ''
    runHook preBuild
    
    # 1. Install dependencies and compile native modules locally in the build directory.
    # We use --offline to strictly use the Nix store cache and --legacy-peer-deps for compatibility.
    npm install --offline --legacy-peer-deps
    
    # 2. Ensure the server and player are built.
    # (postinstall.sh should have done this, but we run it again to be absolutely sure).
    npm run build-server
    npm run build-player
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin $out/share/cytube
    
    # Copy the ENTIRE build directory (source, node_modules, lib, www).
    # This prevents npm's "pack" behavior from dropping gitignored/generated files 
    # like www/js/player.js.
    cp -r ./. $out/share/cytube/
    
    # Change to the installed directory and prune devDependencies to save Nix store space.
    cd $out/share/cytube
    npm prune --omit=dev --offline --legacy-peer-deps --ignore-scripts
    
    # Wrap the executable.
    # We add ffmpeg and yt-dlp to the PATH so CyTube can spawn them at runtime!
    makeWrapper ${nodejs}/bin/node $out/bin/cytube \
      --add-flags "$out/share/cytube/index.js" \
      --chdir "$out/share/cytube" \
      --set NODE_ENV production \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ffmpeg pkgs.yt-dlp pkgs.nodejs ]}
      
    runHook postInstall
  '';

  meta = with lib; {
    description = "Online media synchronizer and chat";
    license = licenses.mit;
    mainProgram = "cytube";
    platforms = platforms.linux;
  };
}
