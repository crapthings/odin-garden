// Release-qualified core SPARQL boundary: owned Memory_Dataset and an
// application-owned custom_view both work with RDF alone, not odin-graph.
package sparql_core

import "core:strings"
import "core:testing"
import rdf "odin-rdf:rdf"
import sparql "odin-sparql:sparql"
import dataset "odin-sparql:sparql/dataset"
import engine "odin-sparql:sparql/engine"

@(private) Source :: struct {
	quads: []rdf.Quad,
	scans: int,
	stops: int,
}

@(private) same_term :: proc(left, right: rdf.Term) -> bool {
	return left.kind == right.kind && left.value == right.value &&
		strings.equal_fold(left.language, right.language) &&
		left.datatype == right.datatype && left.scope == right.scope
}

@(private) matches :: proc(pattern: dataset.Quad_Pattern, quad: rdf.Quad) -> bool {
	#partial switch pattern.Graph_Mode {
	case .Default:
		if quad.has_graph do return false
	case .Named:
		if !quad.has_graph || !same_term(pattern.Graph, quad.graph) do return false
	case .Any_Named:
		if !quad.has_graph do return false
	}
	return (!pattern.Has_Subject || same_term(pattern.Subject, quad.subject)) &&
		(!pattern.Has_Predicate || same_term(pattern.Predicate, quad.predicate)) &&
		(!pattern.Has_Object || same_term(pattern.Object, quad.object))
}

@(private) scan :: proc(data: rawptr, pattern: dataset.Quad_Pattern, sink: dataset.Scan_Sink, sink_data: rawptr) -> dataset.Error_Code {
	source := cast(^Source)data
	source.scans += 1
	for quad in source.quads {
		if matches(pattern, quad) && !sink(quad, sink_data) {
			source.stops += 1
			break
		}
	}
	return .None
}

@(private) execute :: proc(t: ^testing.T, text: string, view: dataset.View) -> engine.Result {
	query, parse_error := sparql.Parse(text)
	defer sparql.Destroy(&query)
	testing.expect_value(t, sparql.Parse_Error_Code(parse_error), sparql.Error_Code.None)
	result, execute_error := engine.execute(&query, view, {Max_Solutions = 8})
	testing.expect_value(t, execute_error, engine.Error_Code.None)
	return result
}

@(test)
test_memory_dataset_is_a_released_rdf_only_default_and_named_graph_boundary :: proc(t: ^testing.T) {
	store: dataset.Memory_Dataset
	dataset.init(&store)
	defer dataset.destroy(&store)

	predicate := rdf.iri("urn:garden:knows")
	testing.expect_value(t, dataset.add(&store, rdf.default_graph_quad(rdf.Triple{
		subject = rdf.iri("urn:garden:ada"), predicate = predicate, object = rdf.iri("urn:garden:bert"),
	})), dataset.Error_Code.None)
	testing.expect_value(t, dataset.add(&store, rdf.named_graph_quad(rdf.Triple{
		subject = rdf.iri("urn:garden:ada"), predicate = predicate, object = rdf.iri("urn:garden:cora"),
	}, rdf.iri("urn:garden:people"))), dataset.Error_Code.None)
	dataset.seal(&store)
	view, view_error := dataset.view(&store)
	testing.expect_value(t, view_error, dataset.Error_Code.None)

	default_result := execute(t, `SELECT ?friend WHERE { <urn:garden:ada> <urn:garden:knows> ?friend }`, view)
	defer engine.destroy(&default_result)
	testing.expect_value(t, engine.Row_Count(&default_result), 1)
	friend, bound, valid := engine.Cell(&default_result, 0, 0)
	testing.expect(t, valid && bound)
	testing.expect_value(t, friend.value, "urn:garden:bert")

	named_result := execute(t, `SELECT ?friend WHERE { GRAPH <urn:garden:people> { <urn:garden:ada> <urn:garden:knows> ?friend } }`, view)
	defer engine.destroy(&named_result)
	testing.expect_value(t, engine.Row_Count(&named_result), 1)
	named_friend, named_bound, named_valid := engine.Cell(&named_result, 0, 0)
	testing.expect(t, named_valid && named_bound)
	testing.expect_value(t, named_friend.value, "urn:garden:cora")
}

@(test)
test_custom_view_remains_an_application_owned_rdf_only_query_boundary :: proc(t: ^testing.T) {
	source := Source{quads = []rdf.Quad{
		rdf.default_graph_quad(rdf.Triple{subject = rdf.iri("urn:garden:ada"), predicate = rdf.iri("urn:garden:knows"), object = rdf.iri("urn:garden:bert")}),
		rdf.default_graph_quad(rdf.Triple{subject = rdf.iri("urn:garden:ada"), predicate = rdf.iri("urn:garden:knows"), object = rdf.iri("urn:garden:cora")}),
	}}
	view := dataset.custom_view(scan, &source)
	result := execute(t, `ASK { <urn:garden:ada> <urn:garden:knows> ?friend }`, view)
	defer engine.destroy(&result)
	answer, valid := engine.Ask_Value(&result)
	testing.expect(t, valid && answer)
	testing.expect_value(t, source.scans, 1)
	testing.expect_value(t, source.stops, 1)
}
