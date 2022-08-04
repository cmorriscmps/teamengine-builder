@ECHO OFF
setlocal enabledelayedexpansion
set current_dir=%CD%

if "%1" == "" GOTO :printHelp
if "%1" == "-h" GOTO :printHelp
if "%1" == "-help" GOTO :printHelp

echo.
echo.
echo -------------------------------------
echo.

::---------------------------------------------------------------

:loop
set param=%1

if DEFINED param (
	if "%1"=="-a" (
		set te_tag=%2
		shift
	) else if "%1"=="-b" (
		set base_folder=%~dpn2
		shift
	) else if "%1"=="-t" (
		set tomcat_base=%~dpn2
		set webapp=true
		shift
	) else if "%1"=="-w" (
		set war=%2
		shift
	)  else if "%1"=="-g" (
		set te_git_url=%2
		shift
	) else if "%1"=="-s" (
		set start=%2
		shift
	) else if "%1"=="-d" (
		set dev=%2
		shift
	) else if "%1"=="-f" (
		set folder_site=%~dpn2
		shift
	) else if "%1"=="-cb" (
		set catalinabasefolder=%~dpn2
		set webapp=true
		shift
	) else if "%1"=="-console" (
		set console=true
	)
	
	shift
	GOTO :loop
) 

REM -- Checking pre-conditions for java, git, maven, tomcat is installed or not.

	if "!JAVA_HOME!" == "" (
		echo.
		echo [FAIL] Please set the JAVA_HOME environment variable.
		echo.
		GOTO END
	)
	
	set "jar_status=false"
	call jar 2>&1 | findstr /lic:"jar-file" >nul && set "jar_status=true"
	if "!jar_status!" == "false" (
		echo.
		echo [FAIL] jar tool not found. Please install a JDK or put it in your PATH.
		echo.
		GOTO END
	)
	
	set "git_status=false"
	for /f "tokens=*" %%g in ( 'call git --version' ) do  echo %%g | findstr /lic:"git" >nul && set "git_status=true"
	if "!git_status!" == "false" (
		echo.
		echo [FAIL] Git not found. Please install Git.
		echo.
		GOTO END
	)
	
	set "mvn_status=false"
	for /f "tokens=*" %%g in ( 'call mvn -version' ) do  echo %%g | findstr /lic:"maven" >nul && set "mvn_status=true"
	if "!mvn_status!" == "false" (
		echo.
		echo [FAIL] Maven not found. Please install Maven.
		echo.
		GOTO END
	)
REM -- END Pre-conditions ---	


if DEFINED catalinabasefolder (
	if exist !catalinabasefolder! (
		echo [INFO] Using catalinabasefolder: !catalinabasefolder!
	)
)
	
if DEFINED tomcat_base (
	if exist "!tomcat_base!\bin\catalina.bat" (
		echo [INFO] Using tomcat:!tomcat_base!
	) else (
		echo.
		echo [FAIL] Please provide a correct tomcat location, e.g. C:\apache-tomcat-8.0.26
		echo.
		GOTO :printHelp
	)
)

if NOT DEFINED webapp (
	if NOT DEFINED console (
		echo.
		echo [FAIL] Please provide a correct tomcat installation or CATALINA_BASE folder
		echo        or use the -console option
		echo.
		GOTO :printHelp
	)
)
  
if DEFINED dev (
	echo [INFO] Running in development mode.  The local source to be used is !dev!
	SET te_git_url=
	SET te_tag=
) else if DEFINED te_git_url (
	echo [INFO] Using git url: !te_git_url!
) else (
	echo [INFO] The git url  was not provided, so 'https://github.com/opengeospatial/teamengine.git' will be used
	SET te_git_url=https://github.com/opengeospatial/teamengine.git
)
	  
if DEFINED te_tag (
	echo [INFO] Building !te_tag!
) else (
	echo [INFO] Did not provide a tag to build 'te_tag', so building master
	SET "te_tag=master"
)

