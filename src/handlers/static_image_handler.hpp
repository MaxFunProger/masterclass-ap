#pragma once

#include <userver/components/component_config.hpp>
#include <userver/components/component_context.hpp>
#include <userver/server/handlers/http_handler_base.hpp>

namespace masterclasses::handlers {

class StaticImageHandler final
    : public userver::server::handlers::HttpHandlerBase {
  public:
    static constexpr std::string_view kName = "handler-static-images";

    StaticImageHandler(const userver::components::ComponentConfig& config,
                       const userver::components::ComponentContext& context);

    std::string HandleRequestThrow(
        const userver::server::http::HttpRequest& request,
        userver::server::request::RequestContext&) const override;
};

}  // namespace masterclasses::handlers
