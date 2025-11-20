#include "handlers/mc_list_handler.hpp"

#include <algorithm>
#include <cstdint>
#include <stdexcept>
#include <string>

#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/storages/postgres/component.hpp>
#include <userver/storages/postgres/query.hpp>

namespace masterclasses::handlers {

namespace {

const userver::storages::postgres::Query kSelectMasterclasses{
    "SELECT id, title, location, price, website, image_url "
    "FROM masterclasses ORDER BY id ASC LIMIT $1",
    userver::storages::postgres::Query::Name{"select-masterclasses"}};

const userver::storages::postgres::Query kTrackUserRequest{
    "INSERT INTO user_requests (user_id, request_count) VALUES ($1, 1) "
    "ON CONFLICT (user_id) DO UPDATE "
    "SET request_count = user_requests.request_count + 1 "
    "RETURNING request_count",
    userver::storages::postgres::Query::Name{"track-user-request"}};

std::int64_t ParsePositiveInt(const std::string& raw) {
  if (raw.empty()) {
    throw std::invalid_argument("value is empty");
  }
  std::int64_t value = 0;
  try {
    value = std::stoll(raw);
  } catch (const std::exception&) {
    throw std::invalid_argument("value is not a number");
  }
  if (value <= 0) {
    throw std::invalid_argument("value must be positive");
  }
  return value;
}

constexpr std::int64_t kMaxLimit = 100;

}  // namespace

McListHandler::McListHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      masterclasses_cluster_(
          context.FindComponent<userver::components::Postgres>("masterclasses-db")
              .GetCluster()),
      users_cluster_(
          context.FindComponent<userver::components::Postgres>("users-db")
              .GetCluster()) {}

std::string McListHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.SetResponseContentType(
      userver::http::content_type::kApplicationJson);

  const auto raw_limit = request.GetArg("n");
  const auto user_id = request.GetArg("user_id");

  if (user_id.empty()) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::HandlerErrorCode::kInvalidArgument,
        "user_id must be provided");
  }

  std::int64_t limit = 0;
  try {
    limit = ParsePositiveInt(raw_limit);
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::HandlerErrorCode::kInvalidArgument,
        std::string{"invalid n: "} + ex.what());
  }
  limit = std::min(limit, kMaxLimit);

  const auto result =
      masterclasses_cluster_->Execute(kSelectMasterclasses, limit);

  userver::formats::json::ValueBuilder masterclasses_json(
      userver::formats::json::Type::kArray);
  std::int64_t returned = 0;
  for (const auto& row : result) {
    userver::formats::json::ValueBuilder entry;
    entry["id"] = row["id"].As<std::int64_t>();
    entry["title"] = row["title"].As<std::string>();
    entry["location"] = row["location"].As<std::string>();
    entry["price"] = row["price"].As<double>();
    entry["website"] = row["website"].As<std::string>();
    entry["image_url"] = row["image_url"].As<std::string>();
    masterclasses_json.PushBack(entry.ExtractValue());
    ++returned;
  }

  const auto counter =
      users_cluster_->Execute(kTrackUserRequest, user_id).Front();
  const auto request_count =
      counter["request_count"].As<std::int64_t>(std::int64_t{1});

  userver::formats::json::ValueBuilder response;
  response["user_id"] = user_id;
  response["request_count"] = request_count;
  response["returned"] = returned;
  response["masterclasses"] = masterclasses_json.ExtractValue();

  request.SetResponseStatus(userver::server::http::HttpStatus::kOk);
  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers

