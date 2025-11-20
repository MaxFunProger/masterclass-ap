#pragma once

#include <string_view>

#include <userver/formats/json/value_builder.hpp>
#include <userver/server/handlers/http_handler_base.hpp>
#include <userver/server/http/http_response.hpp>
#include <userver/server/request/request_context.hpp>

namespace masterclasses::handlers {

class PingHandler final : public userver::server::handlers::HttpHandlerBase {
 public:
  static constexpr std::string_view kName = "handler-ping";

  using HttpHandlerBase::HttpHandlerBase;

  std::string HandleRequestThrow(
      const userver::server::http::HttpRequest& request,
      userver::server::request::RequestContext& context) const override;
};

}  // namespace masterclasses::handlers

