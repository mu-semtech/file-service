class DocumentsController < ApplicationController

  before_action :set_config

  include RDF

  # POST /documents
  def create
    uploaded_file = params[:file]

    document = {}
    document[:id] = SecureRandom.uuid
    document[:name] = "#{document[:id]}.#{uploaded_file.original_filename.split('.').last}"
    file_path = "#{@storage_location}/#{document[:name]}"
    document[:href] = "#{@graph}documents/#{document[:name]}"
    document[:format] = uploaded_file.content_type
    File.open(file_path, 'wb') { |f| f.write(uploaded_file.read) }
    document[:size] = File.size(file_path)

    query =  " INSERT DATA {"
    query += "   GRAPH <#{@graph}/#{params[:project]}> {"
    query += "     <#{document[:href]}> a <#{NFO.FileDataObject}> ;"
    query += "             <#{NFO.fileName}> \"#{document[:name]}\" ;"
    query += "             <#{DC.identifier}> \"#{document[:id]}\" ;"
    query += "             <#{DC.format}> \"#{document[:format]}\" ;"
    query += "             <#{NFO.fileSize}> \"#{document[:size]}\"^^xsd:integer ."
    query += "   }"
    query += " }"

    @sparql_client.update(query)

    render json: { :document => document }, status: :ok
  end

  # GET /documents/:id
  def show
    send_file "#{@storage_location}/#{params[:id]}.#{params[:format]}", disposition: 'attachment'
  end

  # DELETE /documents/:id
  def destroy
    File.delete "#{@storage_location}/#{params[:id]}.#{params[:format]}"

    render json: nil, status: :no_content
  end


  # Exception handling

  rescue_from ActionController::MissingFile do |e|
    render json: { status: 'Not found' }, status: :not_found
  end

  private

  def set_config
    @storage_location = Rails.application.config.x.file.storage_location
    @graph = Rails.application.config.x.rdf.graph_base
    @sparql_access_point = Rails.application.config.x.rdf.sparql_endpoint
    @sparql_client = SPARQL::Client.new(@sparql_access_point)
  end

end
