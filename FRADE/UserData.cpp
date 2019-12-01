#include <string>
#include <iostream>
#include "UserData.h"
#include <vector>
using namespace std;

UserData::UserData(unsigned int ip, long time, string *requestedFile, int num_windows, double proctime, vector<string> vembd) {
  this->ip = ip;
  seqProb = 1;
  seqLength = 1;
  proc_time=0.0;
  avg_time=0.0;

/*  counts = (unsigned int*) malloc(sizeof(unsigned int)*num_windows);
  procs = (unsigned long*) malloc(sizeof(unsigned int)*num_windows);
  times = (unsigned long*) malloc(sizeof(unsigned long)*num_windows);
  embedcounts = (unsigned int*) malloc(sizeof(unsigned int)*num_windows);
  embedtimes = (unsigned long*) malloc(sizeof(unsigned long)*num_windows);*/

  if(requestedFile != NULL){
      for (int i = 0; i < num_windows; i++){
      counts[i] = 1;
      procs[i] = proctime;
      embedcounts[i] = 0;
      times[i] = time;
      embedtimes[i] = 0;
      current_main = *requestedFile;
    }
  }
  else{
      for (int i = 0; i < num_windows; i++){
      counts[i] = 0;
      procs[i] = 0;
      embedcounts[i] = 1;
      times[i] = 0;
      embedtimes[i] = time;
      current_main = "";
    }
  }
  max_allowed = 0;
  current_list = vembd;
  prevFile = requestedFile;
  endNode = NULL;
}
