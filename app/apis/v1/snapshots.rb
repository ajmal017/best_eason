module V1
  class Snapshots < Grape::API

    resource :snapshots, desc: "snapshot" do

      add_desc "snapshot"
      params do
        requires :url, desc: "网址"
      end
      post do
        Resque.enqueue(SnapshotWorker, params[:url])
      end

    end
  end
end