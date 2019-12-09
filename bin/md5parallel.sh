#!/usr/bin/env bash

WD=$1
NJOBS=$2
OUTFILE=$3

find $WD/ -type f -printf '%P\n' | parallel -j $NJOBS md5sum > $OUTFILE

