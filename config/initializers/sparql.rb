# Be sure to restart your server when you modify this file.

Rails.application.config.x.rdf.sparql_endpoint = 'http://localhost:8890/sparql'
Rails.application.config.x.rdf.graph_base = 'http://tstr.semte.ch'

NFO = RDF::Vocabulary.new('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#')