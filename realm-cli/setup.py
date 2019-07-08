#!/usr/bin/env python

from setuptools import setup, find_packages

setup(
    name = "realm_cli",
     entry_points = {
        'console_scripts': ['realm-cli=realm_cli.main:main']
    },
    py_modules = find_packages()
)