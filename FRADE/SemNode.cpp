#include <utility>
#include "SemNode.h"
#include <iostream>

using namespace std;

void SemNode::addEdge(float prob, SemNode *end) {
  if (edges.count(end->uri) != 0) {
    cerr << "Error adding transition from " << uri << " to " << end->uri << endl;
    cerr << "transition already exists. Transition will not be updated" << endl;
    return;
  }
  Edge *e = new Edge;
  e->prob = prob;
  e->end = end;
  edges.insert(make_pair(end->uri, e));
}


double SemNode::transTo(string *end, SemNode **endNode) {
  Edge *e;
  try {
    e = edges.at(*end);
    *endNode = e->end;
    return e->prob;
  } catch (const out_of_range e) {
    *endNode = NULL;
    return 0;
  }

}
