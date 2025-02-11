{
    description = "An easy to use, wired and wireless modular keyboard firmware";

    nixConfig = {
        bash-prompt-prefix = "(keyplus) ";
        extra-trusted-substituters = [ "https://keyplus.cachix.org" ];
        extra-trusted-public-keys = [
            "keyplus.cachix.org-1:qb7JdXS2YJEClsL+qOfNW9HuBHIaws+CTd8onsVt+e4="
        ];
    };

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    inputs.flake-utils.url = "github:numtide/flake-utils";

    inputs.python-cstruct.url = "github:andreax79/python-cstruct/v3.3";
    inputs.python-cstruct.flake = false;

    outputs = inputs@{ self, nixpkgs, flake-utils, python-cstruct, ... }:
        flake-utils.lib.eachDefaultSystem
            (system:
                let
                    pkgs = nixpkgs.legacyPackages.${system};
                    inherit (pkgs) lib;

                    nrf5-sdk = pkgs.fetchzip {
                        url = "https://www.nordicsemi.com/-/media/Software-and-other-downloads/SDKs/nRF5/Binaries/nRF5SDK153059ac345.zip";
                        hash = "sha256-pfmhbpgVv5x2ju489XcivguwpnofHbgVA7bFUJRTj08=";
                    };
                in
                rec {
                    devShells.default = import ./shell.nix { inherit pkgs; };

                    # SDCC can be pretty buggy from release to release,
                    # so often need to compile from source to get things to
                    # work well.
                    packages.sdcc = (pkgs.sdcc.override {
                            excludePorts = ["z80" "z180" "r2k" "r3ka" "gbz80" "tlcs90" "ds390" "ds400" "pic14" "pic16" "hc08" "s08" "stm8"];
                        }).overrideAttrs (old: rec {
                            version = "r9948";
                            src = pkgs.fetchsvn {
                                url = "https://svn.code.sf.net/p/sdcc/code/trunk/sdcc";
                                rev = version;
                                sha256 = "1vgsbibfdp4py2ldl3gpmgrjk6hladwmpdnnlrrlk2v8w1nshx9x";
                            };
                        });

                    packages.python-cstruct = pkgs.python3Packages.buildPythonPackage rec {
                        pname = "cstruct";
                        version = "3.3";

                        src = python-cstruct;

                        checkInputs = with pkgs.python3Packages; [ pytestCheckHook ];
                        pythonImportsCheck = [ "cstruct" ];

                        meta = with lib; {
                            description = "Convert C struct definitions into Python classes with methods for serializing/deserializing";
                            homepage = "http://github.com/andreax79/python-cstruct";
                            license = licenses.mit;
                            maintainers = with maintainers; [ emilytrau ];
                        };
                    };

                    packages.python-easyhid = pkgs.python3Packages.buildPythonPackage rec {
                        pname = "easyhid";
                        version = "0.0.10";

                        src = "${./vendor/python-easyhid}";

                        postPatch = ''
                            substituteInPlace easyhid/easyhid.py \
                                --replace "ffi.dlopen('hidapi')" "ffi.dlopen('${pkgs.hidapi}/lib/libhidapi${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}')" \
                                --replace "ffi.dlopen('hidapi-hidraw')" "ffi.dlopen('${pkgs.hidapi}/lib/libhidapi-hidraw${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}')"
                        '';

                        propagatedBuildInputs = with pkgs.python3Packages; [ cffi ];

                        # No tests are available
                        doCheck = false;
                        pythonImportsCheck = [ "easyhid" ];

                        meta = with lib; {
                            description = "A simple interface to the HIDAPI library";
                            homepage = "http://github.com/ahtn/python-easyhid";
                            license = licenses.mit;
                            maintainers = with maintainers; [ emilytrau ];
                            platforms = platforms.unix;
                        };
                    };

                    packages.python-xusbboot = pkgs.python3Packages.buildPythonPackage rec {
                        pname = "xusbboot";
                        version = "0.0.2";

                        src = "${./vendor}/xusb-boot";

                        preConfigure = ''
                            cd scripts
                        '';

                        propagatedBuildInputs = with pkgs.python3Packages; [ packages.python-easyhid hexdump intelhex ];

                        # No tests are available
                        doCheck = false;
                        pythonImportsCheck = [ "xusbboot" ];

                        meta = with lib; {
                            description = "Python library for xmega xusb bootloader";
                            homepage = "http://github.com/ahtn/xusb-boot";
                            license = licenses.mit;
                            maintainers = with maintainers; [ emilytrau ];
                        };
                    };

                    packages.python-efm8boot = pkgs.python3Packages.buildPythonPackage rec {
                        pname = "efm8boot";
                        version = "0.0.8";

                        src = "${./vendor/python-efm8boot}";

                        propagatedBuildInputs = with pkgs.python3Packages; [ packages.python-easyhid crcmod intelhex ];

                        # No tests are available
                        doCheck = false;
                        pythonImportsCheck = [ "efm8boot" ];

                        meta = with lib; {
                            description = "A python package for working with efm8 bootloaders";
                            homepage = "https://github.com/ahtn/python-efm8boot";
                            license = licenses.mit;
                            maintainers = with maintainers; [ emilytrau ];
                        };
                    };

                    packages.python-kp_boot_32u4 = pkgs.python3Packages.buildPythonPackage rec {
                        pname = "kp_boot_32u4";
                        version = "0.0.3";

                        src = "${./vendor}/kp_boot_32u4";

                        propagatedBuildInputs = with pkgs.python3Packages; [ packages.python-easyhid hexdump intelhex ];

                        # No tests are available
                        doCheck = false;
                        pythonImportsCheck = [ "kp_boot_32u4" ];

                        meta = with lib; {
                            description = "driverless, 1kb bootloader for atmega32u4, with support for writing flash and eeprom";
                            homepage = "https://github.com/ahtn/kp_boot_32u4";
                            license = licenses.mit;
                            maintainers = with maintainers; [ emilytrau ];
                        };
                    };

                    packages.keyplus = pkgs.python3Packages.callPackage ./host-software {
                        inherit (packages) python-cstruct python-easyhid python-xusbboot python-efm8boot python-kp_boot_32u4;
                    };

                    packages.xmega = pkgs.stdenv.mkDerivation rec {
                        name = "keyplus-xmega";

                        src = self;

                        nativeBuildInputs = with pkgs; [
                            pkgsCross.avr.buildPackages.gcc8
                        ];

                        makeFlags = [
                            "--directory=ports/xmega"
                            "BOARD=keyplus_mini"
                            "LAYOUT_FILE=${./layouts}/small_split_test.yaml"
                            "ID=12"
                            "GIT_HASH_FULL=${if (self ? rev) then self.rev else "0000000000000000000000000000000000000000"}"
                            "PYTHON_CMD=${pkgs.python3.interpreter}"
                            "KEYPLUS_CLI=${packages.keyplus}/bin/keyplus-cli"
                        ];

                        installPhase = ''
                          runHook preInstall

                          mkdir $out
                          find ports/xmega -name "*.hex" -exec install {} $out \;

                          runHook postInstall
                        '';
                    };

                    packages.atmega32u4 = pkgs.stdenv.mkDerivation rec {
                        name = "keyplus-atmega32u4";

                        src = self;

                        nativeBuildInputs = with pkgs; [
                            pkgsCross.avr.buildPackages.gcc8
                        ];

                        makeFlags = [
                            "--directory=ports/atmega32u4"
                            "MCU=atmega32u4"
                            "BOARD=default"
                            "LAYOUT_FILE=${./layouts}/1key.yaml"
                            "GIT_HASH_FULL=${if (self ? rev) then self.rev else "0000000000000000000000000000000000000000"}"
                            "PYTHON_CMD=${pkgs.python3.interpreter}"
                            "KEYPLUS_CLI=${packages.keyplus}/bin/keyplus-cli"
                        ];

                        installPhase = ''
                          runHook preInstall

                          mkdir $out
                          find ports/atmega32u4 -name "*.hex" -exec install {} $out \;

                          runHook postInstall
                        '';
                    };

                    packages.unirecv = pkgs.stdenv.mkDerivation rec {
                        name = "keyplus-unirecv";

                        src = self;

                        postPatch = ''
                            patchShebangs .
                        '';

                        makeFlags = [
                            "--directory=ports/nrf24lu1"
                            "BOARD=unirecv"
                            "LAYOUT_FILE=${./layouts}/basic_split_test.yaml"
                            "ID=48"
                            "GIT_HASH_FULL=${if (self ? rev) then self.rev else "0000000000000000000000000000000000000000"}"
                            "SDCC_PATH=${packages.sdcc}"
                            "SDCC_BIN_PATH=${packages.sdcc}/bin"
                            "PYTHON_CMD=${pkgs.python3.interpreter}"
                            "KEYPLUS_CLI=${packages.keyplus}/bin/keyplus-cli"
                        ];

                        installPhase = ''
                          runHook preInstall

                          mkdir $out
                          find ports/nrf24lu1 -name "*.hex" -exec install {} $out \;

                          runHook postInstall
                        '';
                    };

                    packages.nrf52 = pkgs.stdenv.mkDerivation rec {
                        name = "keyplus-nrf52840";

                        src = self;

                        makeFlags = [
                            "--directory=ports/nrf52"
                            "BOARD=nrf52840_dk"
                            "LAYOUT_FILE=${./layouts}/nrf52_4key.yaml"
                            "ID=0"
                            "GIT_HASH_FULL=${if (self ? rev) then self.rev else "0000000000000000000000000000000000000000"}"
                            "GNU_INSTALL_ROOT=${pkgs.gcc-arm-embedded-8}/bin/"
                            "NRF52_SDK_ROOT=${nrf5-sdk}"
                            "PYTHON_CMD=${pkgs.python3.interpreter}"
                            "KEYPLUS_CLI=${packages.keyplus}/bin/keyplus-cli"
                        ];

                        installPhase = ''
                          runHook preInstall

                          mkdir $out
                          find ports/nrf52 -name "*.hex" -exec install {} $out \;

                          runHook postInstall
                        '';
                    };
                }
            );
}
