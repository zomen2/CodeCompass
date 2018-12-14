#ifndef CC_PARSER_SOURCEMANAGER_H
#define CC_PARSER_SOURCEMANAGER_H

#include <memory>
#include <mutex>
#include <string>
#include <map>
#include <unordered_set>

#include <magic.h>

#include <model/file.h>
#include <model/file-odb.hxx>
#include <model/filecontent.h>

#include <util/odbtransaction.h>

namespace cc
{
namespace parser
{

class SourceManager
{
public:
  SourceManager(std::shared_ptr<odb::database> db_);
  SourceManager(const SourceManager&) = delete;
  ~SourceManager();

  struct AllFilesFilter
  {
    bool operator()(model::FilePtr file_) const { return true; }
  };

  template<typename Filter = SourceManager::AllFilesFilter>
  std::vector<model::FilePtr> getFiles(const Filter& beta_ = Filter())
  {
    std::vector<model::FilePtr> files;

    for (const auto& p: _files)
      if (beta_(p.second))
        files.push_back(p.second);

    return files;
  }

  /**
   * This function returns a pointer to the corresponding model::File object
   * based on the given path_. The object is read from a cache. If the file is
   * not in the cache yet then a model::File entry is created, persisted in the
   * database and placed in the cache. If the file doesn't exist then it returns
   * nullptr.
   */
  model::FilePtr getFile(const std::string& path_);

  /**
   * This function updates the file given as parameter. Note that the file
   * content is read-only, so it can't be changed.
   * @param file_ A model::File object which is already persistent. The file
   * content won't change even if the corresponding attribute is modified.
   */
  void updateFile(const model::File& file_);

  /**
   * This function returns true if the given file is a plain text file.
   */
  bool isPlainText(const std::string& path_) const;

  // TODO: Maybe this function shouldn't exist.
  void persistFiles();

  /**
   * This function removes the given file (and its content if necessary)
   * from the SourceManager and also deletes it from the database.
   * @param file_ A model::File object which is already persistent.
   */
  void removeFile(const model::File& file_);

private:
  /**
   * This function creates a model::FileContent object and fills its attributes
   * based on the given path.
   *
   * @pre The function can only be invoked for regular text files of which the
   * content can be read.
   * @return Returns nullptr if the file can't be opened for read. Otherwise
   * returns a model::FileContentPtr which points to a model::FileContent object
   * that contains the file content.
   */
  model::FileContentPtr createFileContent(const std::string& path_) const;

  /**
   * This function creates a model::File object and fills its attributes based
   * on the given path. The "content" attribute is also set if the path_ refers
   * to a regular test file (see: withContent_).
   *
   * @param withContent_ If set to false then "content" attribute will not be
   * set.
   */
  model::FilePtr getCreateFileEntry(
    const std::string& path_,
    bool withContent_ = true);

  /**
   * This function returns the parent model::File object of the given path from
   * cache. If the parent directory can't be found in the cache then it is
   * persisted to the database and placed to the cache. If the path_ is the root
   * directory then the function returns nullptr.
   */
  model::FilePtr getCreateParent(const std::string& path_);

  std::shared_ptr<odb::database> _db;
  util::OdbTransaction _transaction;
  std::map<std::string, model::FilePtr> _files;
  std::unordered_set<model::FileId> _persistedFiles;
  std::unordered_set<std::string> _persistedContents;
  std::mutex _createFileMutex;
  ::magic_t _magicCookie;
};

} // parser
} // cc

#endif // CC_PARSER_SOURCEMANAGER_H
