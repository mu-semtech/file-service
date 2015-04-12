class FilesController < ApplicationController

  before_action :set_config

  include RDF

  # POST /files
  def create
    uploaded_file = params[:file]

    file = {}
    file[:id] = SecureRandom.uuid
    file[:name] = "#{file[:id]}.#{uploaded_file.original_filename.split('.').last}" # uuid.extension
    file_path = file_path(file[:name])
    file[:href] = uri(file[:name])
    file[:format] = uploaded_file.content_type
    File.open(file_path, 'wb') { |f| f.write(uploaded_file.read) }
    file[:size] = File.size(file_path)
    now = DateTime.now.xmlschema

    query =  " INSERT DATA {"
    query += "   GRAPH <#{@graph}> {"
    query += "     <#{file[:href]}> a <#{NFO.FileDataObject}> ;"
    query += "         <#{NFO.fileName}> \"#{file[:name]}\" ;"
    query += "         <#{DC.identifier}> \"#{file[:id]}\" ;"
    query += "         <#{DC.format}> \"#{file[:format]}\" ;"
    query += "         <#{NFO.fileSize}> \"#{file[:size]}\"^^xsd:integer ;"
    query += "         <#{NFO.fileUrl}> \"file://#{file_path}\" ;"
    query += "         <#{DC.created}> \"#{now}\"^^xsd:dateTime ;"
    query += "         <#{DC.modified}> \"#{now}\"^^xsd:dateTime ."
    # TODO add creator/contributor
    query += "   }"
    query += " }"

    @sparql_client.update(query)

    render json: { :file => file }, status: :ok
  end

  # GET /files/:id
  def show
    query = " SELECT ?uri ?name ?format ?size FROM <#{@graph}> WHERE {"
    query += "   ?uri <#{DC.identifier}> \"#{params[:id]}\" ;"
    query += "        <#{NFO.fileName}> ?name ;"
    query += "        <#{DC.format}> ?format ;"
    query += "        <#{NFO.fileSize}> ?size ."
    query += " }"

    result = @sparql_client.query(query)
    raise ActionController::MissingFile if result.empty?

    file = {}
    result = result.first
    file[:href] = result[:uri].value
    file[:name] = result[:name].value
    file[:id] = params[:id]
    file[:format] = result[:format].value
    file[:size] = result[:size].value

    render json: { :file => file }, status: :ok
  end

  # GET /files/:id/download
  def download
    query = " SELECT ?fileUrl FROM <#{@graph}> WHERE {"
    query += "   ?uri <#{NFO.fileUrl}> ?fileUrl ; <#{DC.identifier}> \"#{params[:id]}\" ."
    query += " }"

    result = @sparql_client.query(query)
    raise ActionController::MissingFile if result.empty?
    url = result.first[:fileUrl].value

    send_file URI(url).path, disposition: 'attachment'
  end

  # DELETE /files/:id
  def destroy
    query = " SELECT ?fileUrl FROM <#{@graph}> WHERE {"
    query += "   ?uri <#{NFO.fileUrl}> ?fileUrl ; <#{DC.identifier}> \"#{params[:id]}\" ."
    query += " }"

    result = @sparql_client.query(query)
    raise ActionController::MissingFile if result.empty?

    url = result.first[:fileUrl].value
    path = URI(url).path
    File.delete path if File.exist? path

    query =  " WITH <#{@graph}> "
    query += " DELETE {"
    query += "   ?uri a <#{NFO.FileDataObject}> ;"
    query += "       <#{NFO.fileUrl}> \"#{url}\" ;"
    query += "       <#{NFO.fileName}> ?fileName ;"
    query += "       <#{DC.identifier}> ?id ;"
    query += "       <#{DC.format}> ?format ;"
    query += "       <#{NFO.fileSize}> ?fileSize ;"
    query += "       <#{DC.created}> ?created ;"
    query += "       <#{DC.modified}> ?modified ."
    # TODO remove creator/contributor
    query += " }"
    query += " WHERE {"
    query += "   ?uri a <#{NFO.FileDataObject}> ;"
    query += "       <#{NFO.fileUrl}> \"#{url}\" ;"
    query += "       <#{NFO.fileName}> ?fileName ;"
    query += "       <#{DC.identifier}> ?id ;"
    query += "       <#{DC.format}> ?format ;"
    query += "       <#{NFO.fileSize}> ?fileSize ;"
    query += "       <#{DC.created}> ?created ;"
    query += "       <#{DC.modified}> ?modified ."
    # TODO remove creator/contributor
    query += " }"
    @sparql_client.update(query)

    render json: nil, status: :no_content
  end


  # Exception handling

  rescue_from ActionController::MissingFile do |e|
    render json: { status: 'Not found' }, status: :not_found
  end



  private

  def set_config
    @storage_location = ENV['MU_APPLICATION_STORAGE_LOCATION'].gsub /\/$/, ""
    @graph = ENV['MU_APPLICATION_GRAPH'].gsub /\/$/, ""
    @sparql_client = SPARQL::Client.new('http://localhost:8890/sparql')
  end

  def uri(name)
    "#{@graph}/files/#{name}"
  end

  def file_path(name)
    "#{@storage_location}/#{name}"
  end

end
