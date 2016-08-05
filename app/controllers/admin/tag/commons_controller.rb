module Admin::Tag
  class CommonsController < Admin::ApplicationController
    before_action :set_tag_basis, only: [:show, :edit, :update, :destroy, :baskets]

    def index
      @hot_eq =  params[:q][:hot_eq] rescue nil
      params[:q][:name_cont] = params[:q][:name_cont].try(:strip) if params[:q]
      @q = ::Tag::Common.normal.search(params[:q])
      @tag_bases = @q.result.order(:sort).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
    end

    def show
    end

    def baskets
      @taggings = @tag_basis.taggings.basket.includes(:taggable)
    end

    def new
      @tag_basis = ::Tag::Common.new
      @can_edit = true
    end

    def edit
      @can_edit = !@tag_basis.be_used?
    end

    def create
      @tag_basis = ::Tag::Common.new(tag_basis_params)

      if @tag_basis.save
        redirect_to [:admin, @tag_basis], notice: 'Base was successfully created.'
      else
        render :new
      end
    end

    def update
      if @tag_basis.update(tag_basis_params)
        redirect_to [:admin, @tag_basis], notice: 'Base was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @tag_basis.delete_by_state if !@tag_basis.be_used?
      redirect_to admin_tag_commons_url, notice: 'Base was successfully destroyed.'
    end

    def positions
      ::Tag::Common.update_positions(params[:ids])
      render json: {status: true}
    end

    private

    def set_tag_basis
      @tag_basis = ::Tag::Common.find(params[:id])
    end

    def tag_basis_params
      params.require(:tag_common).permit(:name, :sort, :hot)
    end
  end
end
