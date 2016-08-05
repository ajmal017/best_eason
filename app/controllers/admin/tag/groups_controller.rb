module Admin::Tag
  class GroupsController < Admin::ApplicationController
    before_action :set_tag_basis, only: [:show, :edit, :update, :destroy, :baskets]

    def index
      @hot_eq =  params[:q][:hot_eq] rescue nil
      @q = ::Tag::Group.normal.search(params[:q])
      @tag_bases = @q.result.order(:sort).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
    end

    def show
    end
    
    def baskets
      @taggings = @tag_basis.taggings
    end

    def new
      @tag_basis = ::Tag::Group.new
    end

    def edit
      @can_edit = !@tag_basis.be_used?
    end

    def create
      @tag_basis = ::Tag::Group.new(tag_basis_params)

      if @tag_basis.save
        redirect_to admin_tag_groups_url, notice: 'Base was successfully created.'
      else
        render :new
      end
    end

    def update
      if @tag_basis.update(tag_basis_params)
        redirect_to admin_tag_groups_url, notice: 'Base was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @tag_basis.delete_by_state if !@tag_basis.be_used?
      redirect_to admin_tag_groups_url, notice: 'Base was successfully destroyed.'
    end
    
    def positions
      ::Tag::Group.update_positions(params[:ids])
      render json: {status: true}
    end

    private
  
    def set_tag_basis
      @tag_basis = ::Tag::Group.find(params[:id])
    end

    def tag_basis_params
      params.require(:tag_group).permit(:name, :sort, :hot)
    end
  end
end
