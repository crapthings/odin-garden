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

require_release_tag() {
	path=$1
	tag=$2
	expected=$3
	actual=$(git -C "$path" rev-parse "$tag^{commit}" 2>/dev/null) || {
		printf '%s\n' "expected $path to contain release tag $tag" >&2
		exit 1
	}
	if [ "$actual" != "$expected" ]; then
		printf '%s\n' "expected $path tag $tag at $expected, found $actual" >&2
		exit 1
	fi
}

require_revision ../odin-rdf daa350521a8ad9f79012bb1fefa96cf00938f3f1
require_revision ../odin-reasoner c62ebd8b5070eeb44c5b818bc30698b4f0da0b26
require_revision ../odin-sparql 76ec6b5f3ece65ff65131939106a5973333dd5f2
require_revision ../odin-graph 5c970316ba2008a2fbfea388d1a8c6a56ae94a1f

require_release_tag ../odin-rdf v0.31.1 daa350521a8ad9f79012bb1fefa96cf00938f3f1
require_release_tag ../odin-reasoner v0.3.0 c62ebd8b5070eeb44c5b818bc30698b4f0da0b26
require_release_tag ../odin-sparql v0.1.2 76ec6b5f3ece65ff65131939106a5973333dd5f2

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
