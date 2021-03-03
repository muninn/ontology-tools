#!/bin/sh
#
for all in `rapper $1 | cut -d " " -f 1 | cut -d "<" -f 2 | cut -d ">" -f 1 | sort | sort -u`
do 
echo "<rdf:Description rdf:about=\"${all}\">"
outer=`echo ${all} | sed 's/https/http/g'`
echo " <owl:sameAs rdf:resource=\"${outer}\"/>"
echo "</rdf:Description>"
done
