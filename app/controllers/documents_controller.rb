class DocumentsController < ApplicationController

  @@storage_location = '/tmp/rails'

  # POST /documents
  def create
    file = params[:file]
    file_name = sanitize_filename(file.original_filename)
    File.open("#{@@storage_location}/#{file_name}", 'wb') { |f| f.write(file.read) }

    # TODO add file metadata

    render json: { }, status: :ok
  end

  private

  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name)
    # replace all non alphanumeric, underscore or periods with underscore
    just_filename.sub(/[^\w\.\-]/,'_')
  end

end
