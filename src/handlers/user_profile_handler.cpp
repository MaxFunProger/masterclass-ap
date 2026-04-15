#include "handlers/user_profile_handler.hpp"
#include "sql/queries.hpp"

#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_method.hpp>
#include <userver/storages/postgres/component.hpp>

namespace masterclasses::handlers {

namespace {

using ClusterHostType = userver::storages::postgres::ClusterHostType;

}  // namespace

UserProfileHandler::UserProfileHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      db_cluster_(context.FindComponent<userver::components::Postgres>("app-db")
                      .GetCluster()) {}

std::string UserProfileHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
    request.GetHttpResponse().SetContentType(
        userver::http::content_type::kApplicationJson);

    const auto user_id = request.GetArg("user_id");
    if (user_id.empty()) {
        throw userver::server::handlers::ClientError(
            userver::server::handlers::ExternalBody{"missing user_id"});
    }

    const auto result = db_cluster_->Execute(ClusterHostType::kSlave,
                                             sql::kSelectUserProfile, user_id);

    if (result.IsEmpty()) {
        throw userver::server::handlers::ResourceNotFound(
            userver::server::handlers::ExternalBody{"User not found"});
    }

    const auto row = result[0];
    userver::formats::json::ValueBuilder response;
    response["id"] = row["id"].As<std::string>();
    response["phone"] = row["phone"].As<std::string>();
    response["full_name"] = row["full_name"].As<std::string>();
    response["telegram_nick"] =
        row["telegram_nick"].As<std::optional<std::string>>().value_or("");

    return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers
