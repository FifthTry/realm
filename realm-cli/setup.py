#!/usr/bin/env python

from setuptools import setup

setup(
     entry_points = {
        'console_scripts': ['realm-cli=realm_cli.main:main']
    }
)