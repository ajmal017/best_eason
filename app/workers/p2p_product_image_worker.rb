class P2pProductImageWorker
  @queue = :p2p_product_image_worker

  def self.perform
    P2pStrategy.all.each(&:index_image)
  end
end
