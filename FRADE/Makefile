# Disclaimer: I don't have the slightest clue how make files work...

CFLAGS=-Wall -std=c++11 -g
CC=g++

all: rsyslog 

rsyslog: rsyslog.o
	$(CC) $(CFLAGS) -o rsyslog rsyslog.o FRADE.o UserData.o SemNode.o -lboost_regex 

rsyslog.o: rsyslog.cpp FRADE.o
	$(CC) $(CFLAGS) -c rsyslog.cpp

FRADE.o: FRADE.cpp UserData.o SemNode.o
	$(CC) $(CFLAGS) -c FRADE.cpp -lboost_regex

UserData.o: UserData.cpp
	$(CC) $(CFLAGS) -c UserData.cpp

SemNode.o: SemNode.cpp
	$(CC) $(CFLAGS) -c SemNode.cpp

clean:
	rm *.o
