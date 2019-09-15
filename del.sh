#!/bin/bash


echo -e "\nDelete\n"
for key in `seq 1 1000` 
do
    url="http://localhost:4040/delete?key=key$key"
    curl -X DELETE $url
done

