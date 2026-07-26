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
require_revision ../odin-sparql 4150774bfecc23ea027036084b1edbd41dad13e5
require_revision ../odin-cli 488e7be86dd8dba04f644f178a195c1564252387

require_release_tag ../odin-rdf v0.33.0 eac24a8d3251d03cb3fe700e6ffbda0ad1a47ee4
require_release_tag ../odin-shacl v0.1.0 4ee8249b84380e4ef1d888bd94f8cd24d6e7b985
require_release_tag ../odin-sparql v0.7.0 4150774bfecc23ea027036084b1edbd41dad13e5
require_release_tag ../odin-cli v0.2.0 488e7be86dd8dba04f644f178a195c1564252387

expected_odin='dev-2026-07-nightly:ab0131c'
actual_odin=$(odin version)
actual_odin=${actual_odin##* version }
if [ "$actual_odin" != "$expected_odin" ]; then
	printf '%s\n' "expected $expected_odin, found $actual_odin" >&2
	exit 1
fi

if rg -q '^[[:space:]]*import .*odin-graph' ../odin-cli/cmd/odin; then
	printf '%s\n' 'CLI query release gate must not import odin-graph' >&2
	exit 1
fi

select_output=$(mktemp "${TMPDIR:-/tmp}/odin-cli-query-select.XXXXXX")
select_diagnostics=$(mktemp "${TMPDIR:-/tmp}/odin-cli-query-select-diagnostics.XXXXXX")
construct_output=$(mktemp "${TMPDIR:-/tmp}/odin-cli-query-construct.XXXXXX")
construct_diagnostics=$(mktemp "${TMPDIR:-/tmp}/odin-cli-query-construct-diagnostics.XXXXXX")
binary=$(mktemp "${TMPDIR:-/tmp}/odin-cli-query-bin.XXXXXX")
rm -f "$binary"
trap 'rm -f "$select_output" "$select_diagnostics" "$construct_output" "$construct_diagnostics" "$binary"' EXIT HUP INT TERM

run_query() {
	query=$1
	output=$2
	diagnostics=$3
	set +e
	odin run ../odin-cli/cmd/odin \
		-out:"$binary" \
		-collection:odin-rdf=../odin-rdf \
		-collection:odin-shacl=../odin-shacl \
		-collection:odin-sparql=../odin-sparql \
		-- query \
		--data fixtures/cli/query-local-friends/data.ttl \
		--query "fixtures/cli/query-local-friends/$query" \
		--max-data-triples 8 \
		--max-statement-bytes 1024 \
		--max-query-bytes 512 \
		--max-results 8 \
		>"$output" 2>"$diagnostics"
	exit_code=$?
	set -e
	if [ "$exit_code" -ne 0 ]; then
		printf '%s\n' "expected odin query $query to exit 0, found $exit_code" >&2
		cat "$diagnostics" >&2
		exit 1
	fi
	if [ -s "$diagnostics" ]; then
		printf '%s\n' "expected no diagnostic output for completed query $query" >&2
		cat "$diagnostics" >&2
		exit 1
	fi
}

run_query select.rq "$select_output" "$select_diagnostics"
expected_select=$(tr -d '\n' < fixtures/cli/query-local-friends/expected-select.json)
expected_select_bytes=$(printf '%s' "$expected_select" | wc -c | tr -d '[:space:]')
actual_select_bytes=$(wc -c < "$select_output" | tr -d '[:space:]')
if [ "$actual_select_bytes" != "$expected_select_bytes" ] || [ "$(cat "$select_output")" != "$expected_select" ]; then
	printf '%s\n' 'odin query SELECT JSON output did not match the versioned fixture' >&2
	exit 1
fi

rm -f "$binary"
run_query construct.rq "$construct_output" "$construct_diagnostics"
if ! cmp -s "$construct_output" fixtures/cli/query-local-friends/expected-construct.nt; then
	printf '%s\n' 'odin query CONSTRUCT N-Triples output did not match the versioned fixture' >&2
	diff -u fixtures/cli/query-local-friends/expected-construct.nt "$construct_output" >&2 || true
	exit 1
fi
