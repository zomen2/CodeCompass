#ifndef CC_PARSER_METRICS_PARSER_H
#define CC_PARSER_METRICS_PARSER_H

#include <parser/abstractparser.h>
#include <parser/parsercontext.h>

#include <util/parserutil.h>

namespace cc
{
namespace parser
{

class MetricsParser : public AbstractParser
{
public:
  MetricsParser(ParserContext& ctx_);
  virtual std::vector<std::string> getDependentParsers() const override;  
  virtual bool parse() override;
  virtual bool preparse(bool dry_) override;

private:
  util::DirIterCallback getParserCallback();

  struct Loc
  {
    Loc() : originalLines(0), nonblankLines(0), codeLines(0) {}

    unsigned originalLines;
    unsigned nonblankLines;
    unsigned codeLines;
  };

  Loc getLocFromFile(model::FilePtr file_) const;

  void setCommentTypes(
    std::string& filetype_,
    std::string& singleComment_,
    std::string& multiCommentStart_,
    std::string& multiCommentEnd_) const;

  void eraseBlankLines(std::string& file) const;

  void eraseComments(
    std::string& file_,
    const std::string& singleComment_,
    const std::string& multiCommentStart_,
    const std::string& multiCommentEnd_) const;

  void persistLoc(const Loc& loc_, model::FileId file_);

  std::unordered_set<model::FileId> _fileIdCache;
  std::unique_ptr<util::JobQueueThreadPool<std::string>> _pool;
};

} // namespace parser
} // namespace cc

#endif // CC_PARSER_METRICS_PARSER_H
