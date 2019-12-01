ifconfig | grep inet | grep 10\.2\. | awk -F":" '{print $2}' | awk '{print $1}' 
