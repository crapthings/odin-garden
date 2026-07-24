package rdfs_sparql

import "core:testing"
import trig "odin-rdf:rdf/trig"
import dataset "odin-sparql:sparql/dataset"
import engine "odin-sparql:sparql/engine"
import graph_dataset "odin-sparql:sparql/graph_dataset"

@(test)
test_public_graph_dataset_consumes_named_graph_fixture :: proc(t: ^testing.T) {
	source_text := read(t, NAMED_GRAPH_SOURCE_PATH)
	defer delete(source_text)

	store: graph_dataset.Dataset
	testing.expect_value(t, graph_dataset.init(&store), dataset.Error_Code.None)
	defer graph_dataset.destroy(&store)
	parsed := trig.parse(string(source_text), graph_dataset.sink, {}, &store)
	testing.expect_value(t, parsed.code, trig.Error_Code.None)
	testing.expect_value(t, graph_dataset.quad_count(&store), 6)
	graph_dataset.seal(&store)
	view, view_error := graph_dataset.view(&store)
	testing.expect_value(t, view_error, dataset.Error_Code.None)

	exact_text := read(t, NAMED_GRAPH_QUERY_ROOT + "exact-source-a.rq")
	defer delete(exact_text)
	exact := execute(t, string(exact_text), view)
	defer engine.destroy(&exact)
	testing.expect_value(t, engine.Row_Count(&exact), 1)
	exact_friend, exact_bound, exact_valid := engine.Cell(&exact, 0, 0)
	testing.expect(t, exact_valid && exact_bound)
	testing.expect_value(t, exact_friend.value, "https://example.org/garden/graph-fixture/bea")

	all_text := read(t, NAMED_GRAPH_QUERY_ROOT + "all-sources.rq")
	defer delete(all_text)
	all := execute(t, string(all_text), view)
	defer engine.destroy(&all)
	testing.expect_value(t, engine.Row_Count(&all), 2)
	first_source, first_source_bound, first_source_valid := engine.Cell(&all, 0, 0)
	first_friend, first_friend_bound, first_friend_valid := engine.Cell(&all, 0, 1)
	testing.expect(t, first_source_valid && first_source_bound && first_friend_valid && first_friend_bound)
	testing.expect_value(t, first_source.value, "https://example.org/garden/graph-fixture/source-a")
	testing.expect_value(t, first_friend.value, "https://example.org/garden/graph-fixture/bea")
	second_source, second_source_bound, second_source_valid := engine.Cell(&all, 1, 0)
	second_friend, second_friend_bound, second_friend_valid := engine.Cell(&all, 1, 1)
	testing.expect(t, second_source_valid && second_source_bound && second_friend_valid && second_friend_bound)
	testing.expect_value(t, second_source.value, "https://example.org/garden/graph-fixture/source-b")
	testing.expect_value(t, second_friend.value, "https://example.org/garden/graph-fixture/cy")

	default_text := read(t, NAMED_GRAPH_QUERY_ROOT + "default-does-not-leak.rq")
	defer delete(default_text)
	default_result := execute(t, string(default_text), view)
	defer engine.destroy(&default_result)
	default_answer, default_valid := engine.Ask_Value(&default_result)
	testing.expect(t, default_valid && !default_answer)
}
