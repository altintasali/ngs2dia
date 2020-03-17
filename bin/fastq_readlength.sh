#!/usr/bin/env bash
FASTQ=$1
#parallel "awk '{if(NR%4==2) {count++; bases += length} } END{print bases/count}' {}" ::: $(ls *.fastq.gz)
zcat $1 | awk '{if(NR%4==2) {count++; bases += length} } END{print bases/count}'
