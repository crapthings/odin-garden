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

require_revision ../odin-rdf eac24a8d3251d03cb3fe700e6ffbda0ad1a47ee4
require_revision ../odin-sparql 4150774bfecc23ea027036084b1edbd41dad13e5

require_release_tag ../odin-rdf v0.33.0 eac24a8d3251d03cb3fe700e6ffbda0ad1a47ee4
require_release_tag ../odin-sparql v0.7.0 4150774bfecc23ea027036084b1edbd41dad13e5

expected_odin='dev-2026-07-nightly:ab0131c'
actual_odin=$(odin version)
actual_odin=${actual_odin##* version }
if [ "$actual_odin" != "$expected_odin" ]; then
	printf '%s\n' "expected $expected_odin, found $actual_odin" >&2
	exit 1
fi

if rg -q '^[[:space:]]*import .*odin-graph' integration/sparql_core; then
	printf '%s\n' 'core SPARQL release gate must not import odin-graph' >&2
	exit 1
fi

odin test integration/sparql_core \
	-collection:odin-rdf=../odin-rdf \
	-collection:odin-sparql=../odin-sparql
