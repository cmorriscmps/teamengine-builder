Introduction
------------

This repository provides easy to use scripts to install, from scratch and configure `TEAM Engine <https://github.com/opengeospatial/teamengine>`_ in Windows and Unix Machines

Prerequisites
-------------
The machine where TEAM Engine will be installed requires:


- **Java 8**: Download Java JDK (Java Development Kit) 8, from `here <https://www.openlogic.com/openjdk-downloads?field_java_parent_version_target_id=416>`_.
- **Maven 3**: It has been tested with **Maven 3.2.2**: Download Maven version 3.2.2 from `here <http://apache.mesi.com.ar/maven/maven-3/3.2.2/binaries/apache-maven-3.2.2-bin.zip>`_.
- **Git 1.8**: Download Git-SCM version 1.8 or newer  `here <http://git-scm.com/download>`_.
- **Apache Tomcat 7**: Tomcat is required to run TEAM Engine as a web application accessible from a browser.  It has been tested with Tomcat version 7.0.52, which can be download from
  `here <http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.52/bin/>`_.  Not required to run TEAM Engine as a console application.

The bin directories for the JDK, Maven, and Git need to be in your PATH environment variable.   


Download and run TE builder
---------------------------

Download te-build helper scripts:

	git clone https://github.com/opengeospatial/teamengine-builder.git

Go to the directory::

	cd teamengine-builder

To display build options:

	(Linux)    ./build_te.sh -help
	
	(Windows)  build_te.bat -help
	
To install the web application:

	(Linux)    ./build_te.sh -a 4.1.0b -t /home/ubuntu/apache-tomcat-7.0.52	

	(Windows)  build_te.bat -a 4.1.0b -t C:\apache-tomcat-7.0.52
	
	Start tomcat and you should see teamengine at http://localhost:8080/teamengine or similar configuration

To install just the console application:

	(Windows)  build_te.bat -console -a 5.5


Installation of the tests
-------------------------

Assume:

- $build is the directory that teamengine was built in.  For example C:\te-build
- $catalina_base is the path to catalina_base
- $war is the name of the war. For example *teamengine*
- $TE_BASE is the location of TE_BASE

Preparation:

#. Identify a file in csv format that has all the tests. For example: production-releases/201601.csv
#. Identify where TE_BASE is located. For example: $catalina_base/TE_BASE (for web app) or $build\TE_BASE (for console app)
#. For the web app, identify where the war is located. For example: $catalina_base/webapps/$war 
#. For the console app, identify where the app is located. For example: $build\teamengine-console-5.5-SNAPSHOT-bin

To display script installation options::

	(Linux)    ./install-all-tests.sh

	(Windows)  install-all-tests.bat


To install test scripts in the web app:

	(Linux)    ./install-all-tests.sh $TE_BASE $catalina_base/webapps/$war production-releases/201601.csv temp true
   
	(Windows)  install-all-tests.bat $TE_BASE $catalina_base\webapps\$war production-releases\201601.csv temp true
   
	Restart tomcat and you should see all the tests at http://localhost:8080/teamengine
	
To install test scripts in the console app:

	(Windows)  install-all-tests.bat $TE_BASE $build\teamengine-console-5.5-SNAPSHOT-bin production-releases\201601.csv temp true

	You should be able to use the command shell interface described at https://opengeospatial.github.io/teamengine/users.html

Jar cleanup
-----------

Duplicate jars might exist in the web installation. Do the following:

#. go to WEB-INF/lib  
#. run find-repeated-jars.sh

It will suggest a command to remove repeated jars.
   
