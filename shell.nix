{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    cachix
    pkgsCross.avr.buildPackages.gcc6
  ];
}
