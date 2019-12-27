#ifndef CC_SERVICE_SERVICEPROCESS_H
#define CC_SERVICE_SERVICEPROCESS_H

#include <memory>
#include <string>
#include <vector>

#include <thrift/Thrift.h>

#include <util/pipedprocess.h>

#include <SearchService.h>

namespace cc
{
namespace service
{
namespace search
{

class ServiceProcess : public SearchServiceIf, public util::PipedProcess
{
public:
  class ProcessDied : public apache::thrift::TException
  {
  public:
    ProcessDied() : apache::thrift::TException("Service process died!") {};
  };

  /**
   * Opens the service process.
   *
   * @param indexDatabase_ path to a index database
   */
  ServiceProcess(const std::string& indexDatabase_,
                 const std::string& compassRoot_);

  ~ServiceProcess() override;

public:
  void search(
    SearchResult& _return,
    const SearchParams& params_) override;

  void searchFile(
    FileSearchResult& _return,
    const SearchParams& params_) override;

  void getSearchTypes(
    std::vector<SearchType>& _return) override;

  void pleaseStop() override;

  void suggest(SearchSuggestions& _return,
    const SearchSuggestionParams& params_) override;

private:
  /**
   * Throws a thrift exception if the service process is dead.
   *
   * @throw apache::thrift::TException
   */
  void checkProcess();

  /**
   * Creates the client interface.
   */
  void getClientInterface();

private:
  /**
   * Path to a index database;
   */
  const std::string _indexDatabase;

  /**
   * Service interface for IPC communication.
   */
  std::unique_ptr<SearchServiceIf> _service;

  /**
   * Second pipe.
   */
  int _pipeFd2[2];
};

} // search
} // service
} // cc

#endif // CC_SERVICE_SERVICEPROCESS_H
