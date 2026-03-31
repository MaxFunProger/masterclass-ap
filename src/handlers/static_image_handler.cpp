#include "handlers/static_image_handler.hpp"

#include <filesystem>
#include <fstream>
#include <string>

#include <userver/server/handlers/exceptions.hpp>
#include <userver/server/http/http_status.hpp>

namespace masterclasses::handlers {

StaticImageHandler::StaticImageHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context) {}

std::string StaticImageHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext&) const {
  std::string path = request.GetUrl();

  if (path.find("..") != std::string::npos) {
      throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"Invalid path"});
  }

  std::string prefix = "/static/images/";
  if (path.rfind(prefix, 0) != 0) {
       throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"Invalid path prefix"});
  }

  std::string filename = path.substr(prefix.length());
  if (filename.empty()) {
      throw userver::server::handlers::ClientError(
        userver::server::handlers::ExternalBody{"Filename missing"});
  }

  std::filesystem::path file_path = std::filesystem::current_path() / "static" / "images" / filename;

  if (!std::filesystem::exists(file_path)) {
      throw userver::server::handlers::ResourceNotFound(
          userver::server::handlers::ExternalBody{"File not found"});
  }

  std::string content_type = "application/octet-stream";
  if (filename.ends_with(".jpg") || filename.ends_with(".jpeg")) content_type = "image/jpeg";
  else if (filename.ends_with(".png")) content_type = "image/png";
  
  request.GetHttpResponse().SetContentType(content_type);

  std::ifstream f(file_path, std::ios::binary);
  if (!f.is_open()) {
       throw userver::server::handlers::InternalServerError(
          userver::server::handlers::ExternalBody{"Could not read file"});
  }
  
  std::string content((std::istreambuf_iterator<char>(f)),
                       std::istreambuf_iterator<char>());
  return content;
}

}  // namespace masterclasses::handlers

