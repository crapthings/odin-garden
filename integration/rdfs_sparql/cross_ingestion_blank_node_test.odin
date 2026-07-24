package rdfs_sparql

import "core:testing"
import rdf "odin-rdf:rdf"
import turtle "odin-rdf:rdf/turtle"
import sparql_adapter "../../../odin-reasoner/adapter/sparql"
import importer "../../../odin-reasoner/reasoner/import"
import store "../../../odin-reasoner/reasoner/store"
import engine "odin-sparql:sparql/engine"

CROSS_INGESTION_SOURCE_PATH :: "fixtures/rdfs-core/cross-ingestion-blank-node/source.ttl"
CROSS_INGESTION_QUERY_ROOT  :: "queries/rdfs-core/cross-ingestion-blank-node/"

@(test)
test_identical_blank_node_labels_from_separate_parses_do_not_corefer :: proc(t: ^testing.T) {
	source_text := read(t, CROSS_INGESTION_SOURCE_PATH)
	defer delete(source_text)

	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	state: importer.Sink_State
	importer.init(&state, &source)
	first_parse := turtle.parse(string(source_text), importer.triple_sink, {}, &state)
	second_parse := turtle.parse(string(source_text), importer.triple_sink, {}, &state)
	testing.expect_value(t, first_parse.code, turtle.Error_Code.None)
	testing.expect_value(t, second_parse.code, turtle.Error_Code.None)
	testing.expect_value(t, state.last_error, store.Error_Code.None)
	testing.expect_value(t, state.inserted, 2)
	testing.expect_value(t, state.duplicates, 0)
	testing.expect_value(t, store.fact_count(&source), 2)

	snapshot: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&snapshot, &source), sparql_adapter.Error_Code.None)
	store.destroy(&source)
	defer sparql_adapter.destroy(&snapshot)
	view := sparql_adapter.view(&snapshot)

	select_text := read(t, CROSS_INGESTION_QUERY_ROOT + "select-subject.rq")
	defer delete(select_text)
	select_result := execute(t, string(select_text), view)
	defer engine.destroy(&select_result)
	testing.expect_value(t, engine.Row_Count(&select_result), 2)
	first, first_bound, first_valid := engine.Cell(&select_result, 0, 0)
	second, second_bound, second_valid := engine.Cell(&select_result, 1, 0)
	testing.expect(t, first_valid && first_bound && second_valid && second_bound)
	testing.expect_value(t, first.kind, rdf.Term_Kind.Blank_Node)
	testing.expect_value(t, second.kind, rdf.Term_Kind.Blank_Node)
	testing.expect_value(t, first.value, "same")
	testing.expect_value(t, second.value, "same")
	testing.expect(t, first.scope != 0 && second.scope != 0)
	testing.expect(t, first.scope != second.scope)
}
