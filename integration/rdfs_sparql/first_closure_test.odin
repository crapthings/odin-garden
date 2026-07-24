// Garden's release-gate candidate: public RDF ingestion -> RDFS Core closure
// -> owned immutable SPARQL view -> SELECT, ASK, and CONSTRUCT.
package rdfs_sparql

import "core:os"
import "core:testing"
import rdf "odin-rdf:rdf"
import turtle "odin-rdf:rdf/turtle"
import sparql "odin-sparql:sparql"
import dataset "odin-sparql:sparql/dataset"
import engine "odin-sparql:sparql/engine"
import sparql_adapter "../../../odin-reasoner/adapter/sparql"
import importer "../../../odin-reasoner/reasoner/import"
import rdfs "../../../odin-reasoner/reasoner/rdfs"
import rule "../../../odin-reasoner/reasoner/rule"
import store "../../../odin-reasoner/reasoner/store"

SOURCE_PATH :: "fixtures/rdfs-core/first-closure/source.ttl"
QUERY_ROOT  :: "queries/rdfs-core/first-closure/"

@(private) read :: proc(t: ^testing.T, path: string) -> []u8 {
	data, read_error := os.read_entire_file(path, context.allocator)
	testing.expect(t, read_error == nil)
	return data
}

@(private) execute :: proc(t: ^testing.T, text: string, view: dataset.View) -> engine.Result {
	query, parse_error := sparql.Parse(text)
	defer sparql.Destroy(&query)
	testing.expect_value(t, sparql.Parse_Error_Code(parse_error), sparql.Error_Code.None)
	result, execute_error := engine.execute(&query, view, {Max_Solutions = 16})
	testing.expect_value(t, execute_error, engine.Error_Code.None)
	return result
}

@(private) has_rule :: proc(profile: ^rdfs.Profile, expected: rule.Rule_ID) -> bool {
	for index in 0..<rule.derivation_count(&profile.materializer) {
		derivation, found := rule.derivation_at(&profile.materializer, index)
		if found && derivation.rule_id == expected do return true
	}
	return false
}

@(private) same_term :: proc(left, right: rdf.Term) -> bool {
	return left.kind == right.kind && left.value == right.value && left.language == right.language && left.datatype == right.datatype && left.scope == right.scope
}

@(private) has_inferred :: proc(source: ^store.Store, expected: rdf.Triple) -> bool {
	for index in 0..<store.fact_count(source) {
		id, _, origin, found := store.fact_at(source, index)
		if !found || origin != .Inferred do continue
		actual, valid := store.triple_for(source, id)
		if valid && same_term(actual.subject, expected.subject) && same_term(actual.predicate, expected.predicate) && same_term(actual.object, expected.object) do return true
	}
	return false
}

@(private) Stop_State :: struct { calls: int }

@(private) stop_after_one :: proc(_: rdf.Quad, user_data: rawptr) -> bool {
	(cast(^Stop_State)user_data).calls += 1
	return false
}

