@ECHO OFF
SETLOCAL

:: NOTE: this script will not bring online volumes that are currently offline. 
:: Use diskpart to bring the volume online, then running this script will properly assign its mountpoint.

@CALL :preRunScript

:: mount drives using :myGUIDmounnt function
@CALL :myGUIDmount "C" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "D" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "E" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "F" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "G" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "H" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "J" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "K" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "L" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "M" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
@CALL :myGUIDmount "N" "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"




@CALL :postRunScript

GOTO EOF

:: -----------------------------------------------------------------------------

:preRunScript

:: define mountvol executable path
::@SET mountvol=C:\Windows\System32\cmd.exe /C C:\Windows\System32\mountvol.exe
@SET mountvol=C:\Windows\System32\mountvol.exe

:: setup mount point lists
@SET allReservedMountPoints=%
ECHO .
ECHO .
ECHO ----------------------------- INITIAL MOUNT POINTS -----------------------------
@CALL :analyzeMountPoints

ECHO --------------------------------------------------------------------------------

:: temp disable auto mounting
@CALL %mountvol% /N

:: remove info for unmounted volumes
@CALL %mountvol% /R

GOTO EOF


:postRunScript

:: re-enable auto mounting
@CALL %mountvol% /E

:: print final mount point info 
ECHO --------------------------------------------------------------------------------
ECHO .
ECHO .
ECHO ------------------------------ FINAL MOUNT POINTS ------------------------------
@CALL :printMountPointLists

GOTO EOF

:: -----------------------------------------------------------------------------------

:: mounting functions

:myGUIDmount
:: Check current drive GUID and mount point. It does the following:
:: --- 1) If there is a drivce currently mounted at the mount point other than the requested one, it unmounts it, tries to find a free mount point, and if successful remounts it to the free mount point
:: --- 2) If the requested drive GUID is mounted somewhere other than the requested mount point, it unmounts it
:: --- 3) It mounts the requested drive to the requested mount poiont (both of which are now guaranteed to not be in use, assuming no runtime errors)

ECHO --------------------------------------------------------------------------------
ECHO .

:: set variables
@SET letterCur=%~1
@SET mountPoint=%letterCur%:\

@SET driveGUID0=%~2
@SET driveGUID0=%driveGUID0:{=%
@SET driveGUID0=%driveGUID0:}=%
@SET driveGUID0={%driveGUID0%}
@SET driveGUID=\\?\Volume%driveGUID0%\

@CALL :addToReservedMountPointList "%~1"

ECHO ENSURING DRIVE %driveGUID0% IS MOUNTED TO %mountPoint%
ECHO .

:: get current GUID
@SET curGUID=NONE
FOR /f "delims=" %%m IN ('%mountvol% %mountPoint% /L') DO @SET curGUID=%%m
@SET curGUID=%curGUID: =%
IF "%curGUID%" == "Thesystemcannotfindthefilespecified." (
	@SET curGUID=NONE
)
	
::	@CALL :analyzeMountPoints
:: umount drive (if needed) and mount (correct) drive (if needed)
IF NOT "%curGUID%" == "%driveGUID%" (
	IF "%letterCur%" == "C" (
	ECHO WARNING: DRIVE %driveGUID0% IS NOT MOUNTED TO %mountPoint%
	ECHO However, re-mounting the %mountPoint% drive will result in a system crash.
	ECHO As such, the %mountPoint% drive will NOT be remounted
	GOTO EOF
	)
	@CALL :unmountDriveIfMountedIncorrectly
	IF NOT "%curGUID%" == "NONE" (
		ECHO .
		ECHO %mountPoint% currently has the wrong drive mounted
		ECHO It will be unmounted and if possible remounted to a new location
		ECHO .
		@CALL %mountvol% %mountPoint% /D
		@CALL :remountToFreeMountPoint
	) ELSE (
		ECHO %mountPoint% currently does not have a drive mounted
	)
	ECHO .
	ECHO Mounting drive %driveGUID0% to %mountPoint%
	@CALL %mountvol% %mountPoint% %driveGUID%
	@CALL :analyzeMountPoints
) ELSE (
	ECHO Drive %driveGUID0% is correctly mounted at %mountPoint%
	@CALL :printMountPointLists
)


ECHO .
ECHO --------------------------------------------------------------------------------

GOTO EOF

:: -----------------------------------------------------------------------------------

:analyzeMountPoints
:: scans mount points from C:\ to Z:\ and makes lists of which are free and which are in use

@SET allFreeMountPoints=%
@SET allUsedMountPoints=%

