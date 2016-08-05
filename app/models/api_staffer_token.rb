class ApiStafferToken < ApiToken
  self.table_name = "api_staffer_tokens"
  belongs_to :staffer, class_name: Admin::Staffer
end