@(test)
test_first_closure_from_fixture_through_destroyed_source :: proc(t: ^testing.T) {
	source_text := read(t, SOURCE_PATH)
	defer delete(source_text)

	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	profile: rdfs.Profile
	profile_error, store_error := rdfs.init(&profile, &source)
	testing.expect_value(t, profile_error, rdfs.Error_Code.None)
	testing.expect_value(t, store_error, store.Error_Code.None)

	state: importer.Sink_State
	importer.init(&state, &source)
	parsed := turtle.parse(string(source_text), importer.triple_sink, {}, &state)
	testing.expect_value(t, parsed.code, turtle.Error_Code.None)
	testing.expect_value(t, state.last_error, store.Error_Code.None)
	testing.expect_value(t, state.inserted, 7)
	testing.expect_value(t, state.duplicates, 0)

	materialized := rdfs.materialize(&profile, &source)
	testing.expect_value(t, materialized.error, rule.Error_Code.None)
	testing.expect_value(t, materialized.inferred_facts, 7)
	testing.expect_value(t, store.fact_count(&source), 14)
	testing.expect_value(t, rule.derivation_count(&profile.materializer), 7)
	testing.expect(t, has_rule(&profile, rdfs.RDFS_SC))
	testing.expect(t, has_rule(&profile, rdfs.RDFS_SC_TRANS))
	testing.expect(t, has_rule(&profile, rdfs.RDFS_SP))
	testing.expect(t, has_rule(&profile, rdfs.RDFS_RANGE))
	expected_inferred := [7]rdf.Triple{
		{rdf.iri("https://example.org/garden/ada"), rdf.iri(rdfs.RDF_TYPE), rdf.iri("https://example.org/garden/Agent")},
		{rdf.iri("https://example.org/garden/ada"), rdf.iri(rdfs.RDF_TYPE), rdf.iri("https://example.org/garden/Entity")},
		{rdf.iri("https://example.org/garden/Person"), rdf.iri(rdfs.RDFS_SUBCLASS), rdf.iri("https://example.org/garden/Entity")},
		{rdf.iri("https://example.org/garden/ada"), rdf.iri("https://example.org/garden/relatedTo"), rdf.iri("https://example.org/garden/bea")},
		{rdf.iri("https://example.org/garden/bea"), rdf.iri(rdfs.RDF_TYPE), rdf.iri("https://example.org/garden/Person")},
		{rdf.iri("https://example.org/garden/bea"), rdf.iri(rdfs.RDF_TYPE), rdf.iri("https://example.org/garden/Entity")},
		{rdf.iri("https://example.org/garden/bea"), rdf.iri(rdfs.RDF_TYPE), rdf.iri("https://example.org/garden/Agent")},
	}
	for expected in expected_inferred do testing.expect(t, has_inferred(&source, expected))

	limited_snapshot: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&limited_snapshot, &source, {max_quads = 13}), sparql_adapter.Error_Code.Quad_Limit)
	testing.expect_value(t, sparql_adapter.quad_count(&limited_snapshot), 0)

	snapshot: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&snapshot, &source, {max_quads = 14}), sparql_adapter.Error_Code.None)
	rdfs.destroy(&profile)
	store.destroy(&source)
	defer sparql_adapter.destroy(&snapshot)
	view := sparql_adapter.view(&snapshot)

	select_text := read(t, QUERY_ROOT + "select-agent.rq")
	defer delete(select_text)
	select_result := execute(t, string(select_text), view)
	defer engine.destroy(&select_result)
	testing.expect_value(t, engine.Row_Count(&select_result), 2)
	person, bound, valid := engine.Cell(&select_result, 0, 0)
	testing.expect(t, valid && bound)
	testing.expect_value(t, person.value, "https://example.org/garden/ada")
	second_person, second_bound, second_valid := engine.Cell(&select_result, 1, 0)
	testing.expect(t, second_valid && second_bound)
	testing.expect_value(t, second_person.value, "https://example.org/garden/bea")

	ask_text := read(t, QUERY_ROOT + "ask-bea-person.rq")
	defer delete(ask_text)
	ask_result := execute(t, string(ask_text), view)
	defer engine.destroy(&ask_result)
	ask, valid_ask := engine.Ask_Value(&ask_result)
	testing.expect(t, valid_ask && ask)

	construct_text := read(t, QUERY_ROOT + "construct-related.rq")
	defer delete(construct_text)
	construct_result := execute(t, string(construct_text), view)
	defer engine.destroy(&construct_result)
	testing.expect_value(t, engine.Triple_Count(&construct_result), 1)
}

@(test)
test_default_graph_scope_rejects_named_scans_and_honors_early_stop :: proc(t: ^testing.T) {
	source: store.Store
	testing.expect_value(t, store.init(&source), store.Error_Code.None)
	defer store.destroy(&source)
	added, store_error := store.insert_triple(&source, {rdf.iri("urn:a"), rdf.iri("urn:p"), rdf.iri("urn:o")})
	testing.expect(t, added)
	testing.expect_value(t, store_error, store.Error_Code.None)
	snapshot: sparql_adapter.Snapshot
	testing.expect_value(t, sparql_adapter.init(&snapshot, &source), sparql_adapter.Error_Code.None)
	defer sparql_adapter.destroy(&snapshot)

	state: Stop_State
	view := sparql_adapter.view(&snapshot)
	stop_error := dataset.scan(view, {}, stop_after_one, &state)
	testing.expect_value(t, stop_error, dataset.Error_Code.None)
	testing.expect_value(t, state.calls, 1)
	named_error := dataset.scan(view, {Graph_Mode = .Named}, stop_after_one, &state)
	any_named_error := dataset.scan(view, {Graph_Mode = .Any_Named}, stop_after_one, &state)
	testing.expect_value(t, named_error, dataset.Error_Code.Invalid_View)
	testing.expect_value(t, any_named_error, dataset.Error_Code.Invalid_View)
}
