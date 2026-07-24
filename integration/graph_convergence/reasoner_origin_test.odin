// Development-only convergence gate for current Graph and Reasoner sources.
// It intentionally lives outside the release-qualified RDFS-to-SPARQL package.
package graph_convergence

import "core:os"
import "core:testing"
import rdf "odin-rdf:rdf"
import turtle "odin-rdf:rdf/turtle"
import graph "odin-graph:graph"
import graph_reasoner "../../../odin-graph/adapter/reasoner"
import importer "../../../odin-reasoner/reasoner/import"
import rdfs "../../../odin-reasoner/reasoner/rdfs"
import rule "../../../odin-reasoner/reasoner/rule"
import store "../../../odin-reasoner/reasoner/store"

SOURCE_PATH :: "fixtures/rdfs-core/first-closure/source.ttl"

@(test)
test_graph_closure_copy_preserves_every_rdfs_fact_origin :: proc(t: ^testing.T) {
	source_text, read_error := os.read_entire_file(SOURCE_PATH, context.allocator)
	testing.expect(t, read_error == nil)
	defer delete(source_text)

	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	defer store.destroy(&source)
	profile: rdfs.Profile
	profile_error, store_error := rdfs.init(&profile, &source)
	testing.expect_value(t, profile_error, rdfs.Error_Code.None)
	testing.expect_value(t, store_error, store.Error_Code.None)
	defer rdfs.destroy(&profile)
	state: importer.Sink_State
	importer.init(&state, &source)
	parsed := turtle.parse(string(source_text), importer.triple_sink, {}, &state)
	testing.expect_value(t, parsed.code, turtle.Error_Code.None)
	testing.expect_value(t, state.last_error, store.Error_Code.None)
	materialized := rdfs.materialize(&profile, &source)
	testing.expect_value(t, materialized.error, rule.Error_Code.None)
	testing.expect_value(t, store.fact_count(&source), 14)

	candidate: graph.Graph
	testing.expect_value(t, graph_reasoner.init(&candidate, &source), graph_reasoner.Error.None)
	defer graph.destroy(&candidate)
	testing.expect_value(t, graph.quad_count(&candidate), store.fact_count(&source))
	for index in 0..<store.fact_count(&source) {
		_, _, source_origin, found := store.fact_at(&source, index)
		testing.expect(t, found)
		candidate_origin, candidate_found := graph.origin_at(&candidate, index)
		testing.expect(t, candidate_found)
		expected_origin := source_origin == .Inferred ? graph.Origin.Inferred : graph.Origin.Asserted
		testing.expect_value(t, candidate_origin, expected_origin)
	}
}
