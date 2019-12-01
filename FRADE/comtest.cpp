#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
using namespace std;
std::string exec(const char* cmd) {
    char buffer[128];
    std::string result = "";
    std::shared_ptr<FILE> pipe(popen(cmd, "r"), pclose);
    if (!pipe) throw std::runtime_error("popen() failed!");
    while (!feof(pipe.get())) {
        if (fgets(buffer, 128, pipe.get()) != NULL)
            result += buffer;
    }
    return result;
}


int main(){
string file = "";
const char* cmd = "ls -l /var/log/";
file = exec(cmd);
cout << file;


return 0;
}