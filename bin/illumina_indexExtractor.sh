#!/usr/bin/env bash
FASTQ=$1
OUTDIR=$2
INDOUT=$(basename $FASTQ .gz).index
zcat $FASTQ | grep '^@' | cut -d : -f 10 | sort | uniq -c | sort -nr > $OUTDIR/$INDOUT
