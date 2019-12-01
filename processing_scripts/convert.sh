for FILE in `ls /mnt/log.*` ; do
    echo $FILE
    NAME=`echo "$FILE" | cut -d'/' -f3`
    SERVER=`echo "$NAME"| sed -e 's/log\.//' -`
    rm /mnt/out /mnt/tmp
    editcap $FILE /mnt/out
    editcap -s 68 /mnt/out /mnt/tmp
    rm /mnt/argus.$SERVER
    argus -r /mnt/tmp -w /mnt/argus.$SERVER
done
