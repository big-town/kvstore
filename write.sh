#!/bin/bash

echo -e "\nInit\n"
for key in `seq 1 1000` 
do
    url="http://localhost:4040/create?key=key$key&value=$key&ttl=60"
    curl -X POST  $url
done
