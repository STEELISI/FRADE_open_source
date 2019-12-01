times=[1000,10000,60000,300000,600000]
d={}

with open("xx", "r") as ins:
    array = []
    for line in ins:
        vals = line.split()
        #print(vals[0], vals[1], vals[2], vals[3])
        if(len(vals) == 4):
            if(vals[0] not in d):
                d[vals[0]] = [1]*6
            if(vals[3] == "1000" and int(vals[1]) > d[vals[0]][0]):
                d[vals[0]][0] = int(vals[1])

            if(vals[3] == "10000" and int(vals[1]) > d[vals[0]][1]):
                d[vals[0]][1] = int(vals[1])

            if(vals[3] == "60000" and int(vals[1]) > d[vals[0]][2]):
                d[vals[0]][2] = int(vals[1])

            if(vals[3] == "300000" and int(vals[1]) > d[vals[0]][3]):
                d[vals[0]][3] = int(vals[1])

            if(vals[3] == "600000" and int(vals[1]) > d[vals[0]][4]):
                d[vals[0]][4] = int(vals[1])

                
            #d[vals[3]].append(int(vals[1]))

for k,v in d.items():
    print(v)
                
            

