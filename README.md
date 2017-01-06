# Apex_Backup_Script

Bash Shell script to backup Oracle Apex environment
Minimum Apex version: 4.2

run_apex_backups.sh -d {DBSID} -w {WORKSPACE_NAME} -b {BACKUP LOCATION}

Requires pigz for tar compression, can be removed from script to use standard tar compression

Optional parameters
  -r Number of days to retain backups in backup location, default 60 days
  -a List of applications to export, default all
