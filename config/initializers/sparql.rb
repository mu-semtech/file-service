# Be sure to restart your server when you modify this file.

NFO = RDF::Vocabulary.new('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#')
MU = RDF::Vocabulary.new('http://mu.semte.ch/vocabularies/')
MU_CORE = RDF::Vocabulary.new(MU.to_uri.to_s + 'core/')

FILE_SERVICE_RESOURCE_BASE = 'http://mu.semte.ch/services/file-service/'
