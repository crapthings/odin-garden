package rdfs_sparql

import "core:testing"
import rdf "odin-rdf:rdf"
import dataset "odin-sparql:sparql/dataset"

@(private) Memory_Dataset_Scan_State :: struct { count: int }

@(private) count_memory_dataset_quad :: proc(_: rdf.Quad, user_data: rawptr) -> bool {
	(cast(^Memory_Dataset_Scan_State)user_data).count += 1
	return true
}

@(test)
test_released_memory_dataset_preserves_identity_and_graph_scans :: proc(t: ^testing.T) {
	memory: dataset.Memory_Dataset
	dataset.init(&memory)
	defer dataset.destroy(&memory)

	first_scope := rdf.new_blank_node_scope()
	second_scope := rdf.new_blank_node_scope()
	predicate := rdf.iri("urn:garden:label")
	first := rdf.default_graph_quad(rdf.Triple{
		subject = rdf.blank_node("same", first_scope),
		predicate = predicate,
		object = rdf.language_literal("value", "EN"),
	})
	same_identity := rdf.default_graph_quad(rdf.Triple{
		subject = rdf.blank_node("same", first_scope),
		predicate = predicate,
		object = rdf.language_literal("value", "en"),
	})
	second := rdf.default_graph_quad(rdf.Triple{
		subject = rdf.blank_node("same", second_scope),
		predicate = predicate,
		object = rdf.language_literal("value", "en"),
	})
	named := rdf.named_graph_quad(rdf.Triple{
		subject = rdf.iri("urn:garden:named"),
		predicate = predicate,
		object = rdf.iri("urn:garden:value"),
	}, rdf.iri("urn:garden:graph"))
	testing.expect_value(t, dataset.add(&memory, first), dataset.Error_Code.None)
	testing.expect_value(t, dataset.add(&memory, same_identity), dataset.Error_Code.None)
	testing.expect_value(t, dataset.add(&memory, second), dataset.Error_Code.None)
	testing.expect_value(t, dataset.add(&memory, named), dataset.Error_Code.None)
	testing.expect_value(t, dataset.quad_count(&memory), 3)

	dataset.seal(&memory)
	view, view_error := dataset.view(&memory)
	testing.expect_value(t, view_error, dataset.Error_Code.None)
	first_matches: Memory_Dataset_Scan_State
	first_pattern := dataset.Quad_Pattern{Has_Subject = true, Subject = rdf.blank_node("same", first_scope)}
	testing.expect_value(t, dataset.scan(view, first_pattern, count_memory_dataset_quad, &first_matches), dataset.Error_Code.None)
	testing.expect_value(t, first_matches.count, 1)
	second_matches: Memory_Dataset_Scan_State
	second_pattern := dataset.Quad_Pattern{Has_Subject = true, Subject = rdf.blank_node("same", second_scope)}
	testing.expect_value(t, dataset.scan(view, second_pattern, count_memory_dataset_quad, &second_matches), dataset.Error_Code.None)
	testing.expect_value(t, second_matches.count, 1)
	named_matches: Memory_Dataset_Scan_State
	named_pattern := dataset.Quad_Pattern{Graph_Mode = .Named, Graph = rdf.iri("urn:garden:graph")}
	testing.expect_value(t, dataset.scan(view, named_pattern, count_memory_dataset_quad, &named_matches), dataset.Error_Code.None)
	testing.expect_value(t, named_matches.count, 1)
	any_named_matches: Memory_Dataset_Scan_State
	testing.expect_value(t, dataset.scan(view, {Graph_Mode = .Any_Named}, count_memory_dataset_quad, &any_named_matches), dataset.Error_Code.None)
	testing.expect_value(t, any_named_matches.count, 1)
}
