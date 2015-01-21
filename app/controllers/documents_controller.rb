class DocumentsController < ApplicationController

  include RDF

  @@storage_location = '/tmp/rails'
  @@graph = "http://tstr.semte.ch/"
  @@sparql_access_point = "http://localhost:8890/sparql"

  @@nfo = RDF::Vocabulary.new("http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#")

  # POST /documents
  def create
    uploaded_file = params[:file]

    document = {}
    document[:id] = "fwooptiedoe" # TODO
    document[:name] = "#{document[:id]}.#{uploaded_file.original_filename.split('.').last}"
    file_path = "#{@@storage_location}/#{document[:name]}"
    document[:href] = "#{@@graph}documents/#{document[:name]}"
    document[:format] = uploaded_file.content_type
    document[:size] = File.size(file_path)
    File.open(file_path, 'wb') { |f| f.write(uploaded_file.read) }

    query =  " INSERT DATA {"
    query += "   GRAPH <#{@@graph}/#{params[:project]}> {"
    query += "     <#{document[:href]}> a <#{@@nfo.FileDataObject}> ;"
    query += "             <#{@@nfo.fileName}> \"#{document[:name]}\" ;"
    query += "             <#{DC.identifier}> \"#{document[:id]}\" ;"
    query += "             <#{DC.format}> \"#{document[:format]}\" ;"
    query += "             <#{@@nfo.fileSize}> \"#{document[:size]}\"^^xsd:integer ."
    query += "   }"
    query += " }"

    sparql_client.update(query)

    render json: { :document => document }, status: :ok
  end

  # GET /documents/:id
  def show
    send_file "#{@@storage_location}/#{params[:id]}.#{params[:format]}", disposition: 'attachment'
  end

  # DELETE /documents/:id
  def destroy
    File.delete "#{@@storage_location}/#{params[:id]}.#{params[:format]}"

    render json: nil, status: :no_content
  end

  rescue_from ActionController::MissingFile do |e|
    render json: { status: 'Not found' }, status: :not_found
  end

  private

  def sparql_client
    SPARQL::Client.new(@@sparql_access_point)
  end

end
