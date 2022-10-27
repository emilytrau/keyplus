{
    description = "An easy to use, wired and wireless modular keyboard firmware";

    nixConfig = {
        bash-prompt-prefix = "(keyplus) ";
        extra-trusted-substituters = [ "https://keyplus.cachix.org" ];
        extra-trusted-public-keys = [
            "keyplus.cachix.org-1:qb7JdXS2YJEClsL+qOfNW9HuBHIaws+CTd8onsVt+e4="
        ];
    };

    inputs.flake-utils.url = "github:numtide/flake-utils";

    inputs.python-cstruct.url = "github:andreax79/python-cstruct/v3.3";
    inputs.python-cstruct.flake = false;

    inputs.python-easyhid.url = "github:ahtn/python-easyhid";
    inputs.python-easyhid.flake = false;

    inputs.xusb-boot.url = "github:ahtn/xusb-boot";
    inputs.xusb-boot.flake = false;

    inputs.python-efm8boot.url = "github:ahtn/python-efm8boot";
    inputs.python-efm8boot.flake = false;

    inputs.kp_boot_32u4.url = "github:ahtn/kp_boot_32u4";
    inputs.kp_boot_32u4.flake = false;

    inputs.nrf5-sdk.url = "https://www.nordicsemi.com/-/media/Software-and-other-downloads/SDKs/nRF5/Binaries/nRF5SDK153059ac345.zip";
    inputs.nrf5-sdk.flake = false;

    outputs = inputs@{ self, nixpkgs, flake-utils, python-cstruct, python-easyhid, xusb-boot, python-efm8boot, kp_boot_32u4, nrf5-sdk, ... }:
        flake-utils.lib.eachDefaultSystem
            (system:
                let
                    pkgs = nixpkgs.legacyPackages.${system};
                    inherit (pkgs) lib;
                in
                rec {
                    devShells.default = import ./shell.nix { inherit pkgs; };

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

                        src = python-easyhid;

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

                        src = xusb-boot;

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

                        src = python-efm8boot;

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

                        src = kp_boot_32u4;

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
                            pkgsCross.avr.buildPackages.gcc6
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

                    packages.nrf52 = pkgs.stdenv.mkDerivation rec {
                        name = "keyplus-nrf52840";

                        src = self;

                        makeFlags = [
                            "--directory=ports/nrf52"
                            "BOARD=nrf52840_dk"
                            "LAYOUT_FILE=${./layouts}/nrf52_4key.yaml"
                            "ID=0"
                            "GIT_HASH_FULL=${if (self ? rev) then self.rev else "0000000000000000000000000000000000000000"}"
                            "GNU_INSTALL_ROOT=${pkgs.gcc-arm-embedded-6}/bin/"
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
