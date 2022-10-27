{ lib, buildPythonPackage, hexdump, intelhex, ruamel-yaml, colorama, python-cstruct, python-easyhid, python-xusbboot, python-efm8boot, python-kp_boot_32u4 }:
buildPythonPackage rec {
    pname = "keyplus";
    version = "0.4.0pre1";

    src = ./.;

    propagatedBuildInputs = [
        hexdump
        intelhex
        ruamel-yaml
        colorama
        python-cstruct
        python-easyhid
        python-xusbboot
        python-efm8boot
        python-kp_boot_32u4
    ];

    # No tests are available
    doCheck = false;
    pythonImportsCheck = [ "keyplus" ];

    meta = with lib; {
      description = "Python library for interfacing with keyplus keyboards";
      homepage = "https://github.com/ahtn/keyplus";
      license = licenses.mit;
      maintainers = with maintainers; [ emilytrau ];
    };
}
