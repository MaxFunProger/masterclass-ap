#include "handlers/auth_login_handler.hpp"
#include "handlers/auth_register_handler.hpp"
#include "handlers/mc_add_handler.hpp"
#include "handlers/mc_delete_handler.hpp"
#include "handlers/mc_list_handler.hpp"
#include "handlers/ping_handler.hpp"
#include "handlers/user_delete_handler.hpp"
#include "handlers/user_favorites_handler.hpp"
#include "handlers/user_profile_handler.hpp"

#include <userver/clients/dns/component.hpp>
#include <userver/clients/http/component.hpp>
#include <userver/clients/http/component_core.hpp>
#include <userver/clients/http/middlewares/pipeline_component.hpp>
#include <userver/components/fs_cache.hpp>
#include <userver/components/minimal_server_component_list.hpp>
#include <userver/server/handlers/http_handler_static.hpp>
#include <userver/storages/postgres/component.hpp>
#include <userver/storages/secdist/component.hpp>
#include <userver/storages/secdist/provider_component.hpp>
#include <userver/testsuite/testsuite_support.hpp>
#include <userver/utils/daemon_run.hpp>

int main(int argc, char* argv[]) {
    auto component_list =
        userver::components::MinimalServerComponentList()
            .Append<userver::components::DefaultSecdistProvider>()
            .Append<userver::components::Secdist>()
            .Append<userver::components::TestsuiteSupport>()
            .Append<userver::components::HttpClientCore>()
            .Append<userver::clients::http::MiddlewarePipelineComponent>()
            .Append<userver::components::HttpClient>()
            .Append<userver::clients::dns::Component>()
            .Append<userver::components::Postgres>("app-db")
            .Append<masterclasses::handlers::PingHandler>()
            .Append<masterclasses::handlers::McListHandler>()
            .Append<masterclasses::handlers::McAddHandler>()
            .Append<masterclasses::handlers::McDeleteHandler>()
            .Append<masterclasses::handlers::AuthRegisterHandler>()
            .Append<masterclasses::handlers::AuthLoginHandler>()
            .Append<masterclasses::handlers::UserDeleteHandler>()
            .Append<masterclasses::handlers::UserProfileHandler>()
            .Append<masterclasses::handlers::UserFavoritesHandler>()
            .Append<userver::components::FsCache>("fs-cache-component")
            .Append<userver::server::handlers::HttpHandlerStatic>();

    return userver::utils::DaemonMain(argc, argv, component_list);
}
