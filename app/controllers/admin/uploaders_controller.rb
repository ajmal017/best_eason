class Admin::UploadersController < Admin::ApplicationController

	def create
    @upload = CommonUploader.new
    @upload.store! params[:file]
  end
end