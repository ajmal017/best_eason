require "grape-swagger"

module V1
  class Base < Grape::API

    include V1::Defaults

    mount V1::Users
    mount V1::Search
    mount V1::Profile
    mount V1::Baskets
    mount V1::Stocks
    mount V1::Trading
    mount V1::Notifications
    mount V1::Relationships
    mount V1::Permissions
    mount V1::Reminders
    mount V1::Chart
    mount V1::Comments
    mount V1::Emotions
    mount V1::Feeds
    mount V1::Favorites
    mount V1::Pages
    mount V1::P2p
    mount V1::Admin::Users
    mount V1::Snapshots

    add_swagger_documentation mount_path: "/api-doc", api_version: "v1", hide_documentation_path: true, hide_format: false,
                              info: {title: "移动端app接口文档", description: "v1.0"}

  end
end
