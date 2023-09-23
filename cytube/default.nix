{pkgs ? import <nixpkgs> {} }:

pkgs.buildNpmPackage rec {
  pname = "cytube";
  version = "3.86.0";

  src = pkgs.fetchFromGitHub {
    owner = "calzoneman";
    repo = "sync";
    rev = "227244e2d0420a20afe4acb0ac7adf7610db6233";
    hash = "sha256-T0JqOZ8oVRyOT++YfzeEobsa29mDrWx6TDSrgAirSzM=";
  };

  npmDepsHash = "sha256-zZzIJD72/Uo3ljmV+pnW0jGnyvypJRlhKjPaW/O3QQU=";
  makeCacheWritable = true;
  npmFlags = [ "--legacy-peer-deps" ];
  forceGitDeps = true;

  meta = with pkgs.lib; {
    description = "Online media synchronizer and chat";
    homepage = "http://github.com/calzoneman/sync";
    license = licenses.mit;
  };
}
