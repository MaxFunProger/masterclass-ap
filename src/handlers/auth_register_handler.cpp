#include "handlers/auth_register_handler.hpp"
#include "sql/queries.hpp"
#include "utils/phone.hpp"

#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_method.hpp>
#include <userver/storages/postgres/component.hpp>
#include <userver/utils/uuid4.hpp>
#include <userver/crypto/hash.hpp>

namespace masterclasses::handlers {

namespace {

using ClusterHostType = userver::storages::postgres::ClusterHostType;

std::string ExtractRequiredString(const userver::formats::json::Value& json,
                                  std::string_view field) {
  if (!json.HasMember(field)) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"missing field '" +
                                                std::string{field} + "'"});
  }
  return json[field].As<std::string>();
}

}  // namespace

AuthRegisterHandler::AuthRegisterHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      db_cluster_(
          context.FindComponent<userver::components::Postgres>("app-db")
              .GetCluster()) {}

std::string AuthRegisterHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.GetHttpResponse().SetContentType(
      userver::http::content_type::kApplicationJson);

  if (request.GetMethod() != userver::server::http::HttpMethod::kPost) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "register expects POST requests"});
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

  const auto phone_raw = ExtractRequiredString(payload, "phone");
  const auto full_name = ExtractRequiredString(payload, "full_name");
  const auto password = ExtractRequiredString(payload, "password");
  const auto telegram_nick = payload["telegram_nick"].As<std::string>("");

  const auto phone_digits = masterclasses::utils::NormalizeRuPhoneDigits(phone_raw);
  if (!phone_digits.has_value()) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"invalid phone"});
  }
  const auto phone_canonical = masterclasses::utils::RuPhoneToCanonical(phone_raw);
  if (!phone_canonical.has_value()) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"invalid phone"});
  }

  const auto existing = db_cluster_->Execute(
      ClusterHostType::kSlave, sql::kExistsUserByPhoneDigits, *phone_digits);
  if (!existing.IsEmpty()) {
    userver::formats::json::ValueBuilder response;
    request.SetResponseStatus(userver::server::http::HttpStatus::kConflict);
    response["status"] = "error";
    response["message"] = "phone already registered";
    return userver::formats::json::ToString(response.ExtractValue());
  }

  auto id = userver::utils::generators::GenerateUuid();
  auto password_hash = userver::crypto::hash::Sha256(password);

  const auto result = db_cluster_->Execute(
      ClusterHostType::kMaster, sql::kInsertUser, id, *phone_canonical, full_name,
      telegram_nick, password_hash);

  userver::formats::json::ValueBuilder response;
  if (result.RowsAffected() == 0) {
    request.SetResponseStatus(userver::server::http::HttpStatus::kConflict);
    response["status"] = "error";
    response["message"] = "phone already registered";
  } else {
    request.SetResponseStatus(userver::server::http::HttpStatus::kCreated);
    response["status"] = "success";
    response["user_id"] = id;
  }

  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers
