#!/usr/bin/env bash

############################################################################################################################
# Usage for the script
############################################################################################################################
USAGE="Usage: `basename $0` [FLAGS]

Examples:
cov2bedGraph -i myfile.cov -o myfile.bedgraph 
cov2bedGraph -i myfile.cov -g -o myfile.bedgraph.gz

Flags:
\t [-i <input_file>]                       Input "cov" file. Can be gzipped (.cov.gz). [1-based coord]
\t [-o <output_file>]                      Output "bedGrapgh" file
\t [-z <zero_based>]                       Flag if input cov file is in 0-based genomic coordinate. Normally cov files are 1-based, but it can be 0-based in special occasions.
\t [-g <gzip_file>]                        Flag to gzip the output file
"

exit_abnormal() {       # Function: Exit with error.
  #printf $USAGE
  exit 1
}

############################################################################################################################
# getopts
############################################################################################################################
while getopts 'i:o:gzh' flag; do
        case "${flag}" in
                i) INFILE=${OPTARG}
                                   if [[ -f $INFILE ]]; then
                                        #echo "Input file: $INFILE"
					:
                                   else
                                        echo "ERROR: Cannot find input file [-i]"
                                        exit_abnormal
                                   fi
                                   ;;
                o) OUTFILE=${OPTARG} ;;
		g) GZFILE=TRUE ;;
		z) ZEROBASE=TRUE ;;
                h | *) printf "$USAGE" 1>&2 ; exit 1 ;;
	esac
done
shift $((OPTIND-1))

############################################################################################################################
# Print input
############################################################################################################################
echo "------------------------"
echo "Input parameters"
echo "------------------------"
echo "[-i]      INFILE        : $INFILE"
echo "[-o]      OUTFILE       : $OUTFILE"
echo "[-g]      GZFILE        : $GZFILE"
echo "[-z]      ZEROBASE      : $ZEROBASE"
echo "------------------------"

############################################################################################################################
# Do the job
############################################################################################################################
if [ "$ZEROBASE" == TRUE ]; then
	base_subtract=0
else
	base_subtract=1
fi

echo $base_subtract

if (file $INFILE | grep -q compressed ) ; then
        if [ "$GZFILE" == TRUE ]; then
               zcat $INFILE | awk -v SUBTRACT="$base_subtract" '{print $1"\t"($2-SUBTRACT)"\t"$3"\t"$4}' | awk 'BEGIN{print "type=bedGraph"}1' | gzip -c > $OUTFILE
        else
               zcat $INFILE | awk -v SUBTRACT="$base_subtract" '{print $1"\t"($2-SUBTRACT)"\t"$3"\t"$4}' | awk 'BEGIN{print "type=bedGraph"}1' > $OUTFILE
        fi
else
        if [ "$GZFILE" == TRUE ]; then
	       cat $INFILE | awk -v SUBTRACT="$base_subtract" '{print $1"\t"($2-SUBTRACT)"\t"$3"\t"$4}' | awk 'BEGIN{print "type=bedGraph"}1' | gzip -c > $OUTFILE
        else
	       cat $INFILE | awk -v SUBTRACT="$base_subtract" '{print $1"\t"($2-SUBTRACT)"\t"$3"\t"$4}' | awk 'BEGIN{print "type=bedGraph"}1' > $OUTFILE
        fi
fi

