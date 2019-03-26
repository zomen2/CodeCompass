#include <util/versionhandling.h>

#if INTEGER_VERSION(THRIFT_MAJOR_VERSION, THRIFT_MINOR_VERSION, \
                    THRIFT_PATCH_LEVEL) <= INTEGER_VERSION(0, 10, 0)
#include <boost/shared_ptr.hpp>
#endif

#include <memory>
#include <string>
#include <vector>

#include <thrift/transport/TFDTransport.h>
#include <thrift/protocol/TBinaryProtocol.h>

#include <util/logutil.h>

#include <service/serviceprocess.h>

namespace cc
{
namespace service
{
namespace search
{

ServiceProcess::ServiceProcess(const std::string& indexDatabase_,
    const std::string& compassRoot_) :
    _indexDatabase(indexDatabase_)
  {
    openPipe(_pipeFd2[0], _pipeFd2[1]);

    int pid = startProcess();
    if (pid == 0)
    {
      std::string inFd(std::to_string(_pipeFd[0]));
      std::string outFd(std::to_string(_pipeFd2[1]));

      std::string logLevelOpt("-Dcc.search.logLevel=");
      auto fmtSeverity = util::getSeverityLevel();

      if(fmtSeverity == boost::log::trivial::info)
        logLevelOpt += "INFO";
      else if(fmtSeverity == boost::log::trivial::error ||
              fmtSeverity == boost::log::trivial::warning)
        logLevelOpt += "WARNING";
      else if(fmtSeverity == boost::log::trivial::fatal)
        logLevelOpt += "SEVERE";
      else
        logLevelOpt += "ALL";

      std::string classpath = compassRoot_ + "/lib/java/*";

      ::execlp("java", "java", "-server",
        "-classpath", classpath.c_str(),
        //"-Xdebug", "-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8666",
        "-Djava.util.logging.config.class=cc.search.common.config.LogConfigurator",
        "-Djava.util.logging.SimpleFormatter.format=[%4$s] %5$s%6$s%n",
        logLevelOpt.c_str(),
        "cc.search.service.app.service.ServiceApp",
        "-indexDB", _indexDatabase.c_str(),
        "-ipcInFd", inFd.c_str(),
        "-ipcOutFd", outFd.c_str(),
        "-useSimpleFileLock",
        "-cleanupLocks",
        nullptr);

      LOG(error) << "execlp failed!";

      // This shouldn't be executed by child process
      ::abort();
    }
    else
    {
      getClientInterface();
    }
  }

ServiceProcess::~ServiceProcess()
{
    try
    {
      pleaseStop();
    }
    catch (const ProcessDied&)
    {
    }
    catch (...)
    {
      LOG(warning) << "'pleaseStop' failed!";
    }

    _service.reset(nullptr);

    closePipe(_pipeFd2[0], _pipeFd2[1]);
}

void ServiceProcess::search(
    SearchResult& _return,
    const SearchParams& params_)
{
    checkProcess();
    _service->search(_return, params_);
}

void ServiceProcess::searchFile(
    FileSearchResult& _return,
    const SearchParams& params_)
{
    checkProcess();
    _service->searchFile(_return, params_);
}

void ServiceProcess::getSearchTypes(
    std::vector<SearchType>& _return)
{
    checkProcess();
    _service->getSearchTypes(_return);
}

void ServiceProcess::pleaseStop()
{
    checkProcess();
    _service->pleaseStop();
}

void ServiceProcess::suggest(SearchSuggestions& _return,
    const SearchSuggestionParams& params_)
{
    checkProcess();
    _service->suggest(_return, params_);
}

void ServiceProcess::checkProcess()
{
    if (!isAlive())
    {
      throw ProcessDied();
    }
}

#if INTEGER_VERSION(THRIFT_MAJOR_VERSION, THRIFT_MINOR_VERSION, \
                    THRIFT_PATCH_LEVEL) > INTEGER_VERSION(0, 10, 0)
    template <typename T>
    using shared_ptr_type = std::shared_ptr<T>;
#else
    template <typename T>
    using shared_ptr_type = boost::shared_ptr<T>;
#endif

void ServiceProcess::getClientInterface()
{
    using Transport = apache::thrift::transport::TFDTransport;
    using ProtocolFactory =
      apache::thrift::protocol::TBinaryProtocolFactoryT<Transport>;

    shared_ptr_type<apache::thrift::transport::TTransport> transIn(
      new Transport(_pipeFd2[0], Transport::NO_CLOSE_ON_DESTROY));
    shared_ptr_type<apache::thrift::transport::TTransport> transOut(
      new Transport(_pipeFd[1], Transport::NO_CLOSE_ON_DESTROY));

    ProtocolFactory protFactory;

    _service.reset(new SearchServiceClient(
      protFactory.getProtocol(transIn),
      protFactory.getProtocol(transOut)));
}

} // search
} // service
} // cc

