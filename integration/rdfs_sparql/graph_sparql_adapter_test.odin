package rdfs_sparql

import "core:testing"
import rdf "odin-rdf:rdf"
import trig "odin-rdf:rdf/trig"
import engine "odin-sparql:sparql/engine"
import graph "../../../odin-graph/graph"
import graph_sparql "../../../odin-graph/adapter/sparql"

@(private) Graph_Ingest_State :: struct {
	target: ^graph.Graph,
	error:  graph.Error,
}

@(private) graph_sink :: proc(quad: rdf.Quad, user_data: rawptr) -> bool {
	state := cast(^Graph_Ingest_State)user_data
	state.error = graph.add(state.target, quad)
	return state.error == .None
}

@(test)
test_graph_kernel_adapter_matches_named_graph_source_isolation_fixture :: proc(t: ^testing.T) {
	source_text := read(t, NAMED_GRAPH_SOURCE_PATH)
	defer delete(source_text)

	source: graph.Graph
	testing.expect_value(t, graph.init(&source), graph.Error.None)
	defer graph.destroy(&source)
	state := Graph_Ingest_State{target = &source}
	parsed := trig.parse(string(source_text), graph_sink, {}, &state)
	testing.expect_value(t, parsed.code, trig.Error_Code.None)
	testing.expect_value(t, state.error, graph.Error.None)
	testing.expect_value(t, graph.quad_count(&source), 6)
	testing.expect_value(t, graph.freeze(&source), graph.Error.None)
	adapter: graph_sparql.View
	testing.expect_value(t, graph_sparql.init(&adapter, &source), graph.Error.None)
	view := graph_sparql.dataset_view(&adapter)

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
