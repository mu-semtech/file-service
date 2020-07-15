require 'ruby-filemagic'
require 'fileutils'
require 'mu/auth-sudo'

###
# Configuration
###
if ENV['MU_APPLICATION_FILE_STORAGE_PATH'] and ENV['MU_APPLICATION_FILE_STORAGE_PATH'].start_with?('/')
  log.fatal "MU_APPLICATION_FILE_STORAGE_PATH (#{ENV['MU_APPLICATION_FILE_STORAGE_PATH']}) must be relative"
  exit
else
  FileUtils.mkdir_p "/share/#{ENV['MU_APPLICATION_FILE_STORAGE_PATH']}"
end

configure do
  set :relative_storage_path, (ENV['MU_APPLICATION_FILE_STORAGE_PATH'] || '').chomp('/')
  set :storage_path, "/share/#{(ENV['MU_APPLICATION_FILE_STORAGE_PATH'] || '')}".chomp('/')
end

file_magic = FileMagic.new(FileMagic::MAGIC_MIME)


###
# Vocabularies
###
DC = RDF::Vocab::DC
NFO = RDF::Vocabulary.new('http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#')
NIE = RDF::Vocabulary.new('http://www.semanticdesktop.org/ontologies/2007/01/19/nie#')
DBPEDIA = RDF::Vocabulary.new('http://dbpedia.org/ontology/')
EXT = RDF::Vocabulary.new('http://mu.semte.ch/vocabularies/ext/')

FILE_SERVICE_RESOURCE_BASE = 'http://mu.semte.ch/services/file-service'


###
# GET /files/:id
# Get metadata of the file with the given id
#
# Returns 200 containing the file with the specified id
#         404 if a file with the given id cannot be found
###
get '/files/:id' do
  rewrite_url = rewrite_url_header(request)
  error('X-Rewrite-URL header is missing.') if rewrite_url.nil?

  query = " SELECT ?uri ?name ?format ?size ?extension WHERE {"
  query += "   ?uri <#{MU_CORE.uuid}> #{sparql_escape_string(params['id'])} ;"
  query += "        <#{NFO.fileName}> ?name ;"
  query += "        <#{DC.format}> ?format ;"
  query += "        <#{DBPEDIA.fileExtension}> ?extension ;"
  query += "        <#{NFO.fileSize}> ?size ."
  query += "   ?document <#{EXT.file}> ?uri."
  query += "   ?document <#{EXT.toegangsniveauVoorDocumentVersie}> <http://kanselarij.vo.data.gift/id/concept/toegangs-niveaus/6ca49d86-d40f-46c9-bde3-a322aa7e5c8e>."
  query += " }"
  result = query_sudo(query)

  return status 404 if result.empty?
  result = result.first

  content_type 'application/vnd.api+json'
  status 200
  {
    data: {
      type: 'files',
      id: params['id'],
      attributes: {
        name: result[:name].value,
        format: result[:format].value,
        size: result[:size].value,
        extension: result[:extension].value
      }
    },
    links: {
      self: rewrite_url
    }
  }.to_json
end

###
# GET /files/:id/download?name=foo.pdf
#
# @param name [string] Optional name of the downloaded file
#
# Returns 200 with the file content as attachment
#         404 if a file with the given id cannot be found
#         500 if the file is available in the database but not on disk
###
get '/files/:id/download' do
  query = " SELECT ?fileUrl WHERE {"
  query += "   ?uri <#{MU_CORE.uuid}> #{sparql_escape_string(params['id'])} ."
  query += "   ?fileUrl <#{NIE.dataSource}> ?uri ."
  query += "   ?document <#{EXT.file}> ?uri."
  query += "   ?document <#{EXT.toegangsniveauVoorDocumentVersie}> <http://kanselarij.vo.data.gift/id/concept/toegangs-niveaus/6ca49d86-d40f-46c9-bde3-a322aa7e5c8e>."
  query += " }"
  result = query(query)

  return status 404 if result.empty?

  url = result.first[:fileUrl].value
  path = shared_uri_to_path(url)

  filename = params['name']
  filename ||= File.basename(path)
  if File.file?(path)
    send_file path, disposition: 'attachment', filename: filename
  else
    error("Could not find file in path. Check if the physical file is available on the server and if this service has the right mountpoint.", 500)
  end
end

###
# Helpers
###
def shared_uri_to_path(uri)
  uri.sub('share://', '/share/')
end

def file_to_shared_uri(file_name)
  if settings.relative_storage_path and not settings.relative_storage_path.empty?
    return "share://#{settings.relative_storage_path}/#{file_name}"
  else
    return "share://#{file_name}"
  end
end
