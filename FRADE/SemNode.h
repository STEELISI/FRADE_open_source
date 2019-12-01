#include <string>
#include <unordered_map>

using namespace std;

class SemNode;

struct Edge {
  double prob;
  SemNode *end;
};

class SemNode {
public:

  SemNode(string uri) { this->uri = uri; }
  void addEdge(float prob, SemNode *end);
  /**
    Checks if this node has an edge to the node represtend by the uri pointed to by
    end. If it does, return the probability. If not, return 0.
  */
  double transTo(string *end, SemNode **endNode);

  string uri; 
private:
  unordered_map<string, Edge*> edges;
};
