#!/bin/bash

echo "Hello, "$USER". This script will find the 'fastq.gz.temp' files."
echo -n "Type the directory where the search will be performed and press [ENTER]: "
read dir
echo -n "Type where to save the report and press [ENTER]: "
read out

find $dir -name "*.fastq.gz.temp" -type f > $out/fastq.gz.temp.txt


