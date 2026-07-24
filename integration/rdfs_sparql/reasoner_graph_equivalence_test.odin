package rdfs_sparql

import "core:testing"
import rdf "odin-rdf:rdf"
import turtle "odin-rdf:rdf/turtle"
import engine "odin-sparql:sparql/engine"
import graph "odin-graph:graph"
import graph_reasoner "../../../odin-graph/adapter/reasoner"
import graph_sparql "../../../odin-graph/adapter/sparql"
import sparql_adapter "../../../odin-reasoner/adapter/sparql"
import importer "../../../odin-reasoner/reasoner/import"
import rdfs "../../../odin-reasoner/reasoner/rdfs"
import rule "../../../odin-reasoner/reasoner/rule"
import store "../../../odin-reasoner/reasoner/store"

@(test)
test_reasoner_closure_graph_adapter_matches_existing_snapshot_queries :: proc(t: ^testing.T) {
	source_text := read(t, SOURCE_PATH)
	defer delete(source_text)

	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	profile: rdfs.Profile
	profile_error, store_error := rdfs.init(&profile, &source)
	testing.expect_value(t, profile_error, rdfs.Error_Code.None)
	testing.expect_value(t, store_error, store.Error_Code.None)
	state: importer.Sink_State
	importer.init(&state, &source)
	parsed := turtle.parse(string(source_text), importer.triple_sink, {}, &state)
	testing.expect_value(t, parsed.code, turtle.Error_Code.None)
	testing.expect_value(t, state.last_error, store.Error_Code.None)
	materialized := rdfs.materialize(&profile, &source)
	testing.expect_value(t, materialized.error, rule.Error_Code.None)
	testing.expect_value(t, store.fact_count(&source), 14)

	legacy: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&legacy, &source), sparql_adapter.Error_Code.None)
	defer sparql_adapter.destroy(&legacy)
	candidate: graph.Graph
	testing.expect_value(t, graph_reasoner.init(&candidate, &source), graph_reasoner.Error.None)
	defer graph.destroy(&candidate)
	rdfs.destroy(&profile)
	store.destroy(&source)

	legacy_view := sparql_adapter.view(&legacy)
	graph_adapter: graph_sparql.View
	testing.expect_value(t, graph_sparql.init(&graph_adapter, &candidate), graph.Error.None)
	graph_view := graph_sparql.dataset_view(&graph_adapter)

	select_text := read(t, QUERY_ROOT + "select-agent.rq")
	defer delete(select_text)
	legacy_select := execute(t, string(select_text), legacy_view)
	defer engine.destroy(&legacy_select)
	graph_select := execute(t, string(select_text), graph_view)
	defer engine.destroy(&graph_select)
	testing.expect_value(t, engine.Row_Count(&graph_select), engine.Row_Count(&legacy_select))
	for index in 0..<engine.Row_Count(&legacy_select) {
		legacy_term, legacy_bound, legacy_valid := engine.Cell(&legacy_select, index, 0)
		graph_term, graph_bound, graph_valid := engine.Cell(&graph_select, index, 0)
		testing.expect(t, legacy_valid && legacy_bound && graph_valid && graph_bound)
		testing.expect(t, same_term(legacy_term, graph_term))
	}

	ask_text := read(t, QUERY_ROOT + "ask-bea-person.rq")
	defer delete(ask_text)
	legacy_ask_result := execute(t, string(ask_text), legacy_view)
	defer engine.destroy(&legacy_ask_result)
	graph_ask_result := execute(t, string(ask_text), graph_view)
	defer engine.destroy(&graph_ask_result)
	legacy_ask, legacy_ask_valid := engine.Ask_Value(&legacy_ask_result)
	graph_ask, graph_ask_valid := engine.Ask_Value(&graph_ask_result)
	testing.expect(t, legacy_ask_valid && graph_ask_valid)
	testing.expect_value(t, graph_ask, legacy_ask)

	construct_text := read(t, QUERY_ROOT + "construct-related.rq")
	defer delete(construct_text)
	legacy_construct := execute(t, string(construct_text), legacy_view)
	defer engine.destroy(&legacy_construct)
	graph_construct := execute(t, string(construct_text), graph_view)
	defer engine.destroy(&graph_construct)
	testing.expect_value(t, engine.Triple_Count(&graph_construct), engine.Triple_Count(&legacy_construct))
}
