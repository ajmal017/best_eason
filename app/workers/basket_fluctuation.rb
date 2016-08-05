class BasketFluctuation
  @queue = :basket_fluctuation

  def self.perform
    User.all.each do |u|
      u.basket_fluctuation = u.fluctuation
      u.save
    end
  end
end