# CLI application fixtures

These fixtures exercise a released Odin command as an application boundary.
They may reuse an authored semantic fixture for their input graphs, but own
the command arguments, standard-output schema, exit status, and operational
exclusions that make the workflow reproducible.

They do not turn the command line into a new RDF model, validation profile, or
network API.
