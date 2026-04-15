#include "handlers/mc_list_handler.hpp"
#include "sql/queries.hpp"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

#include <userver/formats/json/serialize.hpp>
#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/exceptions.hpp>
#include <userver/storages/postgres/component.hpp>

namespace masterclasses::handlers {

namespace {

using ClusterHostType = userver::storages::postgres::ClusterHostType;

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

std::int64_t ParseNonNegativeInt(const std::string& raw) {
    if (raw.empty()) {
        throw std::invalid_argument("value is empty");
    }
    std::int64_t value = 0;
    try {
        value = std::stoll(raw);
    } catch (const std::exception&) {
        throw std::invalid_argument("value is not a number");
    }
    if (value < 0) {
        throw std::invalid_argument("value must be non-negative");
    }
    return value;
}

std::vector<std::int64_t> ParseIdList(std::string_view raw) {
    std::vector<std::int64_t> ids;
    std::size_t start = 0;
    while (start < raw.size()) {
        auto end = raw.find(',', start);
        if (end == std::string_view::npos) {
            end = raw.size();
        }
        auto token = raw.substr(start, end - start);
        while (!token.empty() && token.front() == ' ')
            token.remove_prefix(1);
        while (!token.empty() && token.back() == ' ')
            token.remove_suffix(1);
        if (!token.empty()) {
            try {
                auto value = std::stoll(std::string(token));
                if (value > 0) {
                    ids.push_back(value);
                }
            } catch (const std::exception&) {
            }
        }
        start = end + 1;
    }
    return ids;
}

constexpr std::int64_t kMaxLimit = 100;

/// Strict YYYY-MM-DD for query params (avoids injection).
bool IsValidIsoDate(std::string_view s) {
    if (s.size() != 10) {
        return false;
    }
    if (s[4] != '-' || s[7] != '-') {
        return false;
    }
    for (std::size_t i : {0u, 1u, 2u, 3u, 5u, 6u, 8u, 9u}) {
        if (!std::isdigit(static_cast<unsigned char>(s[i]))) {
            return false;
        }
    }
    return true;
}

}  // namespace

McListHandler::McListHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context),
      db_cluster_(context.FindComponent<userver::components::Postgres>("app-db")
                      .GetCluster()) {}

