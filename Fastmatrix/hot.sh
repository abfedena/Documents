 while IFS=',' read name loc 
  do 
  echo $lo
  user=$(echo $name | cut -d , f 9})
  myname=$(echo $loc | awk -F ',' '{print $2'})
  echo $user; 
  echo $myname
 done <home1.csv