if DEFINED base_folder (
	if EXIST !base_folder! (
		echo [INFO] Building in a fresh base folder: !base_folder!
	) else (
		echo.
		echo [FAIL] Base folder doesn't exist !base_folder!
		echo.
		GOTO END
	)
) else (
	echo [INFO] Base folder was not provided, so it will attempt to build in the user's directory 'C:\te-build'
	if NOT EXIST "C:\te-build" (
	   mkdir C:\te-build
	)
	SET "base_folder=C:\te-build"
)
echo [INFO] Using Base folder: !base_folder!

if DEFINED war (
	echo "[INFO] Using war name: " !war!
) else if DEFINED webapp (
	echo "[INFO] War name was not provide, so 'teamengine' will be used"
	SET "war=teamengine"
)

if DEFINED start (
	if "!start!" == "true" (
		echo "[INFO] tomcat will start after installing !start!"
	) else (
		SET "start=false"
	)
)

:: optional: contains body, header and footer for the welcome page
if DEFINED folder_site (
	echo [INFO] The folder to be used to create custom site content is: !folder_site!
) else (
	SET "folder_site=!current_dir!\site"
	echo [INFO] The folder site was not provided, so folder_site will be used: !folder_site!
)



SET folder_to_build=!base_folder!

:: location of tomcat
SET tomcat=!tomcat_base!

:: Contains example of a user: ogctest, ogctest
SET user_source_folder=!current_dir!\users

:: web archive name
SET war_name=!war!



:: ----------------------------------------------------------
echo [INFO] Cleaning folder to build !folder_to_build!
call :cleandir !folder_to_build! %0
::------------------------------------------------------------	

::-----------------------------------------------
::	Install TeamEngine depend on dev
::-----------------------------------------------

echo [INFO] Installing TEAM Engine
cd /d !folder_to_build!

if NOT DEFINED dev (
	git clone !te_git_url! teamengine
	
	if errorlevel 1 (
		echo.
		echo [FAIL] Repository doesn't exist: !te_git_url!
		echo.
		GOTO END
	)

	set tag_type=branch
	if not "!te_tag!"=="master" (
		git tag|findstr /b /e "!te_tag!">nul && ( 
			echo [INFO] Found tag: !te_tag!
			set tag_type=tag
		) || (
			git branch -a|findstr /b /e "!te_tag!">nul && ( 
				echo [INFO] Found branch: !te_tag!
			) || (
				echo.
				echo [FAIL] Branch or Tag !te_tag! not found
				echo.
				GOTO END
			) 
		)
	)

	echo [INFO] Checking out !tag_type!: !te_tag!
	cd /d !folder_to_build!\teamengine 
	git checkout !te_tag!

) else (
	echo [INFO] Running development mode - building from local folder
	if EXIST teamengine (
		call :cleandir !folder_to_build!\teamengine %0
	)
	if EXIST !dev! (
		if NOT EXIST !folder_to_build!\teamengine (
			echo [INFO] Creating directory !folder_to_build!\teamengine
			mkdir "!folder_to_build!\teamengine" 
		) 
		echo [INFO] Copying from !dev! to !folder_to_build!\teamengine
		xcopy !dev! "!folder_to_build!\teamengine" /s /h /q
	) else (
		echo.
		echo [FAIL] !dev! doesn't seems to be a local folder, for example C:\repo\directory.
		echo.
		GOTO END
	) 
)

echo [INFO] Building using Maven in quiet mode (1-2 min)
cd /d !folder_to_build!\teamengine
call mvn -q clean -DskipTests=true
if DEFINED catalinabasefolder (
	call mvn -q install -DskipTests=true || GOTO END
) else if DEFINED tomcat_base (
	call mvn -q install -DskipTests=true || GOTO END
) else (
	pushd teamengine-core
	call mvn -q install -DskipTests=true || GOTO END
	popd
	pushd teamengine-spi
	call mvn -q install -DskipTests=true || GOTO END
	popd
	pushd teamengine-spi-ctl
	call mvn -q install -DskipTests=true || GOTO END
	popd
	pushd teamengine-console
	call mvn -q install -DskipTests=true || GOTO END
	popd
)

echo [INFO] TE has been installed and built successfully

