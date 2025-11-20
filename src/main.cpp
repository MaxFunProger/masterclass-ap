#include "handlers/mc_add_handler.hpp"
#include "handlers/mc_list_handler.hpp"
#include "handlers/ping_handler.hpp"

#include <userver/components/minimal_component_list.hpp>
#include <userver/storages/postgres/component.hpp>
#include <userver/utils/daemon_run.hpp>

int main(int argc, char* argv[]) {
  auto component_list = userver::components::MinimalComponentList()
                            .Append<userver::components::Postgres>(
                                "masterclasses-db")
                            .Append<userver::components::Postgres>("users-db")
                            .Append<masterclasses::handlers::PingHandler>()
                            .Append<masterclasses::handlers::McListHandler>()
                            .Append<masterclasses::handlers::McAddHandler>();

  return userver::utils::DaemonMain(argc, argv, component_list);
}

