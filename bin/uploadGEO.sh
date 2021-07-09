#!/usr/bin/env bash

############################################################################################################################
# Usage for the script
############################################################################################################################
USAGE="This script uploads your folder to GEO FTP server. If the connection times out, it tries to reconnect. Be careful with your
input parameters to avoid overwhelming the GEO FTP server.

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
                                        echo "Local directory: `linkread $WD`"
                                   else
                                        echo "ERROR: Cannot find working directory [-w]"
                                        exit_abnormal
                                   fi
                                   ;;
                r) REMOTEDIR="${OPTARG}"
			           if [[ -d $REMOTEDIR ]]; then
                                        echo "Working directory: `linkread $WD`"
                                   else
                                        echo "ERROR: Cannot find working directory [-w]"
                                        exit_abnormal
                                   fi
                                   ;;
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
# Run the pipeline
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


