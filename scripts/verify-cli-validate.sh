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
require_revision ../odin-shacl 4ee8249b84380e4ef1d888bd94f8cd24d6e7b985
require_revision ../odin-cli 63c639e8cdc2a691377f36085631cb4bf4664b02

require_release_tag ../odin-rdf v0.33.0 eac24a8d3251d03cb3fe700e6ffbda0ad1a47ee4
require_release_tag ../odin-shacl v0.1.0 4ee8249b84380e4ef1d888bd94f8cd24d6e7b985
require_release_tag ../odin-cli v0.1.0 63c639e8cdc2a691377f36085631cb4bf4664b02

expected_odin='dev-2026-07-nightly:ab0131c'
actual_odin=$(odin version)
actual_odin=${actual_odin##* version }
if [ "$actual_odin" != "$expected_odin" ]; then
	printf '%s\n' "expected $expected_odin, found $actual_odin" >&2
	exit 1
fi

output=$(mktemp "${TMPDIR:-/tmp}/odin-cli-validate.XXXXXX")
diagnostics=$(mktemp "${TMPDIR:-/tmp}/odin-cli-validate-diagnostics.XXXXXX")
binary=$(mktemp "${TMPDIR:-/tmp}/odin-cli-validate-bin.XXXXXX")
rm -f "$binary"
trap 'rm -f "$output" "$diagnostics" "$binary"' EXIT HUP INT TERM

set +e
odin run ../odin-cli/cmd/odin \
	-out:"$binary" \
	-collection:odin-rdf=../odin-rdf \
	-collection:odin-shacl=../odin-shacl \
	-- validate \
	--data fixtures/shacl-core/person-record/data.ttl \
	--shapes fixtures/shacl-core/person-record/shapes.ttl \
	--max-data-triples 32 \
	--max-shapes-triples 32 \
	--max-statement-bytes 1048576 \
	--max-results 8 \
	>"$output" 2>"$diagnostics"
exit_code=$?
set -e

if [ "$exit_code" -ne 1 ]; then
	printf '%s\n' "expected odin validate to exit 1 for violations, found $exit_code" >&2
	cat "$diagnostics" >&2
	exit 1
fi
if [ -s "$diagnostics" ]; then
	printf '%s\n' "expected no diagnostic output for a completed validation" >&2
	cat "$diagnostics" >&2
	exit 1
fi
if ! cmp -s "$output" fixtures/cli/validate-person-record/expected-report.json; then
	printf '%s\n' "odin validate JSON output did not match the versioned fixture" >&2
	diff -u fixtures/cli/validate-person-record/expected-report.json "$output" >&2 || true
	exit 1
fi
