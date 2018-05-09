require 'ruby-filemagic'
require 'fileutils'

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

FILE_SERVICE_RESOURCE_BASE = 'http://mu.semte.ch/services/file-service'

###
# POST /files
# Upload a new file. Results in 2 new nfo:FileDataObject resources: one representing
# the uploaded file and one representing the persisted file on disk generated from the upload.
#
# Accepts multipart/form-data with a 'file' parameter containing the file to upload
# 
# Returns 201 on successful upload of the file
#         400 if X-Rewrite header is missing
#             if file param is missing
###
post '/files/?' do
  rewrite_url = rewrite_url_header(request)
  error('X-Rewrite-URL header is missing.') if rewrite_url.nil?
  error('File parameter is required.') if params['file'].nil?

  tempfile = params['file'][:tempfile]

  upload_resource_uuid = generate_uuid()
  upload_resource_name = params['file'][:filename]
  upload_resource_uri = "#{FILE_SERVICE_RESOURCE_BASE}/files/#{upload_resource_uuid}"
  
  file_format = file_magic.file(tempfile.path)
  file_extension = upload_resource_name.split('.').last
  file_size = File.size(tempfile.path)

  file_resource_uuid = generate_uuid()
  file_resource_name = "#{file_resource_uuid}.#{file_extension}"
  file_resource_uri = file_to_shared_uri(file_resource_name)
    
  now = DateTime.now

  FileUtils.copy(tempfile.path, "#{settings.storage_path}/#{file_resource_name}")

  query =  " INSERT DATA {"
  query += "   GRAPH <#{graph}> {"
  query += "     <#{upload_resource_uri}> a <#{NFO.FileDataObject}> ;"
  query += "         <#{NFO.fileName}> #{upload_resource_name.sparql_escape} ;"
  query += "         <#{MU_CORE.uuid}> #{upload_resource_uuid.sparql_escape} ;"
  query += "         <#{DC.format}> #{file_format.sparql_escape} ;"
  query += "         <#{NFO.fileSize}> #{sparql_escape_int(file_size)} ;"
  query += "         <#{DBPEDIA.fileExtension}> #{file_extension.sparql_escape} ;"
  query += "         <#{DC.created}> #{now.sparql_escape} ;"
  query += "         <#{DC.modified}> #{now.sparql_escape} ."
  query += "     <#{file_resource_uri}> a <#{NFO.FileDataObject}> ;"
  query += "         <#{NIE.dataSource}> <#{upload_resource_uri}> ;"
  query += "         <#{NFO.fileName}> #{file_resource_name.sparql_escape} ;"
  query += "         <#{MU_CORE.uuid}> #{file_resource_uuid.sparql_escape} ;"
  query += "         <#{DC.format}> #{file_format.sparql_escape} ;"
  query += "         <#{NFO.fileSize}> #{sparql_escape_int(file_size)} ;"
  query += "         <#{DBPEDIA.fileExtension}> #{file_extension.sparql_escape} ;"  
  query += "         <#{DC.created}> #{now.sparql_escape} ;"
  query += "         <#{DC.modified}> #{now.sparql_escape} ."
  query += "   }"
  query += " }"
  update(query)

  content_type 'application/vnd.api+json'
  status 201
  {
    data: {
      type: 'files',
      id: upload_resource_uuid,
      attributes: {
        name: upload_resource_name,
        format: file_format,
        size: file_size,
        extension: file_extension
      }
    },
    links: {
      self: "#{rewrite_url.chomp '/'}/#{upload_resource_uuid}"
    }
  }.to_json
end

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

  query = " SELECT ?uri ?name ?format ?size ?extension FROM <#{graph}> WHERE {"
  query += "   ?uri <#{MU_CORE.uuid}> #{sparql_escape_string(params['id'])} ;"
  query += "        <#{NFO.fileName}> ?name ;"
  query += "        <#{DC.format}> ?format ;"
  query += "        <#{DBPEDIA.fileExtension}> ?extension ;"    
  query += "        <#{NFO.fileSize}> ?size ."
  query += " }"
  result = query(query)

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
###
get '/files/:id/download' do
  query = " SELECT ?fileUrl FROM <#{graph}> WHERE {"
  query += "   ?uri <#{MU_CORE.uuid}> #{sparql_escape_string(params['id'])} ."
  query += "   ?fileUrl <#{NIE.dataSource}> ?uri ."
  query += " }"
  result = query(query)

  return status 404 if result.empty?
  
  url = result.first[:fileUrl].value
  path = shared_uri_to_path(url)

  filename = params['name']
  filename ||= File.basename(path)

  send_file path, disposition: 'attachment', filename: filename
end

###
# DELETE /files/:id
# Delete a file and its metadata
#
# Returns 204 on successful removal of the file and metadata
#         404 if a file with the given id cannot be found
###
delete '/files/:id' do
  query = " SELECT ?uri ?fileUrl FROM <#{graph}> WHERE {"
  query += "   ?uri <#{MU_CORE.uuid}> #{sparql_escape_string(params['id'])} ."
  query += "   ?fileUrl <#{NIE.dataSource}> ?uri ."
  query += " }"
  result = query(query)

  return status 404 if result.empty?

  query =  " WITH <#{graph}> "
  query += " DELETE WHERE {"
  query += "   <#{result.first[:uri]}> a <#{NFO.FileDataObject}> ;"
  query += "       <#{NFO.fileName}> ?upload_name ;"
  query += "       <#{MU_CORE.uuid}> ?upload_id ;"
  query += "       <#{DC.format}> ?upload_format ;"
  query += "       <#{DBPEDIA.fileExtension}> ?upload_extension ;"  
  query += "       <#{NFO.fileSize}> ?upload_size ;"
  query += "       <#{DC.created}> ?upload_created ;"
  query += "       <#{DC.modified}> ?upload_modified ."
  query += "   <#{result.first[:fileUrl]}> a <#{NFO.FileDataObject}> ;"
  query += "       <#{NIE.dataSource}> <#{result.first[:uri]}> ;"  
  query += "       <#{NFO.fileName}> ?fileName ;"
  query += "       <#{MU_CORE.uuid}> ?id ;"
  query += "       <#{DC.format}> ?format ;"
  query += "       <#{DBPEDIA.fileExtension}> ?extension ;"  
  query += "       <#{NFO.fileSize}> ?size ;"
  query += "       <#{DC.created}> ?created ;"
  query += "       <#{DC.modified}> ?modified ."
  query += " }"
  update(query)
  
  url = result.first[:fileUrl].value
  path = shared_uri_to_path(url)
  File.delete path if File.exist? path

  status 204
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
