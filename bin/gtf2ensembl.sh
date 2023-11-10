#!/usr/bin/env bash

############################################################################################################################
# Usage for the script
############################################################################################################################
usage()
{
printf "Usage:
\t `basename $0` [FLAGS]

Description:
\t Create ENSEMBL IDs from GTF file. Output columns: gene, transcript, exon, gene name

Examples:
\t `basename $0` -i myfile.gtf -o myfile.txt

Flags:
\t [-i <input_file>]                       Input "gtf" file. Can be gzipped (.gtf.gz)
\t [-o <output_file>]                      Output file, tab-delimitted
\t [-g <gzip_file>]                        Flag to gzip the output file
\t [-h <help>]                             Print help

Dependencies:
\t bedops --> convert2bed
"
}

exit_abnormal() {       # Function: Exit with error.
  #printf $USAGE
  exit 1
}

die(){ echo >&2 "$@"; exit 1; }

unset -v OUTFILE 
############################################################################################################################
# getopts
############################################################################################################################
while getopts ':i:o:gvh' flag; do	
        case "${flag}" in
                i) INFILE=${OPTARG}
                                   if [[ -f $INFILE ]]; then
                                        #echo "Input file: $INFILE"
					:
                                   else
                                        echo "ERROR: cannot find input file [-i]"
					echo " "
					usage; exit_abnormal
                                   fi
                                   ;;
                o) OUTFILE=${OPTARG} 
			;;
		g) GZFILE=TRUE 
			           if [[ -z "$INFILE" && -z "$OUTFILE" ]]; then
                                        echo "ERROR: -i and -o are required to activate this option"
                                        echo " "
                                        usage; exit_abnormal
                                   else
					:
                                   fi
			;;
                v) VERBOSE=TRUE 
			           if [[ -z "$INFILE" && -z "$OUTFILE" ]]; then
                                        echo "ERROR: -i and -o are required to activate this option"
                                        echo " "
                                        usage; exit_abnormal
                                   else
					:
                                   fi
			;;
                h) usage ; exit_abnormal ;;
	        :) echo "ERROR: argument required for -$OPTARG" 
		   echo " " 
		   usage; exit_abnormal ;;
        	*) echo "ERROR: invalid switch -$OPTARG" 
		   echo " "
		   usage; exit_abnormal ;;
	esac
done

if [[ -z "$OUTFILE" ]]; then
	echo "ERROR: argument required for -o"
        echo " "
        usage; exit_abnormal
fi

if [ $OPTIND -eq 1 ]; then 
	usage; exit 1
fi

shift $((OPTIND-1))

############################################################################################################################
# Print input
############################################################################################################################
if [ "$VERBOSE" == TRUE ]; then
	echo "------------------------"
	echo "Input parameters"
	echo "------------------------"
	echo "[-i]      INFILE        : $INFILE"
	if [ "$GZFILE" == TRUE ]; then
		echo "[-o]      OUTFILE       : $OUTFILE.gz"
	else
	        echo "[-o]      OUTFILE       : $OUTFILE"
	fi
	echo "[-g]      GZFILE        : $GZFILE"
	echo "------------------------"
fi

############################################################################################################################
# Do the job
############################################################################################################################
paste \
	<(zcat -f $INFILE | awk '$3=="exon"' | convert2bed -d -i gtf --attribute-key="gene_id"       | cut -f4) \
        <(zcat -f $INFILE | awk '$3=="exon"' | convert2bed -d -i gtf --attribute-key="transcript_id" | cut -f4) \
        <(zcat -f $INFILE | awk '$3=="exon"' | convert2bed -d -i gtf --attribute-key="exon_id"       | cut -f4) \
        <(zcat -f $INFILE | awk '$3=="exon"' | convert2bed -d -i gtf --attribute-key="gene_name"     | cut -f4) \
        | sort -k1,1 -k2,2 -k3,3 \
	| uniq \
	> $OUTFILE

if [ "$GZFILE" == TRUE ]; then
        gzip $OUTFILE
fi