if DEFINED tomcat_base (
	SET "catalina_base=!folder_to_build!\catalina_base" 

	echo [INFO] Now clean, create and populate catalina base in !catalina_base!
	if EXIST !catalina_base! (
		call :cleandir !catalina_base! %0
	) else (
		mkdir !catalina_base!
	)

	cd /d !catalina_base!
	mkdir bin logs temp webapps work lib conf

	REM copy from tomcat bin and base files
	xcopy !tomcat!\bin\catalina.bat bin\ /s /h /q

	xcopy !tomcat!\conf conf\ /s /h /q
) else (
  SET "catalina_base=!catalinabasefolder!"
)
		
if DEFINED catalina_base (
	echo [INFO] copying war !war_name! to !catalina_base!\webapps
	
	call :cleandir !catalina_base!\webapps %0
	
	copy "!folder_to_build!\teamengine\teamengine-web\target\teamengine.war" "!catalina_base!\webapps\!war_name!.war"
	
	echo [INFO] unzipping common libs in !catalina_base!\lib

	pushd !catalina_base!\lib
	jar xf !folder_to_build!\teamengine\teamengine-web\target\teamengine-common-libs.zip
	popd
	
	set TE_BASE=!catalina_base!\TE_BASE
) else (
	set TE_BASE=!folder_to_build!\TE_BASE
)

echo [INFO] building TE_BASE
if EXIST !TE_BASE! (
	rd /s /q !TE_BASE!
)
mkdir !TE_BASE!
FOR %%f IN (!folder_to_build!\teamengine\teamengine-console\target\*base.zip) DO SET "base_zip=%%~dpnxf"
pushd !TE_BASE!
jar xf !base_zip!
popd

echo [INFO] copying sample of users
xcopy !user_source_folder! !TE_BASE!\users /s /q /y

if EXIST !folder_site! (  
	echo [INFO] updating !TE_BASE!\resources\site
	REM The folder_site contains body, header and footer to customize TE.

	rd /s /q !TE_BASE!\resources\site
	md !TE_BASE!\resources\site

	xcopy !folder_site! !TE_BASE!\resources\site /s /h /q

) else (
	echo [WARNING] the following folder for site was not found: '!folder_site!'. Site was not updated with custom information
)

if DEFINED catalinabasefolder (
	move !catalina_base!\bin\setenv.bat !catalina_base!\bin\setenv.bat.old
	
	type !catalina_base!\bin\setenv.bat.old | findstr /v \-DTE_BASE >> !catalina_base!\bin\setenv.bat
	
	echo SET CATALINA_OPTS=-server -Xmx1024m -XX:MaxPermSize=128m -DTE_BASE=!TE_BASE! >> !catalina_base!\bin\setenv.bat
	del  !catalina_base!\bin\setenv.bat.old
	echo [SUCCESS] TE build successful
	echo [INFO] Now start tomcat depending on your configuration
	GOTO END
)

if DEFINED tomcat_base (
	echo [INFO] creating setenv with environmental variables
	(
		echo rem This file creates required environmental variables 
		echo rem to properly run teamengine in tomcat
		echo.
		echo rem path to java jdk
		echo set JAVA_HOME=!JAVA_HOME!
		echo.
		echo rem path to tomcat 
		echo SET CATALINA_HOME=!tomcat!
		echo.
		echo rem path to server instance 
		echo SET CATALINA_BASE=!catalina_base!
		echo.
		echo rem catalina options
		echo SET CATALINA_OPTS=-server -Xmx1024m -XX:MaxPermSize=128m -DTE_BASE=!TE_BASE!
	) >!catalina_base!\bin\setenv.bat
)

if DEFINED console (
	echo [INFO] Installing the teamengine console apps
	FOR %%f IN (!folder_to_build!\teamengine\teamengine-console\target\*bin.zip) DO SET "bin_zip=%%~dpnxf"
	FOR %%f IN (!folder_to_build!\teamengine\teamengine-console\target\*bin.zip) DO SET "bin_dir=%%~nf"
	if exist !folder_to_build!\!bin_dir! rmdir /s /q !folder_to_build!\!bin_dir!
	mkdir !folder_to_build!\!bin_dir!
	pushd !folder_to_build!\!bin_dir!
	jar xf !bin_zip!
	popd
	copy /y !folder_to_build!\!bin_dir!\bin\windows\* !bin_dir!
	(
		echo rem This file creates required environmental variables 
		echo rem to properly run the teamengine console apps
		echo.
		echo set TE_BASE=!TE_BASE!
		echo set JAVA_HOME=!JAVA_HOME!
		echo set JAVA_OPTS=-Xmx256m
	) >!folder_to_build!\!bin_dir!\bin\windows\setenv.bat
	echo [INFO] Created !folder_to_build!\!bin_dir!\bin\windows\setenv.bat
)

