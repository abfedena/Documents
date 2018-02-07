#!/bin/bash
name1=`cat fiberIVY nagios info from PLAT pull.csv` | awk  -F ',' '{print $2}
echo $name1 
`cat 'fiberIVY nagios info from PLAT pull.csv' `| while read installion name 
 do
    installname=$(awk '{print $9}' -F ","fiberIVY nagios info from PLAT pull.csv")
    echo $installname >2.csv

done

