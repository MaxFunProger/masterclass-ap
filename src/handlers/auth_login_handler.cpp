#include "handlers/auth_login_handler.hpp"
#include "sql/queries.hpp"
#include "utils/phone.hpp"

#include <optional>

#include <userver/crypto/hash.hpp>
#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_method.hpp>
#include <userver/storages/postgres/component.hpp>

namespace masterclasses::handlers {

namespace {

using ClusterHostType = userver::storages::postgres::ClusterHostType;

}  // namespace

AuthLoginHandler::AuthLoginHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      db_cluster_(context.FindComponent<userver::components::Postgres>("app-db")
                      .GetCluster()) {}

std::string AuthLoginHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
    request.GetHttpResponse().SetContentType(
        userver::http::content_type::kApplicationJson);

    if (request.GetMethod() != userver::server::http::HttpMethod::kPost) {
        throw userver::server::handlers::ClientError(
            userver::server::handlers::ExternalBody{
                "login expects POST requests"});
    }

    const auto body = request.RequestBody();
    userver::formats::json::Value payload;
    try {
        payload = userver::formats::json::FromString(body);
    } catch (...) {
        throw userver::server::handlers::ClientError(
            userver::server::handlers::ExternalBody{"invalid json"});
    }

    if (!payload.HasMember("phone") || !payload.HasMember("password")) {
        throw userver::server::handlers::ClientError(
            userver::server::handlers::ExternalBody{
                "missing phone or password"});
    }

    const auto phone_raw = payload["phone"].As<std::string>();
    const auto password = payload["password"].As<std::string>();

    const auto phone_digits =
        masterclasses::utils::NormalizeRuPhoneDigits(phone_raw);
    if (!phone_digits.has_value()) {
        throw userver::server::handlers::ClientError(
            userver::server::handlers::ExternalBody{"invalid phone"});
    }

    auto result = db_cluster_->Execute(ClusterHostType::kSlave,
                                       sql::kSelectUserByPhone, *phone_digits);

    if (result.IsEmpty()) {
        request.SetResponseStatus(
            userver::server::http::HttpStatus::kUnauthorized);
        return userver::formats::json::ToString(
            userver::formats::json::MakeObject("status", "error", "message",
                                               "User not found"));
    }

    auto row = result[0];
    auto stored_hash = row["password_hash"].As<std::string>();
    auto input_hash = userver::crypto::hash::Sha256(password);

    if (input_hash != stored_hash) {
        request.SetResponseStatus(
            userver::server::http::HttpStatus::kUnauthorized);
        return userver::formats::json::ToString(
            userver::formats::json::MakeObject("status", "error", "message",
                                               "Invalid password"));
    }

    userver::formats::json::ValueBuilder response;
    response["status"] = "success";
    response["user_id"] = row["id"].As<std::string>();
    response["full_name"] = row["full_name"].As<std::string>();
    response["telegram_nick"] =
        row["telegram_nick"].As<std::optional<std::string>>().value_or("");

    return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers
