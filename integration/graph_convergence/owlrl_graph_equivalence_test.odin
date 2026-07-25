// Development-only OWL RL convergence checks. These depend on current
// Reasoner APIs and deliberately stay out of the pinned release package.
package graph_convergence

import "core:testing"
import rdf "odin-rdf:rdf"
import sparql "odin-sparql:sparql"
import dataset "odin-sparql:sparql/dataset"
import engine "odin-sparql:sparql/engine"
import graph "odin-graph:graph"
import graph_reasoner "../../../odin-graph/adapter/reasoner"
import graph_sparql "../../../odin-graph/adapter/sparql"
import sparql_adapter "../../../odin-reasoner/adapter/sparql"
import importer "../../../odin-reasoner/reasoner/import"
import owlrl "../../../odin-reasoner/reasoner/owlrl"
import store "../../../odin-reasoner/reasoner/store"

@(private) W3C_Import_Resolver :: struct {
	iri:      string,
	document: string,
}

@(private) resolve_w3c_import :: proc(iri: string, user_data: rawptr) -> (string, bool) {
	state := cast(^W3C_Import_Resolver)user_data
	if state == nil || iri != state.iri do return "", false
	return state.document, true
}

@(private) execute :: proc(t: ^testing.T, text: string, view: dataset.View) -> engine.Result {
	query, parse_error := sparql.Parse(text)
	defer sparql.Destroy(&query)
	testing.expect_value(t, sparql.Parse_Error_Code(parse_error), sparql.Error_Code.None)
	result, execute_error := engine.execute(&query, view, {Max_Solutions = 16})
	testing.expect_value(t, execute_error, engine.Error_Code.None)
	return result
}

@(private) same_term :: proc(left, right: rdf.Term) -> bool {
	return left.kind == right.kind && left.value == right.value && left.language == right.language && left.datatype == right.datatype && left.scope == right.scope
}

@(test)
test_owlrl_closure_graph_adapter_preserves_sparql_inverse_property_entailment :: proc(t: ^testing.T) {
	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	profile: owlrl.Profile
	profile_error, store_error := owlrl.init(&profile, &source)
	testing.expect_value(t, profile_error, owlrl.Error_Code.None)
	testing.expect_value(t, store_error, store.Error_Code.None)
	_, inverse_error := store.insert_triple(&source, {rdf.iri("urn:parentOf"), rdf.iri(owlrl.OWL_INVERSE_OF), rdf.iri("urn:childOf")})
	testing.expect_value(t, inverse_error, store.Error_Code.None)
	_, assertion_error := store.insert_triple(&source, {rdf.iri("urn:ada"), rdf.iri("urn:parentOf"), rdf.iri("urn:bert")})
	testing.expect_value(t, assertion_error, store.Error_Code.None)
	materialized := owlrl.materialize_all(&profile, &source)
	testing.expect_value(t, materialized.error, owlrl.Materialize_All_Error_Code.None)

	legacy: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&legacy, &source), sparql_adapter.Error_Code.None)
	defer sparql_adapter.destroy(&legacy)
	candidate: graph.Graph
	testing.expect_value(t, graph_reasoner.init(&candidate, &source), graph_reasoner.Error.None)
	defer graph.destroy(&candidate)
	owlrl.destroy(&profile)
	store.destroy(&source)

	graph_adapter: graph_sparql.View
	testing.expect_value(t, graph_sparql.init(&graph_adapter, &candidate), graph.Error.None)
	query := `SELECT ?child WHERE { ?child <urn:childOf> <urn:ada> }`
	legacy_result := execute(t, query, sparql_adapter.view(&legacy))
	defer engine.destroy(&legacy_result)
	graph_result := execute(t, query, graph_sparql.dataset_view(&graph_adapter))
	defer engine.destroy(&graph_result)
	testing.expect_value(t, engine.Row_Count(&legacy_result), 1)
	testing.expect_value(t, engine.Row_Count(&graph_result), 1)
	legacy_child, legacy_bound, legacy_valid := engine.Cell(&legacy_result, 0, 0)
	graph_child, graph_bound, graph_valid := engine.Cell(&graph_result, 0, 0)
	testing.expect(t, legacy_valid && legacy_bound && graph_valid && graph_bound)
	testing.expect_value(t, legacy_child.value, "urn:bert")
	testing.expect(t, same_term(legacy_child, graph_child))
}

@(test)
test_owlrl_closure_graph_adapter_preserves_blank_node_scope_in_sparql_joins :: proc(t: ^testing.T) {
	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	profile: owlrl.Profile
	profile_error, store_error := owlrl.init(&profile, &source)
	testing.expect_value(t, profile_error, owlrl.Error_Code.None)
	testing.expect_value(t, store_error, store.Error_Code.None)

	first_scope := rdf.new_blank_node_scope()
	second_scope := rdf.new_blank_node_scope()
	first_parent := rdf.blank_node("parent", first_scope)
	first_child := rdf.blank_node("child", first_scope)
	second_parent := rdf.blank_node("parent", second_scope)
	second_child := rdf.blank_node("child", second_scope)
	triples := [7]rdf.Triple{
		{rdf.iri("urn:parentOf"), rdf.iri(owlrl.OWL_INVERSE_OF), rdf.iri("urn:childOf")},
		{first_parent, rdf.iri("urn:parentOf"), first_child},
		{first_parent, rdf.iri("urn:name"), rdf.iri("urn:ada")},
		{first_child, rdf.iri("urn:marker"), rdf.iri("urn:good")},
		{second_parent, rdf.iri("urn:parentOf"), second_child},
		{second_parent, rdf.iri("urn:name"), rdf.iri("urn:bert")},
		{second_child, rdf.iri("urn:marker"), rdf.iri("urn:other")},
	}
	for triple in triples {
		_, insert_error := store.insert_triple(&source, triple)
		testing.expect_value(t, insert_error, store.Error_Code.None)
	}
	materialized := owlrl.materialize_all(&profile, &source)
	testing.expect_value(t, materialized.error, owlrl.Materialize_All_Error_Code.None)

	legacy: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&legacy, &source), sparql_adapter.Error_Code.None)
	defer sparql_adapter.destroy(&legacy)
	memory: dataset.Memory_Dataset
	dataset.init(&memory)
	defer dataset.destroy(&memory)
	for index in 0..<store.fact_count(&source) {
		id, _, _, found := store.fact_at(&source, index)
		testing.expect(t, found)
		triple, valid := store.triple_for(&source, id)
		testing.expect(t, valid)
		if valid do testing.expect_value(t, dataset.add(&memory, rdf.default_graph_quad(triple)), dataset.Error_Code.None)
	}
	dataset.seal(&memory)
	memory_view, memory_error := dataset.view(&memory)
	testing.expect_value(t, memory_error, dataset.Error_Code.None)
	candidate: graph.Graph
	testing.expect_value(t, graph_reasoner.init(&candidate, &source), graph_reasoner.Error.None)
	defer graph.destroy(&candidate)
	owlrl.destroy(&profile)
	store.destroy(&source)
	graph_adapter: graph_sparql.View
	testing.expect_value(t, graph_sparql.init(&graph_adapter, &candidate), graph.Error.None)

	// The blank-node labels intentionally collide across scopes. If any copied
	// path discarded scope, the `good` child could join with `bert`.
	query := `SELECT ?name WHERE {
		?child <urn:childOf> ?parent .
		?child <urn:marker> <urn:good> .
		?parent <urn:name> ?name
	}`
	legacy_result := execute(t, query, sparql_adapter.view(&legacy))
	defer engine.destroy(&legacy_result)
	memory_result := execute(t, query, memory_view)
	defer engine.destroy(&memory_result)
	graph_result := execute(t, query, graph_sparql.dataset_view(&graph_adapter))
	defer engine.destroy(&graph_result)
	testing.expect_value(t, engine.Row_Count(&legacy_result), 1)
	testing.expect_value(t, engine.Row_Count(&memory_result), 1)
	testing.expect_value(t, engine.Row_Count(&graph_result), 1)
	legacy_name, legacy_bound, legacy_valid := engine.Cell(&legacy_result, 0, 0)
	memory_name, memory_bound, memory_valid := engine.Cell(&memory_result, 0, 0)
	graph_name, graph_bound, graph_valid := engine.Cell(&graph_result, 0, 0)
	testing.expect(t, legacy_valid && legacy_bound && memory_valid && memory_bound && graph_valid && graph_bound)
	testing.expect_value(t, legacy_name.value, "urn:ada")
	testing.expect(t, same_term(legacy_name, memory_name))
	testing.expect(t, same_term(legacy_name, graph_name))
}

