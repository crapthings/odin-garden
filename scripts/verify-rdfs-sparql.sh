#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root"

require_revision() {
  path=$1
  expected=$2
  actual=$(git -C "$path" rev-parse HEAD)
  if [ "$actual" != "$expected" ]; then
    printf '%s\n' "expected $path at $expected, found $actual" >&2
    exit 1
  fi
}

require_revision ../odin-rdf daa350521a8ad9f79012bb1fefa96cf00938f3f1
require_revision ../odin-reasoner 3ac9267f8651eb9add25b13ac8e12b952e63a959
require_revision ../odin-sparql fcba9b6ffd542f246bf026d69dbd045624315c8d

expected_odin='dev-2026-07-nightly:ab0131c'
actual_odin=$(odin version)
actual_odin=${actual_odin##* version }
if [ "$actual_odin" != "$expected_odin" ]; then
  printf '%s\n' "expected $expected_odin, found $actual_odin" >&2
  exit 1
fi

odin test integration/rdfs_sparql \
  -collection:odin-rdf=../odin-rdf \
  -collection:odin-sparql=../odin-sparql
