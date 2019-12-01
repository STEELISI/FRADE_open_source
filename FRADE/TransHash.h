#include <unordered_map>
#include <functional>
#include <string>
#include <utility>

using namespace std;
// Only for pairs of std::hash-able types for simplicity.
// You can of course template this struct to allow other hash functions
struct TransHash {
    template <class T1, class T2>
    std::size_t operator () (const std::pair<T1,T2> &p) const {
        size_t h1 = std::hash<T1>{}(p.first);
        size_t h2 = std::hash<T2>{}(p.second);

	// Taken from: http://stackoverflow.com/questions/2590677/how-do-i-combine-hash-values-in-c0x
	return h1 + 0x9e3779b9 + (h2<<6) + (h2>>2);
    }
};
