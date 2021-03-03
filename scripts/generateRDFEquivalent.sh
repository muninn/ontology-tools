#!/bin/sh
#
for all in `rapper $1 | grep "http://www.w3.org/2002/07/owl#Class" | cut -d " " -f 1  | cut -d ">" -f 1 | cut -d "<" -f 2 | cut -d "#" -f 2 | sort | sort -u`
do 
echo "<rdf:Description rdf:about=\"#${all}\">"
echo " <rdf:type rdf:resource=\"http://www.w3.org/2000/01/rdf-schema#Class\"/>"
echo "</rdf:Description>"
done
