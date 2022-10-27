#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright 2018 jem@seethis.link
# Licensed under the MIT license (http://opensource.org/licenses/MIT)

from setuptools import setup, find_packages
import os
import sys

if sys.version_info < (3, 5):
    sys.exit("Requires python 3.5+")

# Load the version number
fields = {}
with open(os.path.join("keyplus", "version.py")) as f:
    exec(f.read(), fields)
__version__ = fields['__version__']


setup(
    name = 'keyplus',
    version = __version__,
    description = "Python library for interfacing with keyplus keyboards.",
    url = "http://github.com/ahtn/keyplus",
    author = "jem",
    author_email = "jem@seethis.link",
    license = 'MIT',
    packages = find_packages(include=['keyplus', 'keyplus.*']),
    install_requires = [
        'cstruct', 'hexdump', 'intelhex', 'ruamel.yaml', 'colorama',
        # Closely related
        'easyhid>=0.0.10',
        'xusbboot>=0.0.2',
        'efm8boot>=0.0.7',
        'kp_boot_32u4>=0.0.2',
    ],
    keywords = ['keyboard', 'usb', 'hid'],
    scripts = ['keyplus-cli', 'keyplus_flasher.py'],
    zip_safe = False,
)
