#!/usr/bin/env bash

############################################################################################################################
# Usage for the script
############################################################################################################################
USAGE="This script uploads your folder to GEO FTP server. If the connection times out, it tries to reconnect. 
Be careful with your input parameters (especially with -r) to avoid overwhelming the GEO FTP server.

Usage: `basename $0` [FLAGS]
\t [-l <local_directory>]                  Local directory to be uploaded [default=.]
\t [-r <remote_directory>]                 Remote directory on GEO FTP server
\t [-u <username>]                         GEO username
\t [-p <password>]                         GEO password
\t [-h <help>]                             Print help and exit

For GEO username and password, please refer to https://www.ncbi.nlm.nih.gov/geo/info/submissionftp.html

Example usage:
./uploadGEO.sh -l /my/folder/to/upload/geo -r ./my/geo/directory -u geoftp -p PaSsWoRd 

"

exit_abnormal() {       # Function: Exit with error.
  #printf $USAGE
  exit 1
}

############################################################################################################################
# Assign default parameters for the flags
############################################################################################################################
LOCALDIR=.                    # Default local directory
GEOUSER=geoftp                # Default GEO user
#GEOPASS=########              # Default GEO password


############################################################################################################################
# getopts
############################################################################################################################
while getopts 'l:r:u:p:h' flag; do
        case "${flag}" in
                l) LOCALDIR=${OPTARG}
                                   if [[ -d $LOCALDIR ]]; then
                                        echo "Local directory: `readlink -f $LOCALDIR`"
                                   else
                                        echo "ERROR: Cannot find local directory [-l]"
                                        exit_abnormal
                                   fi
                                   ;;
                r) REMOTEDIR=${OPTARG} ;;
                u) GEOUSER=${OPTARG} ;;
		p) GEOPASS=${OPTARG} ;; 
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
echo "[-i]      LOCALDIR      : $LOCALDIR"
echo "[-r]      REMOTEDIR     : $REMOTEDIR"
echo "[-u]      GEOUSER       : $GEOUSER"
echo "[-p]      GEOPASS       : $GEOPASS"
echo "------------------------"

############################################################################################################################
# Run the upload script
############################################################################################################################
## The body of this function is taken from: 
## https://www.biostars.org/p/268978/#268978 

try=0
COMPLETE_CONDITION=0

echo "START"

until [ "$lastresult" = "$COMPLETE_CONDITION" ]; do
  let "try+=1"
  echo "Try $try ..."
  ncftpput -F -R -z -v -u $GEOUSER -p "$GEOPASS" ftp-private.ncbi.nlm.nih.gov $REMOTEDIR $LOCALDIR
  let "lastresult=$?"
  echo "Last Resultcode: $lastresult"
done

echo "UPLOAD COMPLETED AFTER $try TRY(S)"

exit 0


