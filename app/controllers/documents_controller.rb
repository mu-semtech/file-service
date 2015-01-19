class DocumentsController < ApplicationController

  @@storage_location = '/tmp/rails'

  # POST /documents
  def create
    file = params[:file]
    file_name = sanitize_filename(file.original_filename)
    File.open("#{@@storage_location}/#{file_name}", 'wb') { |f| f.write(file.read) }

    # TODO add file metadata

    render json: nil, status: :ok
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

  private

  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name)
    # replace all non alphanumeric, underscore or periods with underscore
    just_filename.sub(/[^\w\.\-]/,'_')
  end

end
