class FilesController < ApplicationController

  before_action :set_config

  include RDF

  # POST /files
  def create
    raise ActiveModel::ForbiddenAttributesError, 'Id paramater is not allowed.' if not params[:id].blank?
    raise ArgumentError, 'File parameter is required.' if params[:file].blank?
    raise ArgumentError, 'X-Rewrite-URL header is missing.' if request.headers['X-Rewrite-URL'].blank?
    

    uploaded_file = params[:file]

    file = { type: "files", id: SecureRandom.uuid, attributes: {} }
    file[:attributes][:name] = "#{file[:id]}.#{uploaded_file.original_filename.split('.').last}" # uuid.extension
    file_path = file_path(file[:attributes][:name])
    file[:attributes][:format] = uploaded_file.content_type
    File.open(file_path, 'wb') { |f| f.write(uploaded_file.read) }
    file[:attributes][:size] = File.size(file_path)
    links = { self: "#{request.headers['X-Rewrite-URL'].chomp '/'}/#{file[:id]}" }
    now = DateTime.now.xmlschema

    query =  " INSERT DATA {"
    query += "   GRAPH <#{@graph}> {"
    query += "     <#{links[:self]}> a <#{NFO.FileDataObject}> ;"
    query += "         <#{NFO.fileName}> \"#{file[:attributes][:name]}\" ;"
    query += "         <#{MU_CORE.uuid}> \"#{file[:id]}\" ;"
    query += "         <#{DC.format}> \"#{file[:attributes][:format]}\" ;"
    query += "         <#{NFO.fileSize}> \"#{file[:attributes][:size]}\"^^xsd:integer ;"
    query += "         <#{NFO.fileUrl}> \"file://#{file_path}\" ;"
    query += "         <#{DC.created}> \"#{now}\"^^xsd:dateTime ;"
    query += "         <#{DC.modified}> \"#{now}\"^^xsd:dateTime ."
    # TODO add creator/contributor
    query += "   }"
    query += " }"

    @sparql_client.update(query)

    render json: { :data => file, :links => links }, content_type: 'application/vnd.api+json', status: :created
  end

  # GET /files/:id
  def show

    raise ArgumentError 'X-Rewrite-URL header is missing.' if request.headers['X-Rewrite-URL'].blank?

    query = " SELECT ?uri ?name ?format ?size FROM <#{@graph}> WHERE {"
    query += "   ?uri <#{MU_CORE.uuid}> \"#{params[:id]}\" ;"
    query += "        <#{NFO.fileName}> ?name ;"
    query += "        <#{DC.format}> ?format ;"
    query += "        <#{NFO.fileSize}> ?size ."
    query += " }"

    result = @sparql_client.query(query)
    raise ActionController::MissingFile if result.empty?

    result = result.first
    file = { type: "files", id: params[:id], attributes: {} }
    links = { self: request.headers['X-Rewrite-URL'] }
    file[:attributes][:name] = result[:name].value
    file[:attributes][:format] = result[:format].value
    file[:attributes][:size] = result[:size].value

    render json: { :data => file, :links => links }, content_type: 'application/vnd.api+json', status: :ok
  end

  # GET /files/:id/download
  def download
    query = " SELECT ?fileUrl FROM <#{@graph}> WHERE {"
    query += "   ?uri <#{NFO.fileUrl}> ?fileUrl ; <#{MU_CORE.uuid}> \"#{params[:id]}\" ."
    query += " }"

    result = @sparql_client.query(query)
    raise ActionController::MissingFile if result.empty?
    url = result.first[:fileUrl].value

    send_file URI(url).path, disposition: 'attachment'
  end

  # DELETE /files/:id
  def destroy
    query = " SELECT ?fileUrl FROM <#{@graph}> WHERE {"
    query += "   ?uri <#{NFO.fileUrl}> ?fileUrl ; <#{MU_CORE.uuid}> \"#{params[:id]}\" ."
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
    query += "       <#{MU_CORE.uuid}> ?id ;"
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
    query += "       <#{MU_CORE.uuid}> ?id ;"
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
    render json: { errors: [{ title: 'File not found.' }] }, status: :not_found
  end

  rescue_from ArgumentError do |e|
    render json: { errors: [{ title: e.message }] }, status: :bad_request
  end

  rescue_from ActiveModel::ForbiddenAttributesError do |e|
    render json: { errors: [{ title: e.message }] }, status: :forbidden
  end


  private

  def set_config
    @storage_location = ENV['MU_APPLICATION_STORAGE_LOCATION'].gsub /\/$/, ""
    @graph = ENV['MU_APPLICATION_GRAPH'].gsub /\/$/, ""
    @sparql_client = SPARQL::Client.new(ENV['MU_SPARQL_ENDPOINT'])
  end

  def file_path(name)
    "#{@storage_location}/#{name}"
  end

end
