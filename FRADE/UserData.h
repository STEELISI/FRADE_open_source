#include <string>
#include "SemNode.h"
#include <vector>

using namespace std;

class UserData {
public:

  UserData(unsigned int ip, long time, string *requestedFile, int numWindows, double proctime, vector<string> vembd);

  unsigned int ip;
  // Semantic data
  double seqProb;
  string *prevFile;
  // We save a pointer to the end node each time we
  // lookup a transition to avoid looking it up again
  // when we do the next transition
  // save a lookup. NULL if this should not be used
  SemNode *endNode;
  unsigned int seqLength;
  double proc_time;
  double avg_time;  



  // Dynamics 1 and 3 data
 unsigned int counts[20];// unsigned int *counts;
 double procs[20];// unsigned long *procs; //contains processing times sum
 unsigned long times[20];// unsigned long *times;
  

  //Dynamics 2 data
  unsigned int embedcounts[20];//unsigned int *embedcounts;
  unsigned long embedtimes[20];//unsigned long *embedtimes;
  unsigned long lasttime; // To identify out of order request
  string current_main;
  vector<string> current_list; 
  int max_allowed;

};
