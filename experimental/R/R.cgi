#! /bin/sh

###  A shell script to make CGI scripting possible in R.  Part of the
###  "CGIwithR" package for R.
###
###  Author: David Firth, University of Warwick 
###  (d.firth@warwick.ac.uk)
###
###  Terms of use: GPL version 2 or later.  See "COPYING" in the
###  R distribution.
###
###  NO WARRANTY GIVEN, AND NO LIABILITY ACCEPTED FOR LOSS CAUSED BY
###  USE OF THIS PROGRAM
###
###
###  INSTALLING IT:
###
###  This file, and the one-line ".Rprofile" file included with the
###  package, must be placed together in a "cgi-bin" directory.  Both 
###  files should be readable (and this file executable) by the web 
###  server.
###
###
###  CONFIGURING IT:
###    
###  First locate R on the local system (typically the answer 
###  to "which R"). This is the command to run R.
###  Individual R CGI scripts may request execution by a  
###  different, elsewhere-installed version of R; the R specified 
###  here is the default.

#R_DEFAULT=/usr/local/bin/R
R_DEFAULT=/usr/bin/R

###  Graphs can be included in the output using either the 
###  GDD package (available from cran.r-project.org) 
###  or via ghostscript.
###  GDD is the default.  If it is not installed, the webPNG()
###  function will attempt to use ghostscript.  You can specify
###  where the executable is located on your system via the R_GSCMD
###  environment variable.  If using GDD, you can ignore this.

R_GSCMD=/usr/local/bin/gs
export R_GSCMD

###  The next two lines may optionally be edited to limit access
###  to local resources.
###
###  This line allows specification of the priority
###  given to the R process.  A nice of "0" is the normal  
###  priority, while e.g. "+10" causes R to be run as a 
###  low-priority process.  The value "NONE" should be given if  
###  nice is not implemented locally.

R_NICE=NONE

###  This line allows the imposition of a length limit on the data
###  entered on an HTML form for processing by an R script.  
###  Setting MAX_DATA_LENGTH=1000, for example, aborts  
###  execution if the data length exceeds 1000 characters.  Or
###  use MAX_DATA_LENGTH=NONE to impose no limit here.

MAX_DATA_LENGTH=10000


###
### To make use of packages not installed in the default library for R
### i.e. `R RHOME`/library/, set the environment R_LIBS to identify
### one or more library directories containing the packages (separated by :).
### This is only necessary if the CGIwithR package itself is not located
### in the default library, e.g. if one is using a different version.

R_LIBS=
export R_LIBS


###  No further configuration is needed.  
###
###  It is assumed that the CGIwithR package is installed in the  
###  standard library of the R installation.
###
###  See the documentation included with the CGIwithR package for 
###  more details, examples of use, etc.

###################################################################
###################################################################

###  The script proper begins here.
###


###  Check that the data length does not exceed our limit (if any):

case $REQUEST_METHOD in
GET) FORM_DATA=$QUERY_STRING; 
     CONTENT_LENGTH=`expr "$FORM_DATA" : '.*'` ;;
   # Read the input to this script into FORM_DATA.
   # Was `cat $1` But simple `cat` should be reasonably portable !
   # In bash, we can use  `cat /dev/stdin`
POST) FORM_DATA=`cat` ;;
esac
export FORM_DATA

case $MAX_DATA_LENGTH in
NONE)  ;;
none)  ;;
*)    if test $CONTENT_LENGTH -gt $MAX_DATA_LENGTH
        then echo "Error: too much data"; exit 1
      fi ;;
esac

###  Construct the full path to the R script to be run:

PWD=`pwd`
PATH_TRANSLATED=$PWD$PATH_INFO
export PATH_TRANSLATED

###  Next, determine which R will be used.  This is either specified
###  at the head of the script to be run, or else is the R_DEFAULT
###  specified above.

PATH_TO_R=`cat $PATH_TRANSLATED | sed -n 's/^\#\!\ *//p'` 
## (strip #! )
PATH_TO_R=`echo $PATH_TO_R | sed 's/\ *//'`  
## (strip any trailing spaces)     
case $PATH_TO_R in
`ls $PATH_TO_R`) ;;
"") PATH_TO_R=$R_DEFAULT ;;
*)  echo "Error: $PATH_TO_R not found"; exit 1
esac

###  Finally, call R to execute the script and send back the results:

Rcall="$PATH_TO_R --no-restore --no-save --no-readline --slave "

THE_RESULTS=`case $R_NICE in
NONE) $Rcall < $PATH_TRANSLATED ;;
none) $Rcall < $PATH_TRANSLATED ;;
*) nice -n $R_NICE $Rcall < $PATH_TRANSLATED ;;
esac`


### Check if the script has emitted its own Content-type:
### and if not, we add text/html before returning the output
### from the script.

echo $THE_RESULTS | grep '^Content-type: ' > /dev/null

if ! test "$?" = "0" ; then
  echo "Content-type: text/html"; echo
fi

echo "$THE_RESULTS"
# echo "$PATH_TRANSLATED"