FOR %%b IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
	@CALL :checkIfMountPointInUse "%%b"
)

@CALL :printMountPointLists

GOTO EOF


:checkIfMountPointInUse
			
@SET letterCur1=%~1
@SET mountCheckCur=%~1%:\
@SET curMountCheckResponse=NONE

FOR /f "delims=" %%c IN ('%mountvol% %mountCheckCur% /L') DO @SET curMountCheckResponse=%%c
@SET curMountCheckResponse=%curMountCheckResponse: =%

IF "%curMountCheckResponse%" == "Thesystemcannotfindthefilespecified." (
	@CALL :addToFreeMountPointList "%letterCur1%"
) ELSE IF NOT "%curMountCheckResponse%" == "NONE" (
	@CALL :addToUsedMountPointList "%letterCur1%"
) ELSE (
	ECHO WARNING: The command to check the status of %letterCur1%:\ failed
	ECHO          This Mount point will not be used
)

GOTO EOF

:: -----------------------------------------------------------------------------------

:addToFreeMountPointList

@SET letterCur0=%~1
@SET "letterCur0=%letterCur0: =%"
@SET "allFreeMountPoints=%allFreeMountPoints% %letterCur0%"

GOTO EOF


:addToUsedMountPointList

@SET letterCur0=%~1
@SET "letterCur0=%letterCur0: =%"
@SET "allUsedMountPoints=%allUsedMountPoints% %letterCur0%"

GOTO EOF


:addToReservedMountPointList

@SET letterCur0=%~1
@SET "letterCur0=%letterCur0: =%"
@SET "allReservedMountPoints=%allReservedMountPoints% %letterCur0%"

GOTO EOF


:printMountPointLists
:: Prints lists of free, used, and reserved mounts. 
:: note: that the reserved list is independent of
 the free/used lists.

ECHO .
ECHO RESERVED MOUNT POINTS:  %allReservedMountPoints%
ECHO FREE MOUNT POINTS:      %allFreeMountPoints%
ECHO USED MOUNT POINTS:      %allUsedMountPoints%
ECHO .

GOTO EOF

:: -----------------------------------------------------------------------------------

:unmountDriveIfMountedIncorrectly
:: scans mount points from C:\ to Z:\ looking for the drive GUID and, if found, unmounts it

ECHO .
ECHO Checking if drive %driveGUID0% is incorrectly mounted...
ECHO .

FOR %%d IN (%allUsedMountPoints%) DO (
	@CALL :unmountDriveIfMountedIncorrectly0 "%%d%"
)

GOTO EOF

:unmountDriveIfMountedIncorrectly0

@SET curMountPointCheck=%~1%:\
@SET checkGUIDcur=NONE

FOR /f "delims=" %%e IN ('%mountvol% %curMountPointCheck% /L') DO @SET checkGUIDcur=%%e
@SET checkGUIDcur=%checkGUIDcur: =%

IF "%checkGUIDcur%" == "%driveGUID%" (
	ECHO Drive %driveGUID0% found incorrectly mounted at %curMountPointCheck%
	ECHO Drive %driveGUID0% will now be unmounted from incorrect mount point
	ECHO .
	@CALL %mountvol% %curMountPointCheck% /D
)

GOTO EOF

:: -----------------------------------------------------------------------------------

:remountToFreeMountPoint
:: scans through free mount poiunts, excludes any on the "reserved" list, and returns the the highest-letter free and unreserved mount point

ECHO Attempting to locate a free mount point...

@SET "freeMountPointCur=NONE"

FOR %%f IN (%allFreeMountPoints%) DO (
	@CALL :checkIfMountPointReserved "%%f%"
)

IF "%freeMountPointCur%" == "NONE" (
	ECHO All mount points from A:\ to Z:\ checked, but could not find an available mount point...
	ECHO The drive currently mounted at %mountPoint% has been unmounted, but will not be remounted
) ELSE (
	ECHO Free mount point found...
	ECHO The drive currently mounted at %mountPoint% will be remounted to %freeMountPointCur%
	@CALL %mountvol% %freeMountPointCur% %curGUID%
)
ECHO .
 
GOTO EOF

:checkIfMountPointReserved

@SET letterCur2=%~1
FOR %%g IN (%allReservedMountPoints%) DO (
	IF NOT "%letterCur2%" == "%%g" (
		@SET "freeMountLetterCur=%letterCur2%"
		@SET "freeMountPointCur=%freeMountLetterCur%:\"
	)
)

GOTO EOF
		
:EOF
