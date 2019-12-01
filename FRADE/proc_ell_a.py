times=['1000','10000','60000','300000','600000']
arr=[]
done=[]
flag=0

with open("/proj/FRADE/xxxx", "r") as ins:
    for line in ins:
        vals = line.split()
        if(len(vals) == 4):
            if(vals[3] ==times[4]):
                if(flag==0):
                    ctr=0
                    #for i in range(1,int(vals[1])):
                    v=int(vals[1])
                    arr.append([1,int(v/60)+1,int(v/10)+1,int(v/2)+1,int(vals[1]),1])
                    print(arr[ctr])
                    ctr = ctr + 1
                else:
                    for i in range(0,len(arr)):
                        if(arr[i][4] < arr[i][3] and arr[i][4] == 1):
                            arr[i][4] = int(vals[1])
                        print(arr[i])
                arr[:] = []
                flag = 0

            elif(vals[3] ==times[3]):
                if(flag==0):
                    #for i in range(1,int(vals[1])):
                    arr.append([1,1,1,int(vals[1]),1,1])
                else:
                    for i in range(0,len(arr)):
                        if(arr[i][3] < arr[i][2] and arr[i][3] == 1):
                            arr[i][3] = int(vals[1])
                flag = 4
                    
                
            elif(vals[3] ==times[2]):
                if(flag==0):
                    #for i in range(1,int(vals[1])):
                    arr.append([1,1,int(vals[1]),1,1,1])
                else:
                    for i in range(0,len(arr)):
                        if(arr[i][2] < arr[i][1] and arr[i][2] == 1):
                            arr[i][2] = int(vals[1])
                flag = 3



            elif(vals[3] ==times[1]):
                if(flag==0):
                    #for i in range(1,int(vals[1])):
                    arr.append([1,int(vals[1]),1,1,1,1])
                else:
                    for i in range(0,len(arr)):
                        if(arr[i][1] < arr[i][0] and arr[i][1] == 1):
                            arr[i][1] = int(vals[1])
                flag = 2
            elif(vals[3] ==times[0]):
                arr.append([int(vals[1]),1,1,1,1,1])
                flag=1
                    
            
                
            