std::string McListHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
    request.GetHttpResponse().SetContentType(
        userver::http::content_type::kApplicationJson);

    const auto raw_limit = request.GetArg("n");
    const auto raw_offset = request.GetArg("offset");

    std::int64_t limit = 20;
    if (!raw_limit.empty()) {
        try {
            limit = ParsePositiveInt(raw_limit);
        } catch (...) {
        }
    }
    limit = std::min(limit, kMaxLimit);

    std::int64_t offset = 0;
    if (!raw_offset.empty()) {
        try {
            offset = ParseNonNegativeInt(raw_offset);
        } catch (...) {
        }
    }

    auto category = request.GetArg("category");
    auto audience = request.GetArg("audience");
    auto tags = request.GetArg("tags");
    auto format = request.GetArg("format");
    auto company = request.GetArg("company");
    auto exclude_ids = request.GetArg("exclude_ids");

    std::optional<int> min_age;
    if (request.HasArg("min_age")) {
        min_age = std::stoi(request.GetArg("min_age"));
    }

    std::optional<double> max_price;
    if (request.HasArg("max_price")) {
        max_price = std::stod(request.GetArg("max_price"));
    }

    std::optional<double> min_price;
    if (request.HasArg("min_price")) {
        min_price = std::stod(request.GetArg("min_price"));
    }

    std::optional<double> min_rating;
    if (request.HasArg("min_rating")) {
        min_rating = std::stod(request.GetArg("min_rating"));
    }

    std::optional<std::string> category_opt =
        category.empty() ? std::nullopt : std::optional<std::string>(category);
    if (category_opt.has_value()) {
        const auto& c = *category_opt;
        if (c == "photo_video" || c == "photography") {
            category_opt = "photo_video,photography";
        } else if (c == "tech_digital" || c == "tech_coding") {
            category_opt = "tech_digital,tech_coding";
        }
    }
    std::optional<std::string> audience_opt =
        audience.empty() ? std::nullopt : std::optional<std::string>(audience);
    std::optional<std::string> tags_opt =
        tags.empty() ? std::nullopt : std::optional<std::string>(tags);
    std::optional<std::string> format_opt =
        format.empty() ? std::nullopt : std::optional<std::string>(format);
    std::optional<std::string> company_opt =
        company.empty() ? std::nullopt : std::optional<std::string>(company);
    std::optional<std::vector<std::int64_t>> exclude_ids_opt = std::nullopt;
    if (!exclude_ids.empty()) {
        auto parsed_ids = ParseIdList(exclude_ids);
        if (!parsed_ids.empty()) {
            exclude_ids_opt = std::move(parsed_ids);
        }
    }

    std::optional<std::string> event_date_from_opt = std::nullopt;
    std::optional<std::string> event_date_to_opt = std::nullopt;
    if (request.HasArg("event_date_from")) {
        const auto& s = request.GetArg("event_date_from");
        if (IsValidIsoDate(s)) {
            event_date_from_opt = std::string(s);
        }
    }
    if (request.HasArg("event_date_to")) {
        const auto& s = request.GetArg("event_date_to");
        if (IsValidIsoDate(s)) {
            event_date_to_opt = std::string(s);
        }
    }

    auto sort_order = request.GetArg("sort_order");
    const userver::storages::postgres::Query* query_ptr =
        &sql::kSelectMasterclassesFiltered;

    if (sort_order == "date_asc") {
        query_ptr = &sql::kSelectMasterclassesFilteredDateAsc;
    } else if (sort_order == "date_desc") {
        query_ptr = &sql::kSelectMasterclassesFilteredDateDesc;
    }

    const auto result = db_cluster_->Execute(
        ClusterHostType::kSlave, *query_ptr, category_opt, audience_opt,
        tags_opt, format_opt, company_opt, min_age, max_price, min_price,
        min_rating, exclude_ids_opt, event_date_from_opt, event_date_to_opt,
        limit, offset);

    userver::formats::json::ValueBuilder masterclasses_json(
        userver::formats::json::Type::kArray);

    for (const auto& row : result) {
        userver::formats::json::ValueBuilder entry;
        entry["id"] = row["id"].As<std::int64_t>();
        entry["title"] = row["title"].As<std::string>();
        entry["location"] = row["location"].As<std::string>();
        entry["price"] = row["price"].As<double>();
        entry["website"] = row["website"].As<std::string>();
        entry["image_url"] = row["image_url"].As<std::string>();

        entry["format"] =
            row["format"].As<std::optional<std::string>>().value_or("offline");
        entry["company"] =
            row["company"].As<std::optional<std::string>>().value_or("single");
        entry["category"] =
            row["category"].As<std::optional<std::string>>().value_or("");
        entry["min_age"] = row["min_age"].As<std::optional<int>>().value_or(0);
        entry["rating"] =
            row["rating"].As<std::optional<double>>().value_or(5.0);

        entry["description"] =
            row["description"].As<std::optional<std::string>>().value_or("");
        entry["event_date"] =
            row["event_date"].As<std::optional<std::string>>().value_or("");
        entry["duration"] =
            row["duration"].As<std::optional<std::string>>().value_or("");
        entry["organizer"] =
            row["organizer"].As<std::optional<std::string>>().value_or("");
        entry["audience"] =
            row["audience"].As<std::optional<std::string>>().value_or("");
        entry["additional_tags"] =
            row["additional_tags"].As<std::optional<std::string>>().value_or(
                "");
        entry["contact_tg"] =
            row["contact_tg"].As<std::optional<std::string>>().value_or("");
        entry["contact_vk"] =
            row["contact_vk"].As<std::optional<std::string>>().value_or("");
        entry["contact_phone"] =
            row["contact_phone"].As<std::optional<std::string>>().value_or("");

        masterclasses_json.PushBack(entry.ExtractValue());
    }

    userver::formats::json::ValueBuilder response;
    response["returned"] = result.Size();
    response["masterclasses"] = masterclasses_json.ExtractValue();

    request.SetResponseStatus(userver::server::http::HttpStatus::kOk);
    return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers
