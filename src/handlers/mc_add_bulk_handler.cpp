#include "handlers/mc_add_bulk_handler.hpp"

#include <cstdint>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_method.hpp>
#include <userver/storages/postgres/component.hpp>
#include <userver/storages/postgres/query.hpp>

namespace masterclasses::handlers {

namespace {

using ClusterHostType = userver::storages::postgres::ClusterHostType;

const userver::storages::postgres::Query kInsertMasterclass{
    "INSERT INTO masterclasses "
    "(id, title, location, price, website, image_url) "
    "VALUES ($1, $2, $3, $4, $5, $6) "
    "ON CONFLICT (id) DO NOTHING",
    userver::storages::postgres::Query::Name{"insert-masterclass-bulk"}};

template <typename T>
T ExtractRequired(const userver::formats::json::Value& json,
                  std::string_view field, std::size_t index) {
  if (!json.HasMember(field)) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "missing field '" + std::string{field} + "' for item #" +
            std::to_string(index)});
  }

  try {
    return json[field].As<T>();
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "invalid field '" + std::string{field} + "' for item #" +
            std::to_string(index) + ": " + ex.what()});
  }
}

struct MasterclassPayload final {
  std::int64_t id;
  std::string title;
  std::string location;
  double price;
  std::string website;
  std::string image_url;
};

}  // namespace

McAddBulkHandler::McAddBulkHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      masterclasses_cluster_(
          context.FindComponent<userver::components::Postgres>("masterclasses-db")
              .GetCluster()) {}

std::string McAddBulkHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.GetHttpResponse().SetContentType(
      userver::http::content_type::kApplicationJson);

  if (request.GetMethod() != userver::server::http::HttpMethod::kPost) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "mcaddbulk expects POST requests"});
  }

  const auto body = request.RequestBody();
  if (body.empty()) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"request body is empty"});
  }

  userver::formats::json::Value payload_json;
  try {
    payload_json = userver::formats::json::FromString(body);
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            std::string{"failed to parse JSON: "} + ex.what()});
  }

  if (!payload_json.IsArray()) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "expected JSON array with masterclasses"});
  }

  if (payload_json.GetSize() == 0) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "array must not be empty"});
  }

  std::vector<MasterclassPayload> items;
  items.reserve(payload_json.GetSize());
  for (std::size_t i = 0; i < payload_json.GetSize(); ++i) {
    const auto& item = payload_json[i];
    if (!item.IsObject()) {
      throw userver::server::handlers::ClientError(
          userver::server::handlers::ExternalBody{
              "each item must be an object, offending index #" +
              std::to_string(i)});
    }

    items.push_back(MasterclassPayload{
        ExtractRequired<std::int64_t>(item, "id", i),
        ExtractRequired<std::string>(item, "title", i),
        ExtractRequired<std::string>(item, "location", i),
        ExtractRequired<double>(item, "price", i),
        ExtractRequired<std::string>(item, "website", i),
        ExtractRequired<std::string>(item, "image_url", i),
    });
  }

  std::size_t inserted_count = 0;
  userver::formats::json::ValueBuilder results(
      userver::formats::json::Type::kArray);

  for (const auto& item : items) {
    const auto result = masterclasses_cluster_->Execute(
        ClusterHostType::kMaster, kInsertMasterclass, item.id, item.title,
        item.location, item.price, item.website, item.image_url);

    userver::formats::json::ValueBuilder entry;
    entry["id"] = item.id;
    if (result.RowsAffected() == 0) {
      entry["status"] = "duplicate";
      entry["message"] = "masterclass with this id already exists";
    } else {
      entry["status"] = "created";
      ++inserted_count;
    }
    results.PushBack(entry.ExtractValue());
  }

  const auto duplicates = items.size() - inserted_count;

  userver::formats::json::ValueBuilder response;
  response["requested"] = items.size();
  response["inserted"] = inserted_count;
  response["duplicates"] = duplicates;
  response["results"] = results.ExtractValue();

  if (inserted_count == 0) {
    request.SetResponseStatus(userver::server::http::HttpStatus::kConflict);
    response["status"] = "duplicates";
  } else if (inserted_count == items.size()) {
    request.SetResponseStatus(userver::server::http::HttpStatus::kCreated);
    response["status"] = "created";
  } else {
    request.SetResponseStatus(
        userver::server::http::HttpStatus::kMultiStatus);
    response["status"] = "partial";
  }

  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers


