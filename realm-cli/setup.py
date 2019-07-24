#!/usr/bin/env python

from setuptools import setup, find_packages


with open("README.md", "r") as fh:
    long_description = fh.read()


setup(
    name="realm_cli",
    version="0.0.8",
    entry_points={"console_scripts": ["realm-cli=realm_cli.main:main"]},
    author="nilinswap",
    author_email="nilinswap@gmail.com",
    description="A command line utitily to provide services offered by realm( a rust-elm web framework).",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/ackotech/realm/",
    packages=find_packages(),
    install_requires=["cookiecutter>=1.6.0"],
)
