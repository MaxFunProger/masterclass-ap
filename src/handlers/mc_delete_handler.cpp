#include "handlers/mc_delete_handler.hpp"

#include <cstdint>
#include <optional>
#include <stdexcept>
#include <string>

#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_method.hpp>
#include <userver/server/http/http_status.hpp>
#include <userver/storages/postgres/component.hpp>
#include <userver/storages/postgres/query.hpp>

namespace masterclasses::handlers {

namespace {

using ClusterHostType = userver::storages::postgres::ClusterHostType;

const userver::storages::postgres::Query kDeleteMasterclass{
    "DELETE FROM masterclasses WHERE id = $1",
    userver::storages::postgres::Query::Name{"delete-masterclass"}};

std::int64_t ParseId(const userver::server::http::HttpRequest& request) {
  const auto id_str = request.GetArg("id");
  if (id_str.empty()) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "query parameter 'id' is required"});
  }

  try {
    return std::stoll(id_str);
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "invalid 'id' parameter: " + std::string{ex.what()}});
  }
}

}  // namespace

McDeleteHandler::McDeleteHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      masterclasses_cluster_(
          context.FindComponent<userver::components::Postgres>("masterclasses-db")
              .GetCluster()) {}

std::string McDeleteHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.GetHttpResponse().SetContentType(
      userver::http::content_type::kApplicationJson);

  if (request.GetMethod() != userver::server::http::HttpMethod::kDelete) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "mcdelete expects DELETE requests"});
  }

  const auto id = ParseId(request);

  const auto result = masterclasses_cluster_->Execute(
      ClusterHostType::kMaster, kDeleteMasterclass, id);

  userver::formats::json::ValueBuilder response;
  response["id"] = id;

  if (result.RowsAffected() == 0) {
    request.SetResponseStatus(userver::server::http::HttpStatus::kNotFound);
    response["status"] = "not_found";
    response["message"] = "masterclass with this id does not exist";
  } else {
    request.SetResponseStatus(userver::server::http::HttpStatus::kOk);
    response["status"] = "deleted";
  }

  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers


