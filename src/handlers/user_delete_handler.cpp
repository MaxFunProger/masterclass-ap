#include "handlers/user_delete_handler.hpp"

#include <string>

#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_method.hpp>
#include <userver/storages/postgres/component.hpp>
#include <userver/storages/postgres/query.hpp>

namespace masterclasses::handlers {

namespace {

using ClusterHostType = userver::storages::postgres::ClusterHostType;

const userver::storages::postgres::Query kDeleteUser{
    "DELETE FROM user_requests WHERE user_id = $1",
    userver::storages::postgres::Query::Name{"delete-user"}};

std::string ParseUserId(const userver::server::http::HttpRequest& request) {
  const auto user_id = request.GetArg("user_id");
  if (user_id.empty()) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "query parameter 'user_id' is required"});
  }
  return user_id;
}

}  // namespace

UserDeleteHandler::UserDeleteHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      users_cluster_(
          context.FindComponent<userver::components::Postgres>("users-db")
              .GetCluster()) {}

std::string UserDeleteHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.GetHttpResponse().SetContentType(
      userver::http::content_type::kApplicationJson);

  if (request.GetMethod() != userver::server::http::HttpMethod::kDelete) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "userdelete expects DELETE requests"});
  }

  const auto user_id = ParseUserId(request);

  const auto result = users_cluster_->Execute(
      ClusterHostType::kMaster, kDeleteUser, user_id);

  userver::formats::json::ValueBuilder response;
  response["user_id"] = user_id;

  if (result.RowsAffected() == 0) {
    request.SetResponseStatus(userver::server::http::HttpStatus::kNotFound);
    response["status"] = "not_found";
  } else {
    request.SetResponseStatus(userver::server::http::HttpStatus::kOk);
    response["status"] = "deleted";
  }

  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers


