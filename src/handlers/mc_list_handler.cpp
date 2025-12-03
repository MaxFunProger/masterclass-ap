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

using ClusterHostType = userver::storages::postgres::ClusterHostType;

const userver::storages::postgres::Query kSelectMasterclasses{
    "SELECT id, title, location, price, website, image_url "
    "FROM masterclasses ORDER BY id ASC LIMIT $1",
    userver::storages::postgres::Query::Name{"select-masterclasses"}};

const userver::storages::postgres::Query kIncrementUserRequest{
    "UPDATE user_requests "
    "SET request_count = user_requests.request_count + 1 "
    "WHERE user_id = $1 "
    "RETURNING request_count",
    userver::storages::postgres::Query::Name{"increment-user-request"}};

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
  request.GetHttpResponse().SetContentType(
      userver::http::content_type::kApplicationJson);

  const auto raw_limit = request.GetArg("n");
  const auto user_id = request.GetArg("user_id");

  const bool has_user = !user_id.empty();

  std::int64_t limit = 0;
  try {
    limit = ParsePositiveInt(raw_limit);
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{std::string{"invalid n: "} +
                                                ex.what()});
  }
  limit = std::min(limit, kMaxLimit);

  const auto counter_result = users_cluster_->Execute(
      ClusterHostType::kMaster, kIncrementUserRequest, user_id);
  std::optional<std::int64_t> request_count;
  if (has_user) {
    const auto counter_result = users_cluster_->Execute(
        ClusterHostType::kMaster, kIncrementUserRequest, user_id);
    if (counter_result.IsEmpty()) {
      request.SetResponseStatus(userver::server::http::HttpStatus::kNotFound);
      userver::formats::json::ValueBuilder error;
      error["status"] = "user_not_found";
      error["user_id"] = user_id;
      return userver::formats::json::ToString(error.ExtractValue());
    }
    const auto counter = counter_result.Front();
    request_count = counter["request_count"].As<std::int64_t>();
  }

  const auto result = masterclasses_cluster_->Execute(
      ClusterHostType::kSlave, kSelectMasterclasses, limit);

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

  userver::formats::json::ValueBuilder response;
  if (has_user) {
    response["user_id"] = user_id;
    response["request_count"] = *request_count;
  }
  response["returned"] = returned;
  response["masterclasses"] = masterclasses_json.ExtractValue();

  request.SetResponseStatus(userver::server::http::HttpStatus::kOk);
  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers

