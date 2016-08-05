class Ajax::RegionController < Ajax::ApplicationController
  
  # 城市二级联动
  def cities
    @cities = CityInit.get_cities_by_province_code(params[:province_id])
  end
  
  def get_cities
    @cities = CityInit.get_cities_by_province_code(params[:province_id])
  end
  
  def fetch_cities
    @cities = CityInit.get_cities_by_province_code(params[:province_id])
    respond_to do |format|
      format.js
      format.json { render json: { cities: @cities.map(&:name)}, callback: params[:callback], content_type: 'application/javascript' }
    end
  end
end
