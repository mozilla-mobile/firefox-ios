#!/usr/bin/bas
filename="newest_tag.txt"
while read -r line; do
    name="$line"
done < "$filename"
echo $name
