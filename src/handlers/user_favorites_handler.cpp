#include "handlers/user_favorites_handler.hpp"
#include "sql/queries.hpp"

#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_method.hpp>
#include <userver/storages/postgres/component.hpp>

namespace masterclasses::handlers {

namespace {

using ClusterHostType = userver::storages::postgres::ClusterHostType;

}  // namespace

UserFavoritesHandler::UserFavoritesHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      db_cluster_(
          context.FindComponent<userver::components::Postgres>("app-db")
              .GetCluster()) {}

std::string UserFavoritesHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.GetHttpResponse().SetContentType(
      userver::http::content_type::kApplicationJson);

  if (request.GetMethod() == userver::server::http::HttpMethod::kGet) {
      const auto user_id = request.GetArg("user_id");
      if (user_id.empty()) {
         throw userver::server::handlers::ClientError(
            userver::server::handlers::ExternalBody{"missing user_id"});
      }

      const auto fav_result = db_cluster_->Execute(ClusterHostType::kMaster, sql::kSelectFavorites, user_id);
      std::vector<std::int64_t> ids;
      for (const auto& row : fav_result) {
          ids.push_back(row[0].As<std::int64_t>());
      }

      if (ids.empty()) {
          return userver::formats::json::ToString(userver::formats::json::FromString("{\"masterclasses\": []}"));
      }

      const auto mc_result = db_cluster_->Execute(ClusterHostType::kMaster, sql::kSelectMasterclassesByIds, ids);
      
      userver::formats::json::ValueBuilder masterclasses_json(userver::formats::json::Type::kArray);
      for (const auto& row : mc_result) {
        userver::formats::json::ValueBuilder entry;
        entry["id"] = row["id"].As<std::int64_t>();
        entry["title"] = row["title"].As<std::string>();
        entry["location"] = row["location"].As<std::string>();
        entry["price"] = row["price"].As<double>();
        entry["website"] = row["website"].As<std::string>();
        entry["image_url"] = row["image_url"].As<std::string>();
        entry["format"] = row["format"].As<std::string>();
        entry["company"] = row["company"].As<std::string>();
        entry["category"] = row["category"].As<std::string>();
        entry["min_age"] = row["min_age"].As<int>();
        entry["rating"] = row["rating"].As<double>();

        entry["description"] = row["description"].As<std::optional<std::string>>().value_or("");
        entry["event_date"] = row["event_date"].As<std::optional<std::string>>().value_or("");
        entry["duration"] = row["duration"].As<std::optional<std::string>>().value_or("");
        entry["organizer"] = row["organizer"].As<std::optional<std::string>>().value_or("");
        entry["audience"] = row["audience"].As<std::optional<std::string>>().value_or("");
        entry["additional_tags"] = row["additional_tags"].As<std::optional<std::string>>().value_or("");
        entry["contact_tg"] = row["contact_tg"].As<std::optional<std::string>>().value_or("");
        entry["contact_vk"] = row["contact_vk"].As<std::optional<std::string>>().value_or("");
        entry["contact_phone"] = row["contact_phone"].As<std::optional<std::string>>().value_or("");

        masterclasses_json.PushBack(entry.ExtractValue());
      }
      
      userver::formats::json::ValueBuilder response;
      response["masterclasses"] = masterclasses_json.ExtractValue();
      return userver::formats::json::ToString(response.ExtractValue());

  } else if (request.GetMethod() == userver::server::http::HttpMethod::kPost) {
      const auto body = request.RequestBody();
      userver::formats::json::Value payload;
      try {
        payload = userver::formats::json::FromString(body);
      } catch (const std::exception& ex) {
        throw userver::server::handlers::ClientError(
            userver::server::handlers::ExternalBody{
                std::string{"failed to parse JSON: "} + ex.what()});
      }

      if (!payload.HasMember("user_id") || !payload.HasMember("masterclass_id")) {
          throw userver::server::handlers::ClientError(
             userver::server::handlers::ExternalBody{"missing user_id or masterclass_id"});
      }

      std::string user_id = payload["user_id"].As<std::string>();
      std::int64_t mc_id = payload["masterclass_id"].As<std::int64_t>();

      db_cluster_->Execute(ClusterHostType::kMaster, sql::kInsertFavorite, user_id, mc_id);
      request.SetResponseStatus(userver::server::http::HttpStatus::kCreated);
      return "{}";
  } else if (request.GetMethod() == userver::server::http::HttpMethod::kDelete) {
      const auto user_id = request.GetArg("user_id");
      const auto mc_id_str = request.GetArg("masterclass_id");
      if (user_id.empty() || mc_id_str.empty()) throw userver::server::handlers::ClientError(userver::server::handlers::ExternalBody{"missing user_id or masterclass_id"});

      std::int64_t mc_id = std::stoll(mc_id_str);
      db_cluster_->Execute(ClusterHostType::kMaster, sql::kDeleteFavorite, user_id, mc_id);
      return "{}";
  }

  throw userver::server::handlers::ClientError(
      userver::server::handlers::ExternalBody{"unsupported method"});
}

}  // namespace masterclasses::handlers

