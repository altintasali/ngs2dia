#!/usr/bin/env bash

############################################################################################################################
# Usage for the script
############################################################################################################################
USAGE="Usage: `basename $0` [FLAGS]
\t [-w <working_directory>]                Working directory where the MD5SUMS will be checked [default=.]
\t [-n <n_jobs>]                           Number of parallel jobs [default=1]
\t [-o <output_file>]                      Output filename [default=./md5.txt]
\t [-g <gzip_file>]                        Flag to gzip the output file
\t [-r <remove_working_directory_prefix]   Flag for removing the working directory prefix in MD5SUM output file
\t [-c <md5sum_check_file>]		   Activates md5sum check (md5sum -c [FILENAME] when MD5SUM output file provided)
					   An outfile file with CHECKSUM status. File extension will be '.check' [default=./md5.txt.check]
"

exit_abnormal() {       # Function: Exit with error.
  #printf $USAGE
  exit 1
}

linkread(){     # Function: preserve readlink behaviour for MacOS as well
        if [[ "$OSTYPE" == "linux-gnu" ]]; then
                # Linux
                readlink -f $1
        elif [[ "$OSTYPE" == "darwin"* ]]; then
                # Mac OSX
                greadlink -f $1
        elif [[ "$OSTYPE" == "cygwin" ]]; then
                # POSIX compatibility layer and Linux environment emulation for Windows
                readlink -f $1
        elif [[ "$OSTYPE" == "msys" ]]; then
                # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
                readlink -f $1
        elif [[ "$OSTYPE" == "win32" ]]; then
                # I'm not sure this can happen.
                echo "Cannot use readlink on Windows"
                exit 1
        elif [[ "$OSTYPE" == "freebsd"* ]]; then
                # ...
                readlink -f $1
        else
                # Unknown.
                echo "Unknown OS detected. Exiting..."
                exit 1
        fi
}
############################################################################################################################
# Assign default parameters for the flags
############################################################################################################################
WD=.                             # Working Directory
NJOBS=1                          # FASTQ Directory
OUTFILE=./md5.txt                # Sequencing type: Paired-end or Single-end
#CHECKFILE=./md5.check              # Sequencing type: Paired-end or Single-end
#unset OUTFILE

############################################################################################################################
# getopts
############################################################################################################################
while getopts 'w:n:o:rghc:' flag; do
        case "${flag}" in
                w) WD=${OPTARG}
                                   if [[ -d $WD ]]; then
                                        echo "Working directory: `linkread $WD`"
                                   else
                                        echo "ERROR: Cannot find working directory [-w]"
                                        exit_abnormal
                                   fi
                                   ;;
                n) NJOBS="${OPTARG}"
                               re_isanum='^[+]*[[:digit:]]*$' #re_isanum='^[0-9]+$' # Regex: match whole numbers only
                               if ! [[ $NJOBS =~ $re_isanum ]] ; then   # if $CORE not a whole number:
                                echo "ERROR: NJOBS [-n] must be a positive, whole number."
                                exit_abnormal
                               elif [ $NJOBS -eq "0" ]; then            # If it's zero:
                                echo "ERROR: NJOBS [-n] must be bigger than zero."
                                exit_abnormal
                               fi
                               ;;
                o) OUTFILE=${OPTARG} ;;
		r) RMWD=TRUE ;; 
		g) GZFILE=TRUE ;;
                c) CHECKFILE=${OPTARG} ;;
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
echo "[-w]      WD            : $WD"
echo "[-n]      NJOBS         : $NJOBS"
echo "[-g]      GZFILE        : $GZFILE"

if [ ! -z "${CHECKFILE}" ];then
echo "[-c]      CHECKFILE     : $CHECKFILE"
else
echo "[-o]      OUTFILE       : $OUTFILE"
echo "[-r]      RMWD          : $RMWD"
fi

echo "------------------------"

############################################################################################################################
# Run the pipeline
############################################################################################################################
#find $WD/ -type f -printf '%P\n' | parallel -j $NJOBS md5sum > $OUTFILE


if [ ! -z "${CHECKFILE}" ]; then
	CHECKFILEOUT=$CHECKFILE.check
	cat $CHECKFILE | parallel --pipe -j $NJOBS md5sum -c > $CHECKFILEOUT
	
else

	find $WD -type f | parallel -j $NJOBS md5sum > $OUTFILE
	wait
	if [ "$RMWD" == TRUE ]; then
		if [ ${WD: -1} == "/" ]; then
			cat $OUTFILE | awk -v SUB=$WD '{gsub(SUB,"./",$2); print}' > ${OUTFILE}.tmp
		else 
			cat $OUTFILE | awk -v SUB=$WD '{gsub(SUB,".",$2); print}' > ${OUTFILE}.tmp
		fi

	        mv ${OUTFILE}.tmp $OUTFILE
	fi

	if [ "$GZFILE" == TRUE ]; then
        	gzip $OUTFILE 
	fi

fi
