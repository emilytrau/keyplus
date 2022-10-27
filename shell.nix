{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    pkgsCross.avr.buildPackages.gcc6
  ];
}
