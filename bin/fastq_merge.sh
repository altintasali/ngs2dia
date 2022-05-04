#!//usr/bin/env bash

###################################################################################################
# Assign default parameters for the flags
###################################################################################################
INDIR=.             # Input directory
SEQEND=PE           # Sequencing type: Paired-end or Single-end
BASEPATTERN=fastq.gz  # File basename pattern
R1_PATTERN=R1.fastq.gz
R2_PATTERN=R2.fastq.gz
BASESEP=_
CUTUNIQ=1-3
THREADS=1
OUTDIR=.

# usage: merge_fastq <dir IN/> <file_base seperator> <cut_uniq> <dir OUT>

USAGE="
Usage: `basename $0` [FLAGS]

[-i <input_dir>]
\t Input directory where FASTQ files to be merged are located
\t   default: .
[-a <sequencing_type>] 	 	
\t Sequencing type: Paired-end (PE) or Single-end (SE)
\t   default: PE
\t   options: PE,SE
[-b <file_basename_pattern>]
\t Grep pattern for FASTQ files
\t   default: fastq.gz
[-f <file_R1_pattern>]
\t Grep pattern for FASTQ files with R1_reads
\t   default: R1.fastq.gz
[-r <file_R2_pattern>]
\t Grep pattern for FASTQ files with R2_reads. Does not influence anything if sequencing type (-a) is SE
\t   default: R2.fastq.gz
[-s <file_basename_seperator>]
\t Delimitter to seperate FASTQ file basename
\t   default: _ (underscore)
[-c <file_cut_uniq>]
\t Cut basename of FASTQ file using -s flag. Will be passed to 'cut -f' 
\t   default: 1-3
[-t <threads>]
\t Number of threads to be used for parallel processing
\t   default: 1
[-o <output_dir>] 
\t Input directory for the merged FASTQ files
\t   default: .
[-h help]
\t Display help menu


Example:
- Files to merge:
 001_100_S1_L001_R1.fq.gz
 001_100_S1_L002_R1.fq.gz
 001_100_S1_L003_R1.fq.gz
 001_100_S1_L004_R1.fq.gz
- Output file:
 001_100_S1.fq.gz

- Code to run:
`basename $0` -b fq.gz -s _ -c 1-3 -f R1.fq.gz

"

while getopts 'i:a:b:f:r:s:c:t:o:h' flag; do
        case "${flag}" in
                i) INDIR=${OPTARG} ;;
                a) SEQEND=${OPTARG} ;;
                b) BASE_PATTERN=${OPTARG} ;;
                f) R1_PATTERN=${OPTARG} ;;
                r) R2_PATTERN=${OPTARG} ;;
                s) BASESEP=${OPTARG} ;;
                c) CUTUNIQ="${OPTARG}" ;;
                t) THREADS=${OPTARG} ;;
                o) OUTDIR=${OPTARG} ;;
                h | *) printf "$USAGE" 1>&2 ; exit 1 ;;
  esac
done

#######################################
####         Start Timer           ####
#######################################
res1=$(date +%s.%N)
#######################################

mkdir -p $OUTDIR
###################################################################################################
## Functions
###################################################################################################
export INDIR
export OUTDIR
export BASESEP
export R1_PATTERN
mergeR1(){
    echo ${1}
    echo ">>>>>>>>>>>>> ${1}${BASESEP}R1.fastq.gz" 
    files2merge=`find $INDIR -name ${1}"*${R1_PATTERN}" | sort | xargs -i basename {}`
    printf '%s\n' "${files2merge[@]}"
    echo "_____________"
    echo ""
    find $INDIR -name ${1}"*${R1_PATTERN}" | sort | \
    xargs -i cat {} > $OUTDIR/${1}${BASESEP}R1.fastq.gz    
}
mergeR2(){
    echo ${1}
    echo "<<<<<<<<<<<<< ${1}${BASESEP}R2.fastq.gz"
    files2merge=`find $INDIR -name ${1}"*${R1_PATTERN}" | sort | xargs -i basename {}`
    printf '%s\n' "${files2merge[@]}"
    echo "_____________"
    echo ""
    find $INDIR -name ${1}"*${R2_PATTERN}" | sort | \
    xargs -i cat {} > $OUTDIR/${1}${BASESEP}R2.fastq.gz    
}

export -f mergeR1
export -f mergeR2

###################################################################################################
## DO THE JOB
###################################################################################################
if [ $SEQEND == "PE" ]
then
    echo "------------------------"
    echo "Input parameters"
    echo "------------------------"
    echo "[-i]      INDIR        : $INDIR"
    echo "[-a]      SEQEND       : $SEQEND"
    echo "[-b]      BASE_PATTERN : $BASE_PATTERN"
    echo "[-f]      R1_PATTERN   : $R1_PATTERN"
    echo "[-r]      R2_PATTERN   : $R2_PATTERN"
    echo "[-s]      BASESEP      : $BASESEP"
    echo "[-c]      CUTUNIQ      : $CUTUNIQ"
    echo "[-t]      THREADS      : $THREADS"
    echo "[-o]      OUTDIR       : $OUTDIR"
    echo "------------------------"
    echo " "
    echo "Paired-end (PE) reads provided"
    export R2_PATTERN
    
    RUNS=`find $INDIR -name "*${BASE_PATTERN}" | xargs -i basename {} | cut -d $BASESEP -f $CUTUNIQ | sort -u`
    parallel -j $THREADS mergeR1 {} ::: $RUNS
    wait
    parallel -j $THREADS mergeR2 {} ::: $RUNS
    wait
elif [ $SEQEND == "SE" ]
then
    echo "------------------------"
    echo "Input parameters"
    echo "------------------------"
    echo "[-i]      INDIR        : $INDIR"
    echo "[-a]      SEQEND       : $SEQEND"
    echo "[-b]      BASE_PATTERN : $BASE_PATTERN"
    echo "[-f]      R1_PATTERN   : $R1_PATTERN"
    echo "[-s]      BASESEP      : $BASESEP"
    echo "[-c]      CUTUNIQ      : $CUTUNIQ"
    echo "[-t]      THREADS      : $THREADS"
    echo "[-o]      OUTDIR       : $OUTDIR"
    echo "------------------------"
    echo " "
    echo "Single-end (PE) reads provided"
    
    RUNS=`find $INDIR -name "*${BASE_PATTERN}" | xargs -i basename {} | cut -d $BASESEP -f $CUTUNIQ | sort -u`
    echo $RUNS
    parallel -j $THREADS mergeR1 {} ::: $RUNS
    wait
else
    echo "Read type can only be PE or SE"
    exit 1
fi

#######################################
####           End Timer           ####
#######################################
res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)
printf "Total runtime: %d:%02d:%02d:%02.4f\n" $dd $dh $dm $dsi
#######################################
