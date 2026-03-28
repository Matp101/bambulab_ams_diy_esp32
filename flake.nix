{
  description = "Bambu AMS DIY ESP32";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;

      forAllSystems =
        fn:
        lib.genAttrs lib.systems.flakeExposed (
          system:
          fn {
            pkgs = import inputs.nixpkgs {
              inherit system;
            };
            inherit system;
          }
        );
    in
    {
      packages = forAllSystems (
        {
          pkgs,
          system,
          ...
        }:
        let
          fhsPkgs = pkgs: with pkgs; [
            platformio-core
            python3
            git
            esptool
            gcc
            gnumake
            udev
            zlib
            ncurses
            stdenv.cc.cc.lib
            glibc
            libusb1
            openssl
            cacert
          ];

          fhsProfile = ''
            export PLATFORMIO_CORE_DIR="''${PLATFORMIO_CORE_DIR:-$PWD/.platformio}"
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          '';

          mkPioCmd = name: cmd:
            pkgs.buildFHSEnv {
              inherit name;
              targetPkgs = fhsPkgs;
              profile = fhsProfile;
              runScript = pkgs.writeScript name ''
                #!/bin/bash
                set -e
                exec ${cmd}
              '';
            };
        in
        {
          build = mkPioCmd "build" "platformio run -e esp32dev";
          flash = mkPioCmd "flash" "platformio run -e esp32dev --target upload";
          flash-ota = mkPioCmd "flash-ota" "platformio run -e esp32dev-ota --target upload";
          monitor = mkPioCmd "monitor" "platformio device monitor --baud 115200";
          default = mkPioCmd "build" "platformio run -e esp32dev";
        }
      );

      devShells = forAllSystems (
        { pkgs, ... }:
        {
          default =
            (pkgs.buildFHSEnv {
              name = "bambu-ams-diy-esp32-dev";
              targetPkgs = pkgs: with pkgs; [
                platformio-core
                python3
                git
                esptool
                gcc
                gnumake
                udev
                zlib
                ncurses
                stdenv.cc.cc.lib
                glibc
                libusb1
                openssl
                cacert
              ];
              profile = ''
                export PLATFORMIO_CORE_DIR="''${PLATFORMIO_CORE_DIR:-$PWD/.platformio}"
                export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              '';
              runScript = "bash";
            }).env;
        }
      );

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt-tree);
    };
}
