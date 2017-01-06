@echo off

SETLOCAL EnableDelayedExpansion

 

IF "%~1"=="" (

  echo You need to supply a database name

  exit /b 1

)

 

IF "%~2"=="" (

  echo You need to supply an Apex Workspace Name

  exit /b 1

)

 

@set DB_NAME=%~1
@set ORACLE_SID=%DB_NAME%
 

set APP_IDS=%~3

set BACKUP_DIR=H:\Apex_Backups

set WORKSPACE_NAME=%~2

 

@echo ------ Deleting Apex Backups for database !DB_NAME! workspace %WORKSPACE_NAME% older than 60 days

forfiles /p %BACKUP_DIR% /m %DB_NAME%_%WORKSPACE_NAME%*.7z /c "cmd /c echo ---Deleting file @path & del @path " /d -60 2>nul

 

call:getdateFunc +0 backup_date_time

 

IF EXIST %BACKUP_DIR%\%DB_NAME%_%WORKSPACE_NAME% (

  rmdir /Q /S %BACKUP_DIR%\%DB_NAME%_%WORKSPACE_NAME%

)

 

mkdir %BACKUP_DIR%\%DB_NAME%_%WORKSPACE_NAME%

 

FOR %%G in (%APP_IDS%) DO (

  @set APP_ID=%%G

  mkdir %BACKUP_DIR%\%DB_NAME%_%WORKSPACE_NAME%\f!APP_ID!\pages

  sqlplus /nolog @"%~dp0do_apex_export.sql" %DB_NAME% !APP_ID! %WORKSPACE_NAME% %BACKUP_DIR%\%DB_NAME%_%WORKSPACE_NAME%\f!APP_ID!

)

 

sqlplus /nolog @"%~dp0do_workspace_feedback_export.sql" %DB_NAME% %WORKSPACE_NAME% %BACKUP_DIR%\%DB_NAME%_%WORKSPACE_NAME%

 

 

"C:\Program Files\7-Zip\7z.exe" a %BACKUP_DIR%\%DB_NAME%_%WORKSPACE_NAME%_%backup_date_time%.7z %BACKUP_DIR%\%DB_NAME%_%WORKSPACE_NAME%\* 1>nul

 

rmdir /Q /S %BACKUP_DIR%\%DB_NAME%_%WORKSPACE_NAME%

 

goto:eof

 

REM END OF BATCH SCRIPT

REM VBSCRIPT FUNCTION CALLED WITHIN BATCH SCRIPT

 

:getDateFunc

FOR /F %%a IN ('POWERSHELL -COMMAND "$([guid]::NewGuid().ToString())"') DO ( SET NEWGUID=%%a )

set NEWGUID=%NEWGUID: =%

set vb=%~dp0newdate_%NEWGUID%.vbs

(

echo Newdate = (Date(^)%~1^)

echo Yyyy = DatePart("YYYY", Newdate^)

echo   Mm = DatePart("M"   , Newdate^)

echo   Dd = DatePart("D"   , Newdate^)

echo   Wd = DatePart("WW"  , Newdate^)

echo   Wn = DatePart("Y"   , Newdate^)

echo   Ww = datepart("W"   , Newdate^)

 

echo Wscript.Echo Yyyy^&" "^&Mm^&" "^&Dd^&" "^&Wd^&" "^&Ww^&" "^&Wn

)>>"%vb%"

 

FOR /F "tokens=1-6 delims= " %%A in ('cscript //nologo "%vb%"') do (

        set Yyyy=%%A

        set Mm=%%B

        set Dd=%%C

        set Week#=%%D

        set Weekday#=%%E

        set Day#=%%F

        )

 

del %vb%

::                    [Environment Variables are:

::                     %Yyyy%     Year in the format yyyy

::                     %Mm%       Month in the format m or mm

::                     %Dd%       Number of the day in month in the format d or dd (range 1 thru'31)

::                     %Week#%    Week number in year in the format w or ww (range 1 thru' 52)

::                     %Weekday#% Day number in week in the format w

::                                     (range 1 thru' 7, day#1 is Sunday)

::                     %Day#%     day number in the year in the format d thru ddd

::                                     (range 1 thru' 366)]

 

set days=

if not "%1"=="" set days=days

if %Mm% lss 10 set Mm=0%Mm%

if %Dd% lss 10 set Dd=0%Dd%

set "%~2=%Yyyy%_%Mm%_%Dd%"

goto:eof