package rdfs_sparql

import "core:testing"
import rdf "odin-rdf:rdf"
import dataset "odin-sparql:sparql/dataset"

@(private) Candidate_Contract_Scan_State :: struct { count: int }

@(private) count_candidate_contract_quad :: proc(_: rdf.Quad, user_data: rawptr) -> bool {
	(cast(^Candidate_Contract_Scan_State)user_data).count += 1
	return true
}

@(test)
test_candidate_graph_contract_admission_and_freeze_boundaries :: proc(t: ^testing.T) {
	memory: dataset.Memory_Dataset
	testing.expect_value(t, dataset.init_with_options(&memory, {Max_Quads = 2}), dataset.Error_Code.None)
	defer dataset.destroy(&memory)

	predicate := rdf.iri("https://example.org/garden/contract/value")
	first := rdf.default_graph_quad(rdf.Triple{rdf.iri("https://example.org/garden/contract/a"), predicate, rdf.iri("https://example.org/garden/contract/one")})
	second := rdf.named_graph_quad(rdf.Triple{rdf.iri("https://example.org/garden/contract/a"), predicate, rdf.iri("https://example.org/garden/contract/two")}, rdf.iri("https://example.org/garden/contract/source"))
	third := rdf.default_graph_quad(rdf.Triple{rdf.iri("https://example.org/garden/contract/b"), predicate, rdf.iri("https://example.org/garden/contract/three")})
	invalid := rdf.named_graph_quad(rdf.Triple{rdf.iri("https://example.org/garden/contract/c"), predicate, rdf.iri("https://example.org/garden/contract/four")}, rdf.literal("not-a-graph-name"))

	testing.expect_value(t, dataset.add(&memory, first), dataset.Error_Code.None)
	testing.expect_value(t, dataset.add(&memory, second), dataset.Error_Code.None)
	testing.expect_value(t, dataset.quad_count(&memory), 2)
	testing.expect_value(t, dataset.add(&memory, first), dataset.Error_Code.None)
	testing.expect_value(t, dataset.quad_count(&memory), 2)
	testing.expect_value(t, dataset.add(&memory, third), dataset.Error_Code.Quad_Limit)
	testing.expect_value(t, dataset.quad_count(&memory), 2)
	testing.expect_value(t, dataset.add(&memory, invalid), dataset.Error_Code.Invalid_Quad)
	testing.expect_value(t, dataset.quad_count(&memory), 2)

	dataset.seal(&memory)
	testing.expect_value(t, dataset.add(&memory, third), dataset.Error_Code.Sealed)
	view, view_error := dataset.view(&memory)
	testing.expect_value(t, view_error, dataset.Error_Code.None)
	default_matches: Candidate_Contract_Scan_State
	testing.expect_value(t, dataset.scan(view, {}, count_candidate_contract_quad, &default_matches), dataset.Error_Code.None)
	testing.expect_value(t, default_matches.count, 1)
	named_matches: Candidate_Contract_Scan_State
	testing.expect_value(t, dataset.scan(view, {Graph_Mode = .Any_Named}, count_candidate_contract_quad, &named_matches), dataset.Error_Code.None)
	testing.expect_value(t, named_matches.count, 1)

	lexical_limited: dataset.Memory_Dataset
	testing.expect_value(t, dataset.init_with_options(&lexical_limited, {Max_Lexical_Bytes = 1}), dataset.Error_Code.None)
	defer dataset.destroy(&lexical_limited)
	testing.expect_value(t, dataset.add(&lexical_limited, first), dataset.Error_Code.Lexical_Limit)
	testing.expect_value(t, dataset.quad_count(&lexical_limited), 0)
}
