#include "handlers/mc_add_handler.hpp"

#include <cstdint>
#include <stdexcept>
#include <string>

#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_method.hpp>
#include <userver/storages/postgres/component.hpp>
#include <userver/storages/postgres/query.hpp>

namespace masterclasses::handlers {

namespace {

const userver::storages::postgres::Query kInsertMasterclass{
    "INSERT INTO masterclasses "
    "(id, title, location, price, website, image_url) "
    "VALUES ($1, $2, $3, $4, $5, $6) "
    "ON CONFLICT (id) DO NOTHING",
    userver::storages::postgres::Query::Name{"insert-masterclass"}};

template <typename T>
T ExtractRequired(const userver::formats::json::Value& json,
                  std::string_view field) {
  if (!json.HasMember(field)) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::HandlerErrorCode::kInvalidArgument,
        std::string{"missing field: "} + std::string{field});
  }
  try {
    return json[field].As<T>();
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::HandlerErrorCode::kInvalidArgument,
        std::string{"invalid field "} + std::string{field} + ": " + ex.what());
  }
}

}  // namespace

McAddHandler::McAddHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      masterclasses_cluster_(
          context.FindComponent<userver::components::Postgres>("masterclasses-db")
              .GetCluster()) {}

std::string McAddHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.SetResponseContentType(
      userver::http::content_type::kApplicationJson);

  if (request.GetMethod() != userver::server::http::HttpMethod::kPost) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::HandlerErrorCode::kInvalidArgument,
        "mcadd expects POST requests");
  }

  const auto body = request.RequestBody();
  if (body.empty()) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::HandlerErrorCode::kInvalidArgument,
        "request body is empty");
  }

  userver::formats::json::Value payload;
  try {
    payload = userver::formats::json::FromString(body);
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::HandlerErrorCode::kInvalidArgument,
        std::string{"failed to parse JSON: "} + ex.what());
  }

  const auto id = ExtractRequired<std::int64_t>(payload, "id");
  const auto title = ExtractRequired<std::string>(payload, "title");
  const auto location = ExtractRequired<std::string>(payload, "location");
  const auto price = ExtractRequired<double>(payload, "price");
  const auto website = ExtractRequired<std::string>(payload, "website");
  const auto image_url = ExtractRequired<std::string>(payload, "image_url");

  const auto result = masterclasses_cluster_->Execute(
      kInsertMasterclass, id, title, location, price, website, image_url);

  userver::formats::json::ValueBuilder response;
  response["id"] = id;
  response["title"] = title;

  if (result.RowsAffected() == 0) {
    request.SetResponseStatus(userver::server::http::HttpStatus::kConflict);
    response["status"] = "duplicate";
    response["message"] = "masterclass with this id already exists";
  } else {
    request.SetResponseStatus(
        userver::server::http::HttpStatus::kCreated);
    response["status"] = "created";
  }

  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers

