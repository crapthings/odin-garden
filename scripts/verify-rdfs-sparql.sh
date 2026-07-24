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

require_revision ../odin-rdf acb3a190371e8679a2a35a3d4668ec166ec24891
require_revision ../odin-reasoner a46a693f30b00360d6adcf761188cdef681959e1
require_revision ../odin-sparql 00acabd46113676820a55955328b5532149fbf47

expected_odin='dev-2026-07:819fdc7a8'
actual_odin=$(odin version)
actual_odin=${actual_odin##* version }
if [ "$actual_odin" != "$expected_odin" ]; then
  printf '%s\n' "expected $expected_odin, found $actual_odin" >&2
  exit 1
fi

odin test integration/rdfs_sparql \
  -collection:odin-rdf=../odin-rdf \
  -collection:odin-sparql=../odin-sparql
