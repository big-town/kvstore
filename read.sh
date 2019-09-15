#!/bin/bash


echo -e "\nRead\n"
for key in `seq 1 1000` 
do
    url="http://localhost:4040/read?key=key$key"
    curl -X GET $url
done
