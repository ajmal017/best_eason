class Mobile::SurveysController < Mobile::ApplicationController
  
  def zhaocha
    render layout: "mobile/common"
  end

  def create
    @survey = Survey.create(survey_params.merge(user_id: current_user.try(:id)))
  end

  private
  def survey_params
    params.require(:survey).permit(:q1_1, :q1_2, :q2, :q3_1, :q3_2, :q3_3, :q3_4, :q3_5, :q4, :q5, :user_name, :user_gender, :user_phone)
  end
end
