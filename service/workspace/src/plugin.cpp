#include <boost/program_options.hpp>
#include <webserver/pluginhandler.h>
#include <webserver/requesthandler.h>
#include <webserver/servercontext.h>
#include <webserver/thrifthandler.h>
#include <workspaceservice/workspaceservice.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type-c-linkage"
extern "C"
{
  boost::program_options::options_description getOptions()
  {
    boost::program_options::options_description description("Workspace Plugin");

    return description;
  }

  void registerPlugin(
    const cc::webserver::ServerContext& context_,
    cc::webserver::PluginHandler<cc::webserver::RequestHandler>* pluginHandler_)
  {
    std::shared_ptr<cc::webserver::RequestHandler> handler(
      new cc::webserver::ThriftHandler<cc::service::workspace::WorkspaceServiceProcessor>(
        new cc::service::workspace::WorkspaceServiceHandler(
          context_.options["workspace"].as<std::string>())));

    pluginHandler_->registerImplementation("WorkspaceService", handler);
  }
}
#pragma clang diagnostic pop
