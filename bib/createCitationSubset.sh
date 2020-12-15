#!/bin/sh
#
BUILDIT='$key="XXXXXXXXXX"'
for CITATION in `xpath -e "//prov:hadPrimarySource/@rdf:resource" $1 2> /dev/null  | tr " " "\n" | cut -d "\"" -f 2 | tr -d "#" | sort | sort -u | grep -v "^$"`
do
 BUILDIT=${BUILDIT}" or \$key=\"$CITATION\""
done
#echo ${BUILDIT}
bib2bib -c "${BUILDIT}" < $2
