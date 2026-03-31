#include "handlers/mc_add_handler.hpp"
#include "sql/queries.hpp"

#include <cstdint>
#include <stdexcept>
#include <string>

#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_method.hpp>
#include <userver/storages/postgres/component.hpp>
#include <userver/utils/datetime.hpp>

namespace masterclasses::handlers {

namespace {

using ClusterHostType = userver::storages::postgres::ClusterHostType;

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

McAddHandler::McAddHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      db_cluster_(
          context.FindComponent<userver::components::Postgres>("app-db")
              .GetCluster()) {}

std::string McAddHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.GetHttpResponse().SetContentType(
      userver::http::content_type::kApplicationJson);

  if (request.GetMethod() != userver::server::http::HttpMethod::kPost) {
    throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{
            "mcadd expects POST requests"});
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

  const auto id = Extract<std::int64_t>(payload, "id", 0);
  if (id <= 0) {
      throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"id must be positive"});
  }
  const auto title = ExtractRequiredString(payload, "title");
  const auto location = Extract<std::string>(payload, "location", "Moscow");
  const auto price = Extract<double>(payload, "price", 0.0);
  const auto website = Extract<std::string>(payload, "website", "");
  const auto image_url = ExtractRequiredString(payload, "image_url");

  const auto format = Extract<std::string>(payload, "format", "offline");
  const auto company = Extract<std::string>(payload, "company", "single");
  const auto category = Extract<std::string>(payload, "category", "Other");
  const auto min_age = Extract<int>(payload, "min_age", 0);
  const auto rating = Extract<double>(payload, "rating", 5.0);
  
  const auto description = Extract<std::string>(payload, "description", "");
  const auto duration = Extract<std::string>(payload, "duration", "");
  const auto organizer = Extract<std::string>(payload, "organizer", "");
  const auto contact_tg = Extract<std::string>(payload, "contact_tg", "");
  const auto contact_vk = Extract<std::string>(payload, "contact_vk", "");
  const auto contact_phone = Extract<std::string>(payload, "contact_phone", "");
  const auto audience = Extract<std::string>(payload, "audience", "");
  const auto additional_tags = Extract<std::string>(payload, "additional_tags", "");

  std::string event_date;
  if (payload.HasMember("event_date")) {
      try {
        event_date = payload["event_date"].As<std::string>();
        if (event_date.empty()) event_date = "1970-01-01";
      } catch (...) {
          event_date = "1970-01-01";
      }
  } else {
      event_date = "1970-01-01";
  }

  const auto result = db_cluster_->Execute(
      ClusterHostType::kMaster, sql::kInsertMasterclass, id, title, location, price, website, image_url,
      format, company, category, min_age, rating, 
      description, event_date, duration, organizer, contact_tg, contact_vk, contact_phone, audience, additional_tags);

  userver::formats::json::ValueBuilder response;
  response["id"] = id;
  if (result.RowsAffected() == 0) {
    request.SetResponseStatus(userver::server::http::HttpStatus::kConflict);
    response["status"] = "duplicate";
  } else {
    request.SetResponseStatus(userver::server::http::HttpStatus::kCreated);
    response["status"] = "created";
  }

  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers
