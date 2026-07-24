package rdfs_sparql

import "core:testing"
import turtle "odin-rdf:rdf/turtle"
import sparql_adapter "../../../odin-reasoner/adapter/sparql"
import importer "../../../odin-reasoner/reasoner/import"
import rdfs "../../../odin-reasoner/reasoner/rdfs"
import rule "../../../odin-reasoner/reasoner/rule"
import store "../../../odin-reasoner/reasoner/store"
import engine "odin-sparql:sparql/engine"

@(test)
test_live_indexed_view_matches_immutable_snapshot_for_rdfs_closure :: proc(t: ^testing.T) {
	source_text := read(t, SOURCE_PATH)
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

	snapshot: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&snapshot, &source, {max_quads = 14}), sparql_adapter.Error_Code.None)
	defer sparql_adapter.destroy(&snapshot)
	live := sparql_adapter.indexed_view(&source)
	immutable := sparql_adapter.view(&snapshot)

	select_text := read(t, QUERY_ROOT + "select-agent.rq")
	defer delete(select_text)
	live_select := execute(t, string(select_text), live)
	defer engine.destroy(&live_select)
	immutable_select := execute(t, string(select_text), immutable)
	defer engine.destroy(&immutable_select)
	testing.expect_value(t, engine.Row_Count(&live_select), engine.Row_Count(&immutable_select))
	for index in 0..<engine.Row_Count(&live_select) {
		live_term, live_bound, live_valid := engine.Cell(&live_select, index, 0)
		immutable_term, immutable_bound, immutable_valid := engine.Cell(&immutable_select, index, 0)
		testing.expect(t, live_valid && live_bound && immutable_valid && immutable_bound)
		testing.expect(t, same_term(live_term, immutable_term))
	}

	ask_text := read(t, QUERY_ROOT + "ask-bea-person.rq")
	defer delete(ask_text)
	live_ask_result := execute(t, string(ask_text), live)
	defer engine.destroy(&live_ask_result)
	immutable_ask_result := execute(t, string(ask_text), immutable)
	defer engine.destroy(&immutable_ask_result)
	live_ask, live_ask_valid := engine.Ask_Value(&live_ask_result)
	immutable_ask, immutable_ask_valid := engine.Ask_Value(&immutable_ask_result)
	testing.expect(t, live_ask_valid && immutable_ask_valid)
	testing.expect_value(t, live_ask, immutable_ask)

	construct_text := read(t, QUERY_ROOT + "construct-related.rq")
	defer delete(construct_text)
	live_construct := execute(t, string(construct_text), live)
	defer engine.destroy(&live_construct)
	immutable_construct := execute(t, string(construct_text), immutable)
	defer engine.destroy(&immutable_construct)
	testing.expect_value(t, engine.Triple_Count(&live_construct), engine.Triple_Count(&immutable_construct))
}
