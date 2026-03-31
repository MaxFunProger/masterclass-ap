#pragma once

#include <string>
#include <string_view>

#include <userver/components/component_config.hpp>
#include <userver/components/component_context.hpp>
#include <userver/server/handlers/http_handler_base.hpp>
#include <userver/storages/postgres/cluster.hpp>

namespace masterclasses::handlers {

class UserFavoritesHandler final : public userver::server::handlers::HttpHandlerBase {
 public:
  static constexpr std::string_view kName = "handler-user-favorites";

  UserFavoritesHandler(const userver::components::ComponentConfig& config,
                     const userver::components::ComponentContext& context);

  std::string HandleRequestThrow(
      const userver::server::http::HttpRequest& request,
      userver::server::request::RequestContext& context) const override;

 private:
  userver::storages::postgres::ClusterPtr db_cluster_;
};

}  // namespace masterclasses::handlers



