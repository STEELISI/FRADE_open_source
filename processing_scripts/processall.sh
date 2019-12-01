for FILE in `ls /mnt/argus.*` ; do
    NAME=`echo "$FILE" | cut -d'/' -f3`
    SERVER=`echo "$NAME"| sed -e 's/argus\.//' -`
    perl processargus.pl $FILE > /mnt/stats.$SERVER
done
