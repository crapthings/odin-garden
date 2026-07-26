// Garden's candidate SHACL release gate: public Turtle parsing -> bounded
// Core validation -> destroy input ownership -> inspect owned stable report.
package shacl_integration

import "core:os"
import "core:strings"
import "core:testing"
import rdf "odin-rdf:rdf"
import turtle "odin-rdf:rdf/turtle"
import validator "odin-shacl:shacl"

DATA_PATH   :: "fixtures/shacl-core/person-record/data.ttl"
SHAPES_PATH :: "fixtures/shacl-core/person-record/shapes.ttl"
EX          :: "https://example.org/garden/shacl/"

@(private) Owned_Triples :: struct {
	triples: [dynamic]rdf.Triple,
	owned:   [dynamic]string,
	error:   bool,
}

@(private) init_owned :: proc(target: ^Owned_Triples) {
	target^ = Owned_Triples{triples = make([dynamic]rdf.Triple), owned = make([dynamic]string)}
}

@(private) destroy_owned :: proc(target: ^Owned_Triples) {
	for value in target.owned do delete(value)
	delete(target.owned)
	delete(target.triples)
	target^ = {}
}

@(private) copy_string :: proc(target: ^Owned_Triples, value: string) -> (string, bool) {
	if len(value) == 0 do return "", true
	copy, copy_error := strings.clone(value)
	if copy_error != nil do return "", false
	if _, append_error := append(&target.owned, copy); append_error != nil {
		delete(copy)
		return "", false
	}
	return copy, true
}

@(private) copy_term :: proc(target: ^Owned_Triples, source: rdf.Term) -> (rdf.Term, bool) {
	result := source
	valid: bool
	result.value, valid = copy_string(target, source.value)
	if !valid do return {}, false
	result.language, valid = copy_string(target, source.language)
	if !valid do return {}, false
	result.datatype, valid = copy_string(target, source.datatype)
	if !valid do return {}, false
	return result, true
}

@(private) triple_sink :: proc(source: rdf.Triple, user_data: rawptr) -> bool {
	target := cast(^Owned_Triples)user_data
	triple: rdf.Triple
	valid: bool
	triple.subject, valid = copy_term(target, source.subject)
	if !valid { target.error = true; return false }
	triple.predicate, valid = copy_term(target, source.predicate)
	if !valid { target.error = true; return false }
	triple.object, valid = copy_term(target, source.object)
	if !valid { target.error = true; return false }
	if _, append_error := append(&target.triples, triple); append_error != nil { target.error = true; return false }
	return true
}

@(private) read :: proc(t: ^testing.T, path: string) -> []u8 {
	data, read_error := os.read_entire_file(path, context.allocator)
	testing.expect(t, read_error == nil)
	return data
}

@(private) parse_fixture :: proc(t: ^testing.T, path: string, target: ^Owned_Triples) {
	init_owned(target)
	text := read(t, path)
	defer delete(text)
	parsed := turtle.parse(string(text), triple_sink, {}, target)
	testing.expect_value(t, parsed.code, turtle.Error_Code.None)
	testing.expect(t, !target.error)
}

@(private) iri :: proc(local: string) -> rdf.Term {
	// Every caller supplies a compile-time string here; the helper avoids
	// storing any temporary generated IRI in the report assertion path.
	switch local {
	case "ada":             return rdf.iri(EX + "ada")
	case "bea":             return rdf.iri(EX + "bea")
	case "cora":            return rdf.iri(EX + "cora")
	case "email":           return rdf.iri(EX + "email")
	case "employeeId":      return rdf.iri(EX + "employeeId")
	case "EmailShape":      return rdf.iri(EX + "EmailShape")
	case "EmployeeIdShape": return rdf.iri(EX + "EmployeeIdShape")
	}
	return {}
}

@(private) same_term :: proc(left, right: rdf.Term) -> bool {
	return left.kind == right.kind && left.value == right.value && left.language == right.language && left.datatype == right.datatype && left.scope == right.scope
}

@(test)
test_person_record_fixture_is_a_stable_owned_validation_report :: proc(t: ^testing.T) {
	data, shapes: Owned_Triples
	parse_fixture(t, DATA_PATH, &data)
	parse_fixture(t, SHAPES_PATH, &shapes)
	testing.expect_value(t, len(data.triples), 10)
	testing.expect_value(t, len(shapes.triples), 13)

	report: validator.Report
	defer validator.destroy(&report)
	testing.expect_value(t, validator.validate(data.triples[:], shapes.triples[:], &report, {max_data_triples = 32, max_shape_triples = 32, max_results = 8}), validator.Error_Code.None)
	// The report must own its values. Destroy both parser-derived graphs before
	// inspecting any reported term, rather than merely relying on scope exit.
	destroy_owned(&data)
	destroy_owned(&shapes)
	testing.expect(t, !report.conforms)
	testing.expect_value(t, len(report.results), 4)

	first := report.results[0]
	testing.expect(t, same_term(first.focus_node, iri("bea")))
	testing.expect(t, same_term(first.result_path, iri("email")))
	testing.expect(t, first.has_value && first.value.kind == .Literal && first.value.value == "not-an-iri")
	testing.expect(t, same_term(first.source_shape, iri("EmailShape")))
	testing.expect_value(t, first.source_constraint_component, validator.Constraint_Component.Node_Kind)

	second := report.results[1]
	testing.expect(t, same_term(second.focus_node, iri("bea")))
	testing.expect(t, same_term(second.result_path, iri("employeeId")))
	testing.expect(t, second.has_value && second.value.kind == .Literal && second.value.value == "ID-2")
	testing.expect(t, same_term(second.source_shape, iri("EmployeeIdShape")))
	testing.expect_value(t, second.source_constraint_component, validator.Constraint_Component.Datatype)

	third := report.results[2]
	testing.expect(t, same_term(third.focus_node, iri("cora")))
	testing.expect(t, same_term(third.result_path, iri("email")))
	testing.expect(t, !third.has_value)
	testing.expect_value(t, third.source_constraint_component, validator.Constraint_Component.Min_Count)

	fourth := report.results[3]
	testing.expect(t, same_term(fourth.focus_node, iri("cora")))
	testing.expect(t, same_term(fourth.result_path, iri("employeeId")))
	testing.expect(t, !fourth.has_value)
	testing.expect_value(t, fourth.source_constraint_component, validator.Constraint_Component.Max_Count)
}

@(test)
test_unsupported_shape_is_rejected_instead_of_returning_conforms :: proc(t: ^testing.T) {
	shape := rdf.iri(EX + "UnsupportedShape")
	pattern := rdf.iri("http://www.w3.org/ns/shacl#pattern")
	shapes := [2]rdf.Triple{
		{shape, rdf.iri("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), rdf.iri("http://www.w3.org/ns/shacl#NodeShape")},
		{shape, pattern, rdf.literal("[0-9]+")},
	}
	report: validator.Report
	defer validator.destroy(&report)
	testing.expect_value(t, validator.validate(nil, shapes[:], &report), validator.Error_Code.Unsupported_Shape)
	testing.expect(t, !report.conforms)
	testing.expect_value(t, len(report.results), 0)
}
