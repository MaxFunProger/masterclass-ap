#include "handlers/user_add_handler.hpp"

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

using ClusterHostType = userver::storages::postgres::ClusterHostType;

const userver::storages::postgres::Query kInsertUser{
    "INSERT INTO user_requests "
    "(user_id, phone, full_name, telegram_nick, request_count) "
    "VALUES ($1, $2, $3, $4, $5) "
    "ON CONFLICT (user_id) DO NOTHING",
    userver::storages::postgres::Query::Name{"insert-user"}};

template <typename T>
T Extract(const userver::formats::json::Value& json, std::string_view field,
          const T& default_value) {
  if (!json.HasMember(field)) {
    return default_value;
  }
  try {
    return json[field].As<T>();
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"invalid field '" +
                                                std::string{field} + "': " +
                                                ex.what()});
  }
}

std::string ExtractRequiredString(const userver::formats::json::Value& json,
                                  std::string_view field) {
  if (!json.HasMember(field)) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"missing field '" +
                                                std::string{field} + "'"});
  }
  try {
    auto value = json[field].As<std::string>();
    if (value.empty()) {
      throw std::runtime_error("must not be empty");
    }
    return value;
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"invalid field '" +
                                                std::string{field} + "': " +
                                                ex.what()});
  }
}

}  // namespace

UserAddHandler::UserAddHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      users_cluster_(
          context.FindComponent<userver::components::Postgres>("users-db")
              .GetCluster()) {}

std::string UserAddHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.GetHttpResponse().SetContentType(
      userver::http::content_type::kApplicationJson);

  if (request.GetMethod() != userver::server::http::HttpMethod::kPost) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "useradd expects POST requests"});
  }

  const auto body = request.RequestBody();
  if (body.empty()) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"request body is empty"});
  }

  userver::formats::json::Value payload;
  try {
    payload = userver::formats::json::FromString(body);
  } catch (const std::exception& ex) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            std::string{"failed to parse JSON: "} + ex.what()});
  }

  const auto user_id = ExtractRequiredString(payload, "user_id");
  const auto phone = ExtractRequiredString(payload, "phone");
  const auto full_name = ExtractRequiredString(payload, "full_name");
  const auto telegram_nick = ExtractRequiredString(payload, "telegram_nick");
  const auto initial_count =
      Extract<std::int64_t>(payload, "request_count", std::int64_t{0});
  if (initial_count < 0) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "request_count must be non-negative"});
  }

  const auto result = users_cluster_->Execute(
      ClusterHostType::kMaster, kInsertUser, user_id, phone, full_name,
      telegram_nick, initial_count);

  userver::formats::json::ValueBuilder response;
  response["user_id"] = user_id;
  response["request_count"] = initial_count;
  response["phone"] = phone;
  response["full_name"] = full_name;
  response["telegram_nick"] = telegram_nick;
  if (result.RowsAffected() == 0) {
    request.SetResponseStatus(userver::server::http::HttpStatus::kConflict);
    response["status"] = "duplicate";
    response["message"] = "user already exists";
  } else {
    request.SetResponseStatus(userver::server::http::HttpStatus::kCreated);
    response["status"] = "created";
  }

  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers


