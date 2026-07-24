package rdfs_sparql

import "core:testing"
import rdf "odin-rdf:rdf"
import turtle "odin-rdf:rdf/turtle"
import sparql_adapter "../../../odin-reasoner/adapter/sparql"
import importer "../../../odin-reasoner/reasoner/import"
import store "../../../odin-reasoner/reasoner/store"
import engine "odin-sparql:sparql/engine"

BLANK_NODE_SOURCE_PATH :: "fixtures/rdfs-core/blank-node-boundary/source.ttl"
BLANK_NODE_QUERY_ROOT  :: "queries/rdfs-core/blank-node-boundary/"

@(test)
test_blank_node_scope_and_duplicate_set_semantics_survive_snapshot :: proc(t: ^testing.T) {
	source_text := read(t, BLANK_NODE_SOURCE_PATH)
	defer delete(source_text)

	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	state: importer.Sink_State
	importer.init(&state, &source)
	parsed := turtle.parse(string(source_text), importer.triple_sink, {}, &state)
	testing.expect_value(t, parsed.code, turtle.Error_Code.None)
	testing.expect_value(t, state.last_error, store.Error_Code.None)
	testing.expect_value(t, state.inserted, 1)
	testing.expect_value(t, state.duplicates, 1)
	testing.expect_value(t, store.fact_count(&source), 1)

	snapshot: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&snapshot, &source, {max_quads = 1}), sparql_adapter.Error_Code.None)
	testing.expect_value(t, sparql_adapter.quad_count(&snapshot), 1)
	store.destroy(&source)
	defer sparql_adapter.destroy(&snapshot)
	view := sparql_adapter.view(&snapshot)

	select_text := read(t, BLANK_NODE_QUERY_ROOT + "select-subject.rq")
	defer delete(select_text)
	select_result := execute(t, string(select_text), view)
	defer engine.destroy(&select_result)
	testing.expect_value(t, engine.Row_Count(&select_result), 1)
	subject, bound, valid := engine.Cell(&select_result, 0, 0)
	testing.expect(t, valid && bound)
	testing.expect_value(t, subject.kind, rdf.Term_Kind.Blank_Node)
	testing.expect_value(t, subject.value, "same")
	testing.expect(t, subject.scope != 0)

	ask_text := read(t, BLANK_NODE_QUERY_ROOT + "ask-knows.rq")
	defer delete(ask_text)
	ask_result := execute(t, string(ask_text), view)
	defer engine.destroy(&ask_result)
	ask, valid_ask := engine.Ask_Value(&ask_result)
	testing.expect(t, valid_ask && ask)
}
