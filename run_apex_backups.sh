#!/bin/bash

DT()
{
  date "+>>> %y/%m/%d %T - "
}

BKP_DT=`date '+%Y_%m_%d'`

PATH=/bin:/usr/bin:/usr/local/bin; export PATH

# Process command line arguments.

echo ""

ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while getopts ":d:w:b:r:a:" param
do
  case $param in
    a) APP_LIST=$OPTARG
       ;;
    w) WORKSPACE=$OPTARG
       ;;
    d) DBSID=$OPTARG
       ;;
    b) BACKUP_LOC=$OPTARG
       ;;
    r) RETDAYS=$OPTARG
       ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ "x${DBSID}" = "x" ]
then
  echo "DB SID needs to be provided"
  echo ""
  exit 1
fi

if [ "x${WORKSPACE}" = "x" ]
then
  echo "WORKSPACE name needs to be provided"
  echo ""
  exit 1
fi

if [ "x${BACKUP_LOC}" = "x" ]
then
  echo "Backup location needs to be provided"
  echo ""
  exit 1
fi

if [ -z "${RETDAYS##*[!0-9]*}" ]
then
  echo "Number of days to retain apex backups has not been provided, defaulting to 60"
  RETDAYS=60
fi

if [ "x${APP_LIST}" = "x" ]
then
  echo "List of applications to export not supplied, defaulting to all"
  APP_LIST="*"
fi

echo ""
echo "$(DT)Checking if already running: "

if [ -f /tmp/run_apex_backups_${DBSID}_${WORKSPACE}.lck ] && ps -fp $(cat /tmp/run_apex_backups_${DBSID}_${WORKSPACE}.lck ) 1>/dev/null 2>&1
then
  echo " --- Already running. Exiting"
  exit 1
else
  echo " --- Not Running, continuing"
fi

echo $$ > /tmp/run_apex_backups_${DBSID}_${WORKSPACE}.lck

echo ""
echo "$(DT)Starting Apex backups"

if [ -d "${BACKUP_LOC}" ]
then
  echo ------ Deleting Apex Backups for database ${DBSID} workspace ${WORKSPACE} older than ${RETDAYS} days
  find ${BACKUP_LOC} -name "${DBSID}_${WORKSPACE}*.tar.gz" -ctime +${RETDAYS} -type f -exec sh -c 'echo --Deleting backup file "$1"; rm -f "$1"; ' x {} \;
  echo ""
  echo "Done"
  echo ""
fi

export ORACLE_SID=${DBSID}
export ORAENV_ASK=NO

. oraenv 1>/dev/null 2>&1

unset ORAENV_ASK

if [ -d "${BACKUP_LOC}/${DBSID}_${WORKSPACE}" ]
then
  echo "$(DT)Temporary directory already exists, removing it"
  rm -rf "${BACKUP_LOC}/${DBSID}_${WORKSPACE}"
fi

mkdir -p "${BACKUP_LOC}/${DBSID}_${WORKSPACE}"

if [ ! "x${APP_LIST}" = "x" ]
then
  echo ""

  if [ "${APP_LIST}" = "*" ]
  then
    echo "$(DT)Exporting all applications"
APP_LIST=$(echo "set pages 0 feedback off
            select listagg(APPLICATION_ID, ' ') within group (order by APPLICATION_ID) from apex_applications where WORKSPACE='${WORKSPACE}';
            quit" | sqlplus -S '/ as sysdba')
  fi 

  for appid in $( echo ${APP_LIST} | tr -s " " "\012" | sort -un )
  do
    echo ""
    echo "$(DT)Exporting application "${appid}
    mkdir -p "${BACKUP_LOC}/${DBSID}_${WORKSPACE}/f${appid}/pages"
    sqlplus /nolog @"${ABSOLUTE_PATH}/do_apex_export.sql" ${DBSID} ${appid} ${WORKSPACE} "${BACKUP_LOC}/${DBSID}_${WORKSPACE}/f${appid}"
  done

fi

echo ""
echo "$(DT)Exporting workspace and feedback details..."

sqlplus /nolog @"${ABSOLUTE_PATH}/do_workspace_feedback_export.sql" ${DBSID} ${WORKSPACE} "${BACKUP_LOC}/${DBSID}_${WORKSPACE}"

echo ""
echo "$(DT)Compressing backup to single tar.gz file - ${DBSID}_${WORKSPACE}_${BKP_DT}.tar.gz"
tar cf "${BACKUP_LOC}/${DBSID}_${WORKSPACE}_${BKP_DT}.tar.gz" --directory="${BACKUP_LOC}" ${DBSID}_${WORKSPACE}/  --use-compress-program=/usr/bin/pigz

echo ""
echo "$(DT)Cleaning up..."
rm -rf "${BACKUP_LOC}/${DBSID}_${WORKSPACE}"

rm -f /tmp/run_apex_backups_${DBSID}_${WORKSPACE}.lck

echo "" 
echo "$(DT)Completed successfully"
echo ""

