#!/usr/bin/env bash
#
# This file should not be run directly.

if ! [[ -x "$(command -v rustc)" ]]; then
  echo 'Error: The Rust compiler needs to be installed. See https://rustup.rs/ for install instructions.' >&2
  exit 1
fi
