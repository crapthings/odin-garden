package rdfs_sparql

import "core:testing"
import rdf "odin-rdf:rdf"
import trig "odin-rdf:rdf/trig"
import dataset "odin-sparql:sparql/dataset"
import engine "odin-sparql:sparql/engine"

NAMED_GRAPH_SOURCE_PATH :: "fixtures/rdfs-core/named-graph-source-isolation/source.trig"
NAMED_GRAPH_QUERY_ROOT :: "queries/rdfs-core/named-graph-source-isolation/"

@(test)
test_memory_dataset_keeps_multi_source_named_graphs_isolated :: proc(t: ^testing.T) {
	source_text := read(t, NAMED_GRAPH_SOURCE_PATH)
	defer delete(source_text)

	memory: dataset.Memory_Dataset
	dataset.init(&memory)
	defer dataset.destroy(&memory)
	parsed := trig.parse(string(source_text), dataset.sink, {}, &memory)
	testing.expect_value(t, parsed.code, trig.Error_Code.None)
	testing.expect_value(t, dataset.quad_count(&memory), 6)
	dataset.seal(&memory)
	view, view_error := dataset.view(&memory)
	testing.expect_value(t, view_error, dataset.Error_Code.None)

	exact_text := read(t, NAMED_GRAPH_QUERY_ROOT + "exact-source-a.rq")
	defer delete(exact_text)
	exact_result := execute(t, string(exact_text), view)
	defer engine.destroy(&exact_result)
	testing.expect_value(t, engine.Row_Count(&exact_result), 1)
	exact_friend, exact_bound, exact_valid := engine.Cell(&exact_result, 0, 0)
	testing.expect(t, exact_valid && exact_bound)
	testing.expect_value(t, exact_friend.value, "https://example.org/garden/graph-fixture/bea")

	all_text := read(t, NAMED_GRAPH_QUERY_ROOT + "all-sources.rq")
	defer delete(all_text)
	all_result := execute(t, string(all_text), view)
	defer engine.destroy(&all_result)
	testing.expect_value(t, engine.Row_Count(&all_result), 2)
	first_source, first_source_bound, first_source_valid := engine.Cell(&all_result, 0, 0)
	first_friend, first_friend_bound, first_friend_valid := engine.Cell(&all_result, 0, 1)
	testing.expect(t, first_source_valid && first_source_bound && first_friend_valid && first_friend_bound)
	testing.expect_value(t, first_source.value, "https://example.org/garden/graph-fixture/source-a")
	testing.expect_value(t, first_friend.value, "https://example.org/garden/graph-fixture/bea")
	second_source, second_source_bound, second_source_valid := engine.Cell(&all_result, 1, 0)
	second_friend, second_friend_bound, second_friend_valid := engine.Cell(&all_result, 1, 1)
	testing.expect(t, second_source_valid && second_source_bound && second_friend_valid && second_friend_bound)
	testing.expect_value(t, second_source.value, "https://example.org/garden/graph-fixture/source-b")
	testing.expect_value(t, second_friend.value, "https://example.org/garden/graph-fixture/cy")

	default_text := read(t, NAMED_GRAPH_QUERY_ROOT + "default-does-not-leak.rq")
	defer delete(default_text)
	default_result := execute(t, string(default_text), view)
	defer engine.destroy(&default_result)
	default_answer, default_valid := engine.Ask_Value(&default_result)
	testing.expect(t, default_valid && !default_answer)

	default_catalog_text := `ASK { <https://example.org/garden/graph-fixture/catalog> <https://example.org/garden/graph-fixture/published> <https://example.org/garden/graph-fixture/source-a> }`
	default_catalog := execute(t, default_catalog_text, view)
	defer engine.destroy(&default_catalog)
	catalog_answer, catalog_valid := engine.Ask_Value(&default_catalog)
	testing.expect(t, catalog_valid && catalog_answer)
}
