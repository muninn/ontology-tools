#!/bin/sh
#
MYTMP=`mktemp`
BUILDIT='$key="XXXXXXXXXX"'
xpath -e "//foaf:isPrimaryTopicOf/@rdf:resource" $1 2> /dev/null  | tr " " "\n" | cut -d "\"" -f 2 | tr -d "#" | sort | sort -u | grep -v "^$" > ${MYTMP}
xpath -e "//prov:hadPrimarySource/@rdf:resource" $1 2> /dev/null  | tr " " "\n" | cut -d "\"" -f 2 | tr -d "#" | sort | sort -u | grep -v "^$" >> ${MYTMP}
tr " " "\n" < $2 | grep -i "href=" | grep '#' | cut -d "#" -f 2- | cut -d '"' -f 1 | cut -d "'" -f 1 | sort -u | grep -v "^$" >> ${MYTMP}
for CITATION in `cat ${MYTMP} | sort | sort -u`
do
 BUILDIT=${BUILDIT}" or \$key=\"$CITATION\""
done
#echo ${BUILDIT}
bib2bib -c "${BUILDIT}" < $3
rm -f ${MYTMP}