@(test)
test_w3c_import_closure_graph_adapter_matches_snapshot_sparql_entailment :: proc(t: ^testing.T) {
	root_document := `<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:ont="http://www.w3.org/2002/03owlt/imports/support011-A#" xml:base="http://www.w3.org/2002/03owlt/imports/premises011"><owl:Ontology rdf:about=""><owl:imports rdf:resource="http://www.w3.org/2002/03owlt/imports/support011-A"/></owl:Ontology><ont:Man rdf:about="http://example.org/data#Socrates"/></rdf:RDF>`
	imported_document := `<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:owl="http://www.w3.org/2002/07/owl#" xml:base="http://www.w3.org/2002/03owlt/imports/support011-A"><owl:Ontology rdf:about=""/><owl:Class rdf:ID="Man"><rdfs:subClassOf rdf:resource="#Mortal"/></owl:Class><owl:Class rdf:ID="Mortal"/></rdf:RDF>`
	resolver := W3C_Import_Resolver{iri = "http://www.w3.org/2002/03owlt/imports/support011-A", document = imported_document}
	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	loaded := importer.load_rdfxml_import_closure(root_document, &source, resolve_w3c_import, {root_iri = "http://www.w3.org/2002/03owlt/imports/premises011"}, &resolver)
	testing.expect_value(t, loaded.error, importer.Import_Error_Code.None)
	testing.expect_value(t, loaded.documents, 2)
	profile: owlrl.Profile
	profile_error, store_error := owlrl.init(&profile, &source)
	testing.expect_value(t, profile_error, owlrl.Error_Code.None)
	testing.expect_value(t, store_error, store.Error_Code.None)
	materialized := owlrl.materialize_all(&profile, &source)
	testing.expect_value(t, materialized.error, owlrl.Materialize_All_Error_Code.None)

	legacy: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&legacy, &source), sparql_adapter.Error_Code.None)
	defer sparql_adapter.destroy(&legacy)
	candidate: graph.Graph
	testing.expect_value(t, graph_reasoner.init(&candidate, &source), graph_reasoner.Error.None)
	defer graph.destroy(&candidate)
	owlrl.destroy(&profile)
	store.destroy(&source)
	graph_adapter: graph_sparql.View
	testing.expect_value(t, graph_sparql.init(&graph_adapter, &candidate), graph.Error.None)
	query := `ASK { <http://example.org/data#Socrates> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/03owlt/imports/support011-A#Mortal> }`
	legacy_result := execute(t, query, sparql_adapter.view(&legacy))
	defer engine.destroy(&legacy_result)
	graph_result := execute(t, query, graph_sparql.dataset_view(&graph_adapter))
	defer engine.destroy(&graph_result)
	legacy_answer, legacy_valid := engine.Ask_Value(&legacy_result)
	graph_answer, graph_valid := engine.Ask_Value(&graph_result)
	testing.expect(t, legacy_valid && graph_valid)
	testing.expect(t, legacy_answer && graph_answer)
	testing.expect_value(t, graph_answer, legacy_answer)
}
