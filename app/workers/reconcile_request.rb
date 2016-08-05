class ReconcileRequest
  @queue = :reconcile_request

  def self.perform
    ReconcileRequestCts.publish
  end
end
