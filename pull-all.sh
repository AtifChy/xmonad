#!/bin/sh -eu

# Put all submodules on master from upstream:
git submodule foreach 'git checkout master && git pull'
