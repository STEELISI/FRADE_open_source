#include "UserData.h"
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <boost/regex.hpp>
#include <vector>
#include <fstream>
using namespace std;

/** 
  Not necessary anymore because we aren't using a pair of strings as a hash key. Still might be useful at some point in the future though, so I'm leaving it here.
struct TransHash {
    template <class T1, class T2>
    std::size_t operator () (const std::pair<T1,T2> &p) const {
        size_t h1 = std::hash<T1>{}(p.first);
        size_t h2 = std::hash<T2>{}(p.second);

	// Taken from: http://stackoverflow.com/questions/2590677/how-do-i-combine-hash-values-in-c0x
        // This is supposedly a good way to combine two hash values
	return h1 + 0x9e3779b9 + (h2<<6) + (h2>>2);
    }
};
*/

class FRADE {
public:
  FRADE();
  FRADE(string config_file, int modules = 15);
  void configure(string config_file, int modules = 15);
  bool semantics(UserData *ud, string *requestedFile);
  //OLD:: bool dynamics1and3(UserData *ud, unsigned long reqTime, long proctime);
  //OLD:: bool dynamics2(UserData *ud, unsigned long reqTime);
  //Not used anymore as we combined it with dyn1:: bool dynamics3(UserData *ud, unsigned long reqTime, long proctime);

  bool dynamics1and3(UserData *ud, unsigned long reqTime, string *requestedFile);
  bool dynamics2(UserData *ud, unsigned long reqTime, string *requestedFile);
  bool deception(UserData *ud, string *uri);

  void blacklistIP(unsigned int userIP);
  void beAFRADE(unsigned int userIP, long reqTime, string *requestedFile);
  void dumpData();

private:
  // Helper functions
  double getTransitionProb(UserData *ud, string *end);
  double getTransitionProb2(UserData *ud, string *end);
  double getSequenceThreshold(int seqLength);
  bool isMainRequest(string *uri);
  int hasFolder(string *uri);
  string blacklistpipe;
  ofstream pipe;
  int activemodules;  

  unordered_map<string, SemNode*> semNodes;
  unordered_map<unsigned int, UserData*> users;
  unordered_set<unsigned int> blacklist;
  unordered_map<string, vector<string> > main_embed; // used in dyn2: mapping between main and its embedded object requests 
  unordered_map<string, double> proc_time; //used in dyn3: mapping between main request and its processing time
  unordered_map<string, int> dummy_links;

  // Semantics
  // It would be more accurate to call NO_FILE_PROB -> NO_TRANS_PROB, but I don't feel
  // like changing it now
  double NO_FILE_PROB;
  double *seqThreshes;
  int maxSeqLen;
  int numWindows;
  // null-terminated arrays
  boost::regex **folders;
  boost::regex **mainReqs;
  // Dynamics
  unsigned int *windows;
  unsigned int *dyn1Threshes;
  unsigned int *dyn2Threshes;
  unsigned int *dyn3Threshes;
  unordered_map<string,string> groups;
};
