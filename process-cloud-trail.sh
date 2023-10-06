FILES=$(find . -type f -name \*json.gz)

for file in $FILES; do
    echo $file
    gzip -d -c $file | jq  -r '.Records[] | select(.userIdentity.accessKeyId=="AKIAIPZYWWF5KXXIXYTQ") | "\(.requestParameters.bucketName) \(.eventName)"' >> results.txt
done
sort results.txt | uniq -c | sort -nr