echo [SUCCESS] TE build successful
echo [INFO] TE_BASE is !TE_BASE!

if DEFINED catalina_base (
	echo [INFO] catalina_base was built at !catalina_base!
	echo [INFO] to start run !catalina_base!/bin/catalina.bat start
	echo [INFO] to stop run !catalina_base!/bin/catalina.bat stop

	if "!start!"=="true" (
		netstat -na | find "LISTENING" | find /C /I ":8080">nul && ( 
			echo [INFO] Tomcat is running
			echo [INFO] Stopping Tomcat.....
			!catalina_base!\bin\catalina.bat stop 
			timeout /t 6
		) || (
			echo [INFO] Tomcat is not running
		)
		
		echo [INFO] Starting Tomcat....
		!catalina_base!\bin\catalina.bat start   
	)
)
		
		
		
::----------------------------------------------------------------
GOTO END

:cleandir 
REM param 1 is the dir to empty
REM param 2 is a file to leave in place
for /d %%a in (%1\*) do rd /s /q %%a
for %%a in (%1\*) do if not "%%~dpnxa"=="%~dpnx2" del /q %%a
goto :eof

:printHelp
echo ---------
echo Usage build_te [-t tomcat or -cb catalinabasefolder] [-console] [-options] 
echo.
echo There are three main ways to build.
echo.
echo 1. Build the webapp, where Tomcat and catalina_base are not setup
echo 2. Build the webapp, where catalina_base is already setup
echo 3. Build the the console application only
echo.
echo For the first case, -t parameter needs to be passed as an argument. 
echo For the second case, -cb needs to passed as an argument.
echo For the third case, -console needs to passed as an argument.
echo.
echo.
echo.
echo where:
echo   tomcat                    Is the path to tomcat, e.g. C:\apache-tomcat-7.0.52
echo   catalinabasefolder        Is the path to the CATALINA_BASE directory. It should contain 
echo                             webapps and lib folders, amongst others.
echo.
echo where options include:
echo   -g (for git-url)          URL to a git repository (local or external) for the TEAM Engine source
echo                             For example: https://github.com/opengeospatial/teamengine.git
echo                             If not provided, then this URL will be used:
echo                             https://github.com/opengeospatial/teamengine.git
echo.
echo   -a (for tag-or-branch)    To build a specific tag or branch.
echo                             If not provided, then master will be used.
echo.
echo   -b (for base-folder)      Local path where teamengine will be built from scratch.
echo                             If not given, then C:\te-build will be used.
echo.
echo   -w (for war)              War name
echo                             If not given, then 'teamengine' will be used.
echo.
echo   -s (for start)            If 'true', then the build will attempt to stop 
echo                             a tomcat a process and will start again tomcat.
echo.
echo   -d (for dev)              Local directory to build from to run in development mode. 
echo                             It will build from the source at the given path. No 'git pull' is issued.
echo                             If the parameters -g and -a are also provided, then they will not be used
echo.
echo   -f (for folder_site)      If given, it will build with the provided site folder, if not it will
echo                             use a folder 'site' located in the same directory of this script
echo                             The site folder customizes the look and feel, welcome page, etc.
echo.
echo  Examples:
echo     build_te.bat -t C:\apache-tomcat-7.0.57 
echo     build_te.bat -t C:\apache-tomcat-7.0.57 -a 4.1.0b -w /temp/te
echo     build_te.bat -t C:\apache-tomcat-7.0.57 
echo     build_te.bat -t C:\apache-tomcat-7.0.57 -d C:\teamengine\ -s true
echo. 
echo more information about TEAM Engine at https://github.com/opengeospatial/teamengine/  
echo more information about this builder at https://github.com/opengeospatial/teamengine-builder/ 
echo ---------- 

GOTO END

:END
cd !current_dir!
