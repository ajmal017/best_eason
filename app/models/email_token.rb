class EmailToken < ActiveRecord::Base
  validates :email, uniqueness: {conditions: -> {where.not(confirmed_at: nil)}}, format: { with: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i }

  include Confirmable
end
