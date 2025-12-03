#include "handlers/ping_handler.hpp"

#include <chrono>
#include <ctime>
#include <string>

#include <userver/formats/json/serialize.hpp>

namespace masterclasses::handlers {

namespace {
std::string GetCurrentTimestamp() {
  using namespace std::chrono;
  const auto now = system_clock::now();
  const auto time = system_clock::to_time_t(now);
  std::tm tm;
  gmtime_r(&time, &tm);

  char buffer[32];
  if (std::strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", &tm) == 0) {
    return "unknown";
  }
  return std::string{buffer};
}
}  // namespace

std::string PingHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  request.SetResponseStatus(userver::server::http::HttpStatus::kOk);
  request.GetHttpResponse().SetContentType(
      userver::http::content_type::kApplicationJson);

  userver::formats::json::ValueBuilder response;
  response["status"] = "ok";
  response["service"] = "masterclasses-service";
  response["timestamp"] = GetCurrentTimestamp();

  return userver::formats::json::ToString(response.ExtractValue());
}

}  // namespace masterclasses::handlers

