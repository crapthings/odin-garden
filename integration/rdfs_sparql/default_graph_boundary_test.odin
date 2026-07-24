package rdfs_sparql

import "core:testing"
import rdf "odin-rdf:rdf"
import turtle "odin-rdf:rdf/turtle"
import sparql_adapter "../../../odin-reasoner/adapter/sparql"
import importer "../../../odin-reasoner/reasoner/import"
import store "../../../odin-reasoner/reasoner/store"
import dataset "odin-sparql:sparql/dataset"

DEFAULT_GRAPH_SOURCE_PATH :: "fixtures/rdfs-core/default-graph-boundary/source.ttl"

@(private) Boundary_Stop_State :: struct { calls: int }

@(private) boundary_stop_after_one :: proc(_: rdf.Quad, user_data: rawptr) -> bool {
	(cast(^Boundary_Stop_State)user_data).calls += 1
	return false
}

@(test)
test_default_graph_scope_and_atomic_snapshot_limit :: proc(t: ^testing.T) {
	source_text := read(t, DEFAULT_GRAPH_SOURCE_PATH)
	defer delete(source_text)

	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	state: importer.Sink_State
	importer.init(&state, &source)
	parsed := turtle.parse(string(source_text), importer.triple_sink, {}, &state)
	testing.expect_value(t, parsed.code, turtle.Error_Code.None)
	testing.expect_value(t, state.last_error, store.Error_Code.None)
	testing.expect_value(t, state.inserted, 2)
	testing.expect_value(t, state.duplicates, 0)
	testing.expect_value(t, store.fact_count(&source), 2)

	limited_snapshot: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&limited_snapshot, &source, {max_quads = 1}), sparql_adapter.Error_Code.Quad_Limit)
	testing.expect_value(t, sparql_adapter.quad_count(&limited_snapshot), 0)
	testing.expect_value(t, store.fact_count(&source), 2)

	snapshot: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&snapshot, &source), sparql_adapter.Error_Code.None)
	store.destroy(&source)
	defer sparql_adapter.destroy(&snapshot)
	view := sparql_adapter.view(&snapshot)

	stop_state: Boundary_Stop_State
	stop_error := dataset.scan(view, {Has_Predicate = true, Predicate = rdf.iri("https://example.org/garden/relatedTo")}, boundary_stop_after_one, &stop_state)
	testing.expect_value(t, stop_error, dataset.Error_Code.None)
	testing.expect_value(t, stop_state.calls, 1)

	named_error := dataset.scan(view, {Graph_Mode = .Named, Graph = rdf.iri("https://example.org/garden/graph")}, boundary_stop_after_one, &stop_state)
	any_named_error := dataset.scan(view, {Graph_Mode = .Any_Named}, boundary_stop_after_one, &stop_state)
	testing.expect_value(t, named_error, dataset.Error_Code.Invalid_View)
	testing.expect_value(t, any_named_error, dataset.Error_Code.Invalid_View)
}
