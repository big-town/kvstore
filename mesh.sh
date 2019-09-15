#!/bin/bash

echo -e "\nInit\n"
for key in `seq 1 100` 
do
    url="http://localhost:4040/create?key=key$key&value=$key&ttl=60"
    curl -X POST  $url
done

echo -e "\nRead\n"
for key in `seq 1 100` 
do
    url="http://localhost:4040/read?key=key$key"
    curl -X GET $url
done

echo -e "\nRange mul 2\n"
for key in `seq 1 100` 
do
    let val=key*2
    url="http://localhost:4040/update?key=key$key&value=$val&ttl=60"
    curl -X PUT $url
done

echo -e "\nRead again\n"
for key in `seq 1 100` 
do
    url="http://localhost:4040/read?key=key$key"
    curl -X GET $url
done

echo -e "\nDelete\n"
for key in `seq 1 100` 
do
    url="http://localhost:4040/delete?key=key$key"
    curl -X DELETE $url
done

echo -e "\nRead after delete\n"
for key in `seq 1 100` 
do
    url="http://localhost:4040/read?key=key$key"
    curl -X GET $url
done

echo -e "\nCreate with ttl=1\n"
for key in `seq 1 100` 
do
    url="http://localhost:4040/create?key=key$key&value=$key&ttl=1"
    curl -X POST $url
done

sleep 2
echo -e "\nRead expire ttl\n"
for key in `seq 1 100` 
do
    url="http://localhost:4040/read?key=key$key"
    curl -X GET $url
done
