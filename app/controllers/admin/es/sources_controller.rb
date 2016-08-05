module Admin::ES
  class SourcesController < Admin::ApplicationController
    before_action :set_es_source, only: [:show, :edit, :update, :destroy]

    def index
      @q = ::ES::Source.search(params[:q])
      @es_sources = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
    end

    def show
    end

    def new
      @es_source = ::ES::Source.new
    end

    def edit
    end

    def create
      @es_source = ::ES::Source.new(es_source_params)

      if @es_source.save
        redirect_to [:admin, @es_source], notice: 'Source was successfully created.'
      else
        render :new
      end
    end

    def update
      if @es_source.update(es_source_params)
        redirect_to [:admin, @es_source], notice: 'Source was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @es_source.destroy
      redirect_to admin_es_sources_url, notice: 'Source was successfully destroyed.'
    end

    private
  
    def set_es_source
      @es_source = ::ES::Source.find(params[:id])
    end

    def es_source_params
      params.require(:es_source).permit(:name, :url, :code)
    end
  end
end
