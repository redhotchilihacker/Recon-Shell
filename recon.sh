#!/bin/bash
# Author: redhotchilihacker



export PATH=$PATH:/usr/local/go/bin



if [ $# -gt 2 ]; then

	echo "Usage: ./script.sh <domain>"

	echo "Example: ./script.sh hackerone.com"

	exit 1

fi 



if [ ! -d "$1" ]; then

	mkdir $1

fi



if [ ! -d "$1/thirdlevels" ]; then

	mkdir $1/thirdlevels

fi



if [ ! -d "$1/scans" ]; then

	mkdir $1/scans

fi



if [ ! -d "$1/thirdlevels/subfinder" ]; then

	mkdir $1/thirdlevels/subfinder

fi



if [ ! -d "$1/thirdlevels/assetfinder" ]; then

	mkdir $1/thirdlevels/assetfinder

fi



pwd=$(pwd)



echo

echo "Gathering subdomains with Sublist3r"

echo



python3 ~/Tools/Sublist3r/sublist3r.py -d $1 -o $1/sublist3r.txt

echo $1 >> $1/sublist3r.txt



echo

echo "Gathering subdomains with Subfinder"

echo



subfinder -d $1 -o $1/subfinder.txt



echo

echo "Gathering subdomains with Assetfinder"

echo



assetfinder $1 -subs-only  | tee -a $1/assetfinder.txt



echo

echo "Gathering subdomains with Amass"

echo



amass enum -passive -d $1 -o $1/amass.txt



echo

echo "Gathering subdomains with Crt.sh"

echo



curl -s https://crt.sh/?q=%25.$1 | grep "$1" | grep "<TD>" | cut -d">" -f2 | cut -d"<" -f1 | sort -u | sed s/*.//g > $1/crtsh.txt

cat $1/crtsh.txt



echo

echo "Compiling third-level domains"

echo



cat $1/sublist3r.txt >> $1/trash.txt

cat $1/assetfinder.txt >> $1/trash.txt

cat $1/amass.txt >> $1/trash.txt

cat $1/subfinder.txt >> $1/trash.txt

cat $1/crtsh.txt >> $1/trash.txt

sort -u $1/trash.txt | sed 's/\*.//' | sed 's/BR/\n/g' | grep ${1} >> $1/all_subdomains.txt

cat $1/all_subdomains.txt | grep -Po "(\w+\.\w+\.\w+)$" | sort -u >>  $1/third-level.txt



for domain in $(cat $1/third-level.txt);

do subfinder -d $domain -o $1/thirdlevels/subfinder/$domain.txt; cat $1/thirdlevels/subfinder/$domain.txt | sort -u >> $1/all_subdomains.txt;done



for domain in $(cat $1/third-level.txt);

do assetfinder $domain >> $1/thirdlevels/assetfinder/$domain.txt; cat $1/thirdlevels/assetfinder/$domain.txt | sort -u >> $1/all_subdomains.txt;done



cat $1/all_subdomains.txt | sort -u | grep ${1} >> $1/final_subdomains.txt



echo

echo "Passing subdomains to Httpx"

echo



httpx -l $1/final_subdomains.txt -o $1/httpx_statuscodes.txt -status-code -no-color

sed 's/......$//' $1/httpx_statuscodes.txt >> $1/httpx_clean.txt



echo

echo "Passing subdomains to Httprobe"

echo



cat $1/final_subdomains.txt | httprobe -c 5 >> $1/httprobe_results.txt



echo

echo "Checking for subdomain takeover"

echo



subjack -w $1/final_subdomains.txt -o $1/subdomain_takeover.txt -c ~/go/pkg/mod/github.com/haccer/subjack@v0.0.0-20201112041112-49c51e57deab/fingerprints.json



echo

echo "Identifying technologies"

echo



nuclei -l $1/httpx_clean.txt -t ~/Tools/nuclei-templates/technologies/ -o $1/technologies.txt -silent



echo

echo "Taking Screenshots with Aquatone"

echo



cat $1/httpx_clean.txt | ~/Tools/aquatone -chrome-path /usr/bin/chromium -out $1/aquatone -threads 1





rm $1/trash.txt

rm $1/all_subdomains.txt

mv $1/amass.txt $1/scans

mv $1/assetfinder.txt $1/scans

mv $1/sublist3r.txt $1/scans

mv $1/subfinder.txt $1/scans

mv $1/crtsh.txt $1/scans

mv $1/third-level.txt $1/thirdlevels

