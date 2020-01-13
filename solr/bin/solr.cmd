@REM
@REM  Licensed to the Apache Software Foundation (ASF) under one or more
@REM  contributor license agreements.  See the NOTICE file distributed with
@REM  this work for additional information regarding copyright ownership.
@REM  The ASF licenses this file to You under the Apache License, Version 2.0
@REM  (the "License"); you may not use this file except in compliance with
@REM  the License.  You may obtain a copy of the License at
@REM
@REM      http://www.apache.org/licenses/LICENSE-2.0
@REM
@REM  Unless required by applicable law or agreed to in writing, software
@REM  distributed under the License is distributed on an "AS IS" BASIS,
@REM  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@REM  See the License for the specific language governing permissions and
@REM  limitations under the License.

@echo off

Here's a test line I added

@REM Make sure to keep line endings as CRLF for .cmd files

IF "%OS%"=="Windows_NT" setlocal enabledelayedexpansion enableextensions

set "PASS_TO_RUN_EXAMPLE="

REM Determine top-level Solr directory
set SDIR=%~dp0
IF "%SDIR:~-1%"=="\" set SDIR=%SDIR:~0,-1%
set SOLR_TIP=%SDIR%\..
pushd %SOLR_TIP%
set SOLR_TIP=%CD%
popd

REM Used to report errors before exiting the script
set SCRIPT_ERROR=
set NO_USER_PROMPT=0

REM Allow user to import vars from an include file
REM vars set in the include file can be overridden with
REM command line args
IF "%SOLR_INCLUDE%"=="" set "SOLR_INCLUDE=%SOLR_TIP%\bin\solr.in.cmd"
IF EXIST "%SOLR_INCLUDE%" CALL "%SOLR_INCLUDE%"

set "DEFAULT_SERVER_DIR=%SOLR_TIP%\server"

REM Select HTTP OR HTTPS related configurations
set SOLR_URL_SCHEME=http
set "SOLR_JETTY_CONFIG=--module=http"
set "SOLR_SSL_OPTS= "

IF DEFINED SOLR_HADOOP_CREDENTIAL_PROVIDER_PATH (
  set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Dhadoop.security.credential.provider.path=%SOLR_HADOOP_CREDENTIAL_PROVIDER_PATH%"
)

IF NOT DEFINED SOLR_SSL_ENABLED (
  IF DEFINED SOLR_SSL_KEY_STORE (
    set "SOLR_SSL_ENABLED=true"
  ) ELSE (
    set "SOLR_SSL_ENABLED=false"
  )
)

IF "%SOLR_SSL_ENABLED%"=="true" (
  set "SOLR_JETTY_CONFIG=--lib="%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*""
  if !JAVA_MAJOR_VERSION! GEQ 9  (
    set "SOLR_JETTY_CONFIG=!SOLR_JETTY_CONFIG! --module=https"
  ) else (
    set "SOLR_JETTY_CONFIG=!SOLR_JETTY_CONFIG! --module=https8"
  )
  set SOLR_URL_SCHEME=https
  IF DEFINED SOLR_SSL_KEY_STORE (
    set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Dsolr.jetty.keystore=%SOLR_SSL_KEY_STORE%"
  )

  IF DEFINED SOLR_SSL_KEY_STORE_TYPE (
    set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Dsolr.jetty.keystore.type=%SOLR_SSL_KEY_STORE_TYPE%"
  )

  IF DEFINED SOLR_SSL_TRUST_STORE (
    set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Dsolr.jetty.truststore=%SOLR_SSL_TRUST_STORE%"
  )
  IF DEFINED SOLR_SSL_TRUST_STORE_TYPE (
    set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Dsolr.jetty.truststore.type=%SOLR_SSL_TRUST_STORE_TYPE%"
  )

  IF NOT DEFINED SOLR_SSL_CLIENT_HOSTNAME_VERIFICATION (
    set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Dsolr.jetty.ssl.verifyClientHostName=HTTPS"
  )

  IF DEFINED SOLR_SSL_NEED_CLIENT_AUTH (
    set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Dsolr.jetty.ssl.needClientAuth=%SOLR_SSL_NEED_CLIENT_AUTH%"
  )
  IF DEFINED SOLR_SSL_WANT_CLIENT_AUTH (
    set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Dsolr.jetty.ssl.wantClientAuth=%SOLR_SSL_WANT_CLIENT_AUTH%"
  )

  IF DEFINED SOLR_SSL_CLIENT_KEY_STORE (
    set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Djavax.net.ssl.keyStore=%SOLR_SSL_CLIENT_KEY_STORE%"

    IF DEFINED SOLR_SSL_CLIENT_KEY_STORE_TYPE (
      set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Djavax.net.ssl.keyStoreType=%SOLR_SSL_CLIENT_KEY_STORE_TYPE%"
    )
  ) ELSE (
    IF DEFINED SOLR_SSL_KEY_STORE (
      set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Djavax.net.ssl.keyStore=%SOLR_SSL_KEY_STORE%"
    )
    IF DEFINED SOLR_SSL_KEY_STORE_TYPE (
      set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Djavax.net.ssl.keyStoreType=%SOLR_SSL_KEY_STORE_TYPE%"
    )
  )

  IF DEFINED SOLR_SSL_CLIENT_TRUST_STORE (
    set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Djavax.net.ssl.trustStore=%SOLR_SSL_CLIENT_TRUST_STORE%"

    IF DEFINED SOLR_SSL_CLIENT_TRUST_STORE_TYPE (
      set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Djavax.net.ssl.trustStoreType=%SOLR_SSL_CLIENT_TRUST_STORE_TYPE%"
    )
  ) ELSE (
    IF DEFINED SOLR_SSL_TRUST_STORE (
     set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Djavax.net.ssl.trustStore=%SOLR_SSL_TRUST_STORE%"
    )
    IF DEFINED SOLR_SSL_TRUST_STORE_TYPE (
     set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Djavax.net.ssl.trustStoreType=%SOLR_SSL_TRUST_STORE_TYPE%"
    )
  )
  IF DEFINED SOLR_SSL_CHECK_PEER_NAME (
   set "SOLR_SSL_OPTS=!SOLR_SSL_OPTS! -Dsolr.ssl.checkPeerName=%SOLR_SSL_CHECK_PEER_NAME%"
  )
) ELSE (
  set SOLR_SSL_OPTS=
)

REM Requestlog options
IF "%SOLR_REQUESTLOG_ENABLED%"=="true" (
  set "SOLR_JETTY_CONFIG=!SOLR_JETTY_CONFIG! --module=requestlog"
)

REM Authentication options

IF NOT DEFINED SOLR_AUTH_TYPE (
  IF DEFINED SOLR_AUTHENTICATION_OPTS (
    echo WARNING: SOLR_AUTHENTICATION_OPTS variable configured without associated SOLR_AUTH_TYPE variable
    echo          Please configure SOLR_AUTH_TYPE variable with the authentication type to be used.
    echo          Currently supported authentication types are [kerberos, basic]
  )
)

IF DEFINED SOLR_AUTH_TYPE (
  IF DEFINED SOLR_AUTHENTICATION_CLIENT_BUILDER (
    echo WARNING: SOLR_AUTHENTICATION_CLIENT_BUILDER and SOLR_AUTH_TYPE variables are configured together
    echo          Use SOLR_AUTH_TYPE variable to configure authentication type to be used
    echo          Currently supported authentication types are [kerberos, basic]
    echo          The value of SOLR_AUTHENTICATION_CLIENT_BUILDER configuration variable will be ignored
  )
)

IF DEFINED SOLR_AUTH_TYPE (
  IF /I "%SOLR_AUTH_TYPE%" == "basic" (
    set SOLR_AUTHENTICATION_CLIENT_BUILDER="org.apache.solr.client.solrj.impl.PreemptiveBasicAuthClientBuilderFactory"
  ) ELSE (
    IF /I "%SOLR_AUTH_TYPE%" == "kerberos" (
      set SOLR_AUTHENTICATION_CLIENT_BUILDER="org.apache.solr.client.solrj.impl.PreemptiveBasicAuthClientBuilderFactory"
    ) ELSE (
      echo ERROR: Value specified for SOLR_AUTH_TYPE configuration variable is invalid.
      goto err
    )
  )
)

IF DEFINED SOLR_AUTHENTICATION_CLIENT_CONFIGURER (
  echo WARNING: Found unsupported configuration variable SOLR_AUTHENTICATION_CLIENT_CONFIGURER
  echo          Please start using SOLR_AUTH_TYPE instead
)
IF DEFINED SOLR_AUTHENTICATION_CLIENT_BUILDER (
  set AUTHC_CLIENT_BUILDER_ARG="-Dsolr.httpclient.builder.factory=%SOLR_AUTHENTICATION_CLIENT_BUILDER%"
)
set "AUTHC_OPTS=%AUTHC_CLIENT_BUILDER_ARG% %SOLR_AUTHENTICATION_OPTS%"

REM Set the SOLR_TOOL_HOST variable for use when connecting to a running Solr instance
IF NOT "%SOLR_HOST%"=="" (
  set "SOLR_TOOL_HOST=%SOLR_HOST%"
) ELSE (
  set "SOLR_TOOL_HOST=localhost"
)
IF "%SOLR_JETTY_HOST%"=="" (
  set "SOLR_JETTY_HOST=127.0.0.1"
)

REM Verify Java is available
IF DEFINED SOLR_JAVA_HOME set "JAVA_HOME=%SOLR_JAVA_HOME%"
REM Try to detect JAVA_HOME from the registry
IF NOT DEFINED JAVA_HOME (
  FOR /F "skip=2 tokens=2*" %%A IN ('REG QUERY "HKLM\Software\JavaSoft\Java Runtime Environment" /v CurrentVersion') DO set CurVer=%%B
  FOR /F "skip=2 tokens=2*" %%A IN ('REG QUERY "HKLM\Software\JavaSoft\Java Runtime Environment\!CurVer!" /v JavaHome') DO (
    set "JAVA_HOME=%%B"
  )
)
IF NOT DEFINED JAVA_HOME goto need_java_home
set JAVA_HOME=%JAVA_HOME:"=%
IF %JAVA_HOME:~-1%==\ SET JAVA_HOME=%JAVA_HOME:~0,-1%
IF NOT EXIST "%JAVA_HOME%\bin\java.exe" (
  set "SCRIPT_ERROR=java.exe not found in %JAVA_HOME%\bin. Please set JAVA_HOME to a valid JRE / JDK directory."
  goto err
)
set "JAVA=%JAVA_HOME%\bin\java"
CALL :resolve_java_info
IF !JAVA_MAJOR_VERSION! LSS 8 (
  set "SCRIPT_ERROR=Java 1.8 or later is required to run Solr. Current Java version is: !JAVA_VERSION_INFO! (detected major: !JAVA_MAJOR_VERSION!)"
  goto err
)

set FIRST_ARG=%1

IF [%1]==[] goto usage

IF "%1"=="-help" goto usage
IF "%1"=="-usage" goto usage
IF "%1"=="-h" goto usage
IF "%1"=="--help" goto usage
IF "%1"=="/?" goto usage
IF "%1"=="-i" goto get_info
IF "%1"=="-info" goto get_info
IF "%1"=="status" goto get_info
IF "%1"=="version" goto get_version
IF "%1"=="-v" goto get_version
IF "%1"=="-version" goto get_version
IF "%1"=="assert" goto run_assert
IF "%1"=="autoscaling" goto run_autoscaling
IF "%1"=="export" goto run_export
IF "%1"=="package" goto run_package

REM Only allow the command to be the first argument, assume start if not supplied
IF "%1"=="start" goto set_script_cmd
IF "%1"=="stop" goto set_script_cmd
IF "%1"=="restart" goto set_script_cmd
IF "%1"=="healthcheck" (
  REM healthcheck uses different arg parsing strategy
  set SCRIPT_CMD=healthcheck
  SHIFT
  goto parse_healthcheck_args
)
IF "%1"=="create" (
  set SCRIPT_CMD=create
  SHIFT
  goto parse_create_args
)
IF "%1"=="create_core" (
  set SCRIPT_CMD=create_core
  SHIFT
  goto parse_create_args
)
IF "%1"=="create_collection" (
  set SCRIPT_CMD=create_collection
  SHIFT
  goto parse_create_args
)
IF "%1"=="delete" (
  set SCRIPT_CMD=delete
  SHIFT
  goto parse_delete_args
)
IF "%1"=="zk" (
  set SCRIPT_CMD=zk
  SHIFT
  set ZK_RECURSE=false
  goto parse_zk_args
)
IF "%1"=="auth" (
  set SCRIPT_CMD=auth
  SHIFT
  goto run_auth
)
IF "%1"=="config" (
  REM config uses different arg parsing strategy
  set SCRIPT_CMD=config
  SHIFT
  set CONFIG_ARGS=
  goto parse_config_args
)

goto parse_args

:usage
IF NOT "%SCRIPT_ERROR%"=="" ECHO %SCRIPT_ERROR%
IF [%FIRST_ARG%]==[] goto script_usage
IF "%FIRST_ARG%"=="-help" goto script_usage
IF "%FIRST_ARG%"=="-usage" goto script_usage
IF "%FIRST_ARG%"=="-h" goto script_usage
IF "%FIRST_ARG%"=="--help" goto script_usage
IF "%FIRST_ARG%"=="/?" goto script_usage
IF "%SCRIPT_CMD%"=="start" goto start_usage
IF "%SCRIPT_CMD%"=="restart" goto start_usage
IF "%SCRIPT_CMD%"=="stop" goto stop_usage
IF "%SCRIPT_CMD%"=="healthcheck" goto healthcheck_usage
IF "%SCRIPT_CMD%"=="create" goto create_usage
IF "%SCRIPT_CMD%"=="create_core" goto create_core_usage
IF "%SCRIPT_CMD%"=="create_collection" goto create_collection_usage
IF "%SCRIPT_CMD%"=="delete" goto delete_usage
IF  "%SCRIPT_CMD%"=="zk" goto zk_usage
IF "%SCRIPT_CMD%"=="auth" goto auth_usage
IF "%SCRIPT_CMD%"=="status" goto status_usage
goto done

:script_usage
@echo.
@echo Usage: solr COMMAND OPTIONS
@echo        where COMMAND is one of: start, stop, restart, healthcheck, create, create_core, create_collection, delete, version, zk, auth, assert, config, autoscaling, export
@echo.
@echo   Standalone server example (start Solr running in the background on port 8984):
@echo.
@echo     solr start -p 8984
@echo.
@echo   SolrCloud example (start Solr running in SolrCloud mode using localhost:2181 to connect to Zookeeper, with 1g max heap size and remote Java debug options enabled):
@echo.
@echo     solr start -c -m 1g -z localhost:2181 -a "-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=1044"
@echo.
@echo   Omit '-z localhost:2181' from the above command if you have defined ZK_HOST in solr.in.cmd.
@echo.
@echo Pass -help after any COMMAND to see command-specific usage information,
@echo   such as:    solr start -help or solr stop -help
@echo.
goto done

:start_usage
@echo.
@echo Usage: solr %SCRIPT_CMD% [-f] [-c] [-h hostname] [-p port] [-d directory] [-z zkHost] [-m memory] [-e example] [-s solr.solr.home] [-t solr.data.home] [-a "additional-options"] [-V]
@echo.
@echo   -f            Start Solr in foreground; default starts Solr in the background
@echo                   and sends stdout / stderr to solr-PORT-console.log
@echo.
@echo   -c or -cloud  Start Solr in SolrCloud mode; if -z not supplied and ZK_HOST not defined in
@echo                   solr.in.cmd, an embedded ZooKeeper instance is started on Solr port+1000,
@echo                   such as 9983 if Solr is bound to 8983
@echo.
@echo   -h host       Specify the hostname for this Solr instance
@echo.
@echo   -p port       Specify the port to start the Solr HTTP listener on; default is 8983
@echo "                  The specified port (SOLR_PORT) will also be used to determine the stop port"
@echo "                  STOP_PORT=(\$SOLR_PORT-1000) and JMX RMI listen port RMI_PORT=(\$SOLR_PORT+10000). "
@echo "                  For instance, if you set -p 8985, then the STOP_PORT=7985 and RMI_PORT=18985"
@echo.
@echo   -d dir        Specify the Solr server directory; defaults to server
@echo.
@echo   -z zkHost     Zookeeper connection string; only used when running in SolrCloud mode using -c
@echo                   If neither ZK_HOST is defined in solr.in.cmd nor the -z parameter is specified,
@echo                   an embedded ZooKeeper instance will be launched.
@echo.
@echo   -m memory     Sets the min (-Xms) and max (-Xmx) heap size for the JVM, such as: -m 4g
@echo                   results in: -Xms4g -Xmx4g; by default, this script sets the heap size to 512m
@echo.
@echo   -s dir        Sets the solr.solr.home system property; Solr will create core directories under
@echo                   this directory. This allows you to run multiple Solr instances on the same host
@echo                   while reusing the same server directory set using the -d parameter. If set, the
@echo                   specified directory should contain a solr.xml file, unless solr.xml exists in Zookeeper.
@echo                   This parameter is ignored when running examples (-e), as the solr.solr.home depends
@echo                   on which example is run. The default value is server/solr. If passed a relative dir
@echo                   validation with the current dir will be done before trying the default server/^<dir^>
@echo.
@echo   -t dir        Sets the solr.data.home system property, where Solr will store index data in ^<instance_dir^>/data subdirectories.
@echo                   If not set, Solr uses solr.solr.home for both config and data.
@echo.
@echo   -e example    Name of the example to run; available examples:
@echo       cloud:          SolrCloud example
@echo       techproducts:   Comprehensive example illustrating many of Solr's core capabilities
@echo       dih:            Data Import Handler
@echo       schemaless:     Schema-less example
@echo.
@echo   -a opts       Additional parameters to pass to the JVM when starting Solr, such as to setup
@echo                 Java debug options. For example, to enable a Java debugger to attach to the Solr JVM
@echo                 you could pass: -a "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=18983"
@echo                 In most cases, you should wrap the additional parameters in double quotes.
@echo.
@echo   -j opts       Additional parameters to pass to Jetty when starting Solr.
@echo                 For example, to add configuration folder that jetty should read
@echo                 you could pass: -j "--include-jetty-dir=/etc/jetty/custom/server/"
@echo                 In most cases, you should wrap the additional parameters in double quotes.
@echo.
@echo   -noprompt     Don't prompt for input; accept all defaults when running examples that accept user input
@echo.
@echo   -v and -q     Verbose (-v) or quiet (-q) logging. Sets default log level to DEBUG or WARN instead of INFO
@echo.
@echo   -V/-verbose   Verbose messages from this script
@echo.
goto done

:status_usage
@echo.
@echo Usage: solr status
@echo.
@echo   NOTE: This command will show the status of all running Solr servers
@echo.
goto done

:stop_usage
@echo.
@echo Usage: solr stop [-k key] [-p port] [-V]
@echo.
@echo  -k key      Stop key; default is solrrocks
@echo.
@echo  -p port     Specify the port the Solr HTTP listener is bound to
@echo.
@echo  -all        Find and stop all running Solr servers on this host
@echo.
@echo  -V/-verbose Verbose messages from this script
@echo.
@echo  NOTE: To see if any Solr servers are running, do: solr status
@echo.
goto done

:healthcheck_usage
@echo.
@echo Usage: solr healthcheck [-c collection] [-z zkHost] [-V] 
@echo.
@echo Can be run from remote (non-Solr^) hosts, as long as a proper ZooKeeper connection is provided
@echo.
@echo   -c collection  Collection to run healthcheck against.
@echo.
@echo   -z zkHost      Zookeeper connection string; unnecessary if ZK_HOST is defined in solr.in.cmd; 
@echo                    otherwise, default is localhost:9983
@echo.
@echo   -V             Enable more verbose output
@echo.
goto done

:create_usage
echo.
echo Usage: solr create [-c name] [-d confdir] [-n confname] [-shards #] [-replicationFactor #] [-p port] [-V]
echo.
echo   Create a core or collection depending on whether Solr is running in standalone (core) or SolrCloud
echo   mode (collection). In other words, this action detects which mode Solr is running in, and then takes
echo   the appropriate action (either create_core or create_collection). For detailed usage instructions, do:
echo.
echo     bin\solr create_core -help
echo.
echo        or
echo.
echo     bin\solr create_collection -help
echo.
goto done

:delete_usage
echo.
echo Usage: solr delete [-c name] [-deleteConfig true^|false] [-p port] [-V]
echo.
echo  Deletes a core or collection depending on whether Solr is running in standalone (core) or SolrCloud
echo  mode (collection). If you're deleting a collection in SolrCloud mode, the default behavior is to also
echo  delete the configuration directory from Zookeeper so long as it is not being used by another collection.
echo  You can override this behavior by passing -deleteConfig false when running this command.
echo.
echo  Can be run on remote (non-Solr^) hosts, as long as a valid SOLR_HOST is provided in solr.in.cmd
echo.
echo   -c name     Name of core to delete
echo.
echo   -deleteConfig boolean Delete the configuration directory from Zookeeper; default is true
echo.
echo   -p port     Port of a local Solr instance where you want to delete the core/collection
echo                 If not specified, the script will search the local system for a running
echo                 Solr instance and will use the port of the first server it finds.
echo.
echo   -V            Enables more verbose output.
echo.
goto done

:create_core_usage
echo.
echo Usage: solr create_core [-c ^<core^>] [-d confdir] [-p port] [-V]
echo.
echo When a configSet is used, this can be run from any host.  If pointing at a non-configSet directory, this
echo must be run from the host that you wish to create the core on.
echo.
echo   -c ^<core^>     Name of core to create
echo.
echo   -d confdir  Configuration directory to copy when creating the new core, built-in options are:
echo.
echo       _default: Minimal configuration, which supports enabling/disabling field-guessing support
echo       sample_techproducts_configs: Example configuration with many optional features enabled to
echo          demonstrate the full power of Solr
echo.
echo       If not specified, default is: _default
echo.
echo       Alternatively, you can pass the path to your own configuration directory instead of using
echo       one of the built-in configurations, such as: bin\solr create_core -c mycore -d c:/tmp/myconfig
echo.
echo   -p port     Port of a local Solr instance where you want to create the new core
echo                 If not specified, the script will search the local system for a running
echo                 Solr instance and will use the port of the first server it finds.
echo.
echo   -V            Enable more verbose output.
echo.
goto done

:create_collection_usage
echo.
echo Usage: solr create_collection [-c collection] [-d confdir] [-n confname] [-shards #] [-replicationFactor #] [-p port] [-V]
echo.
echo Can be run from remote (non-Solr^) hosts, as long as a valid SOLR_HOST is provided in solr.in.cmd.
echo.
echo   -c ^<collection^>         Name of collection to create
echo.
echo   -d ^<confdir^>            Configuration directory to copy when creating the new collection, built-in options are:
echo.
echo       _default: Minimal configuration, which supports enabling/disabling field-guessing support
echo       sample_techproducts_configs: Example configuration with many optional features enabled to
echo          demonstrate the full power of Solr
echo.
echo       If not specified, default is: _default
echo.
echo       Alternatively, you can pass the path to your own configuration directory instead of using
echo       one of the built-in configurations, such as: bin\solr create_collection -c mycoll -d c:/tmp/myconfig
echo.
echo       By default the script will upload the specified confdir directory into Zookeeper using the same
echo         name as the collection (-c) option. Alternatively, if you want to reuse an existing directory
echo         or create a confdir in Zookeeper that can be shared by multiple collections, use the -n option
echo.
echo   -n configName         Name the configuration directory in Zookeeper; by default, the configuration
echo                             will be uploaded to Zookeeper using the collection name (-c), but if you want
echo                             to use an existing directory or override the name of the configuration in
echo                              Zookeeper, then use the -c option.
echo.
echo   -shards #             Number of shards to split the collection into; default is 1
echo.
echo   -replicationFactor #  Number of copies of each document in the collection, default is 1 (no replication)
echo.
echo   -p port               Port of a local Solr instance where you want to create the new collection
echo                           If not specified, the script will search the local system for a running
echo                           Solr instance and will use the port of the first server it finds.
echo.
echo   -V                    Enable more verbose output.
echo.
goto done

:zk_usage
set ZK_FULL=true
goto zk_short_usage
:zk_full_usage
echo         Can be run on remote (non-Solr^) hosts, as long as valid ZK_HOST information is provided.
echo         Be sure to check the Solr logs in case of errors.
echo.
echo             -z zkHost       Optional Zookeeper connection string for all commands. If specified it
echo                             overrides the 'ZK_HOST=...'' defined in solr.in.cmd.
echo.
echo             -V              Enable more verbose output.
echo.
echo         upconfig uploads a configset from the local machine to Zookeeper. (Backcompat: -upconfig)
echo.
echo         downconfig downloads a configset from Zookeeper to the local machine. (Backcompat: -downconfig)
echo.
echo             -n configName   Name of the configset in Zookeeper that will be the destination of
echo                             'upconfig' and the source for 'downconfig'.
echo.
echo             -d confdir      The local directory the configuration will be uploaded from for
echo                             'upconfig' or downloaded to for 'downconfig'. If 'confdir' is a child of
echo                             ...solr/server/solr/configsets' then the configs will be copied from/to
echo                             that directory. Otherwise it is interpreted as a simple local path.
echo.
echo         cp copies files or folders to/from Zookeeper or Zokeeper -^> Zookeeper
echo             -r              Recursively copy ^<src^> to ^<dst^>. Command will fail if ^<src^> has children and
echo                             -r is not specified. Optional
echo.
echo.             ^<src^>, ^<dest^> : [file:][/]path/to/local/file or zk:/path/to/zk/node
echo                              NOTE: ^<src^> and ^<dest^> may both be Zookeeper resources prefixed by 'zk:'
echo             When ^<src^> is a zk resource, ^<dest^> may be '.'
echo             If ^<dest^> ends with '/', then ^<dest^> will be a local folder or parent znode and the last
echo             element of the ^<src^> path will be appended unless ^<src^> also ends in a slash. 
echo             ^<dest^> may be zk:, which may be useful when using the cp -r form to backup/restore 
echo             the entire zk state.
echo             You must enclose local paths that end in a wildcard in quotes or just
echo             end the local path in a slash. That is,
echo             'bin/solr zk cp -r /some/dir/ zk:/ -z localhost:2181' is equivalent to
echo             'bin/solr zk cp -r ^"/some/dir/*^" zk:/ -z localhost:2181'
echo             but 'bin/solr zk cp -r /some/dir/* zk:/ -z localhost:2181' will throw an error.
echo.
echo             Here's an example of backup/restore for a ZK configuration:
echo             to copy to local: 'bin/solr zk cp -r zk:/ /some/dir -z localhost:2181'
echo             to restore to ZK: 'bin/solr zk cp -r /some/dir/ zk:/ -z localhost:2181'
echo.
echo             The 'file:' prefix is stripped, thus 'file:/wherever' specifies an absolute local path and
echo             'file:somewhere' specifies a relative local path. All paths on Zookeeper are absolute.
echo.
echo             Zookeeper nodes CAN have data, so moving a single file to a parent znode
echo             will overlay the data on the parent Znode so specifying the trailing slash
echo             can be important.
echo.
echo             Wildcards are supported when copying from local, trailing only and must be quoted.
echo.
echo         rm deletes files or folders on Zookeeper
echo             -r     Recursively delete if ^<path^> is a directory. Command will fail if ^<path^>
echo                    has children and -r is not specified. Optional
echo             ^<path^> : [zk:]/path/to/zk/node. ^<path^> may not be the root ('/')
echo.
echo         mv moves (renames) znodes on Zookeeper
echo             ^<src^>, ^<dest^> : Zookeeper nodes, the 'zk:' prefix is optional.
echo             If ^<dest^> ends with '/', then ^<dest^> will be a parent znode
echo             and the last element of the ^<src^> path will be appended.
echo             Zookeeper nodes CAN have data, so moving a single file to a parent znode
echo             will overlay the data on the parent Znode so specifying the trailing slash
echo             is important.
echo.
echo         ls lists the znodes on Zookeeper
echo             -r recursively descends the path listing all znodes. Optional
echo             ^<path^>: The Zookeeper path to use as the root.
echo.
echo             Only the node names are listed, not data
echo.
echo         mkroot makes a znode in Zookeeper with no data. Can be used to make a path of arbitrary
echo                depth but primarily intended to create a 'chroot'.
echo.
echo             ^<path^>: The Zookeeper path to create. Leading slash is assumed if not present.
echo                       Intermediate nodes are created as needed if not present.
echo.

goto done

:zk_short_usage
IF NOT "!ERROR_MSG!"=="" (
  echo  ERROR: !ERROR_MSG!
  echo.
)
echo  Usage: solr zk upconfig^|downconfig -d ^<confdir^> -n ^<configName^> [-z zkHost]
echo         solr zk cp [-r] ^<src^> ^<dest^> [-z zkHost]
echo         solr zk rm [-r] ^<path^> [-z zkHost]
echo         solr zk mv ^<src^> ^<dest^> [-z zkHost]
echo         solr zk ls [-r] ^<path^> [-z zkHost]
echo         solr zk mkroot ^<path^> [-z zkHost]
echo.
IF "%ZK_FULL%"=="true" (
  goto zk_full_usage
) ELSE (
  echo Type bin/solr zk -help for full usage help
)
goto done

:auth_usage
echo Usage: solr auth enable [-type basicAuth] -credentials user:pass [-blockUnknown ^<true^|false^>] [-updateIncludeFileOnly ^<true^|false^>] [-V]
echo        solr auth enable [-type basicAuth] -prompt ^<true^|false^> [-blockUnknown ^<true^|false^>] [-updateIncludeFileOnly ^<true^|false^>] [-V]
echo        solr auth disable [-updateIncludeFileOnly ^<true^|false^>] [-V]
echo.
echo  Updates or enables/disables authentication.  Must be run on the machine hosting Solr.
echo.
echo   -type ^<type^>                 The authentication mechanism to enable. Defaults to 'basicAuth'.
echo.
echo   -credentials ^<user:pass^>     The username and password of the initial user
echo                                Note: only one of -prompt or -credentials must be provided
echo.
echo   -prompt ^<true^|false^>         Prompts the user to provide the credentials
echo                                Note: only one of -prompt or -credentials must be provided
echo.
echo   -blockUnknown ^<true^|false^>   When true, this blocks out access to unauthenticated users. When not provided,
echo                                this defaults to false (i.e. unauthenticated users can access all endpoints, except the
echo                                operations like collection-edit, security-edit, core-admin-edit etc.^). Check the reference
echo                                guide for Basic Authentication for more details.
echo.
echo   -updateIncludeFileOnly ^<true^|false^>    Only update the solr.in.sh or solr.in.cmd file, and skip actual enabling/disabling"
echo                                          authentication (i.e. don't update security.json^)"
echo.
echo   -z zkHost                    Zookeeper connection string. Unnecessary if ZK_HOST is defined in solr.in.cmd.
echo.
echo   -d ^<dir^>                     Specify the Solr server directory"
echo.
echo   -s ^<dir^>                     Specify the Solr home directory. This is where any credentials or authentication"
echo                                configuration files (e.g. basicAuth.conf^) would be placed."
echo.
echo   -V                           Enable more verbose output
echo.
goto done

REM Really basic command-line arg parsing
:parse_args

set "arg=%~1"
set "firstTwo=%arg:~0,2%"
IF "%SCRIPT_CMD%"=="" set SCRIPT_CMD=start
IF [%1]==[] goto process_script_cmd
IF "%1"=="-help" goto usage
IF "%1"=="-usage" goto usage
IF "%1"=="/?" goto usage
IF "%1"=="-f" goto set_foreground_mode
IF "%1"=="-foreground" goto set_foreground_mode
IF "%1"=="-V" goto set_verbose
IF "%1"=="-verbose" goto set_verbose
IF "%1"=="-v" goto set_debug
IF "%1"=="-q" goto set_warn
IF "%1"=="-c" goto set_cloud_mode
IF "%1"=="-cloud" goto set_cloud_mode
IF "%1"=="-d" goto set_server_dir
IF "%1"=="-dir" goto set_server_dir
IF "%1"=="-s" goto set_solr_home_dir
IF "%1"=="-t" goto set_solr_data_dir
IF "%1"=="-solr.home" goto set_solr_home_dir
IF "%1"=="-e" goto set_example
IF "%1"=="-example" goto set_example
IF "%1"=="-h" goto set_host
IF "%1"=="-host" goto set_host
IF "%1"=="-m" goto set_memory
IF "%1"=="-memory" goto set_memory
IF "%1"=="-p" goto set_port
IF "%1"=="-port" goto set_port
IF "%1"=="-z" goto set_zookeeper
IF "%1"=="-zkhost" goto set_zookeeper
IF "%1"=="-zkHost" goto set_zookeeper
IF "%1"=="-a" goto set_addl_opts
IF "%1"=="-addlopts" goto set_addl_opts
IF "%1"=="-j" goto set_addl_jetty_config
IF "%1"=="-jettyconfig" goto set_addl_jetty_config
IF "%1"=="-noprompt" goto set_noprompt
IF "%1"=="-k" goto set_stop_key
IF "%1"=="-key" goto set_stop_key
IF "%1"=="-all" goto set_stop_all
IF "%firstTwo%"=="-D" goto set_passthru
IF NOT "%1"=="" goto invalid_cmd_line
goto invalid_cmd_line

:set_script_cmd
set SCRIPT_CMD=%1
SHIFT
goto parse_args

:set_foreground_mode
set FG=1
SHIFT
goto parse_args

:set_verbose
set verbose=1
set "PASS_TO_RUN_EXAMPLE=--verbose !PASS_TO_RUN_EXAMPLE!"
SHIFT
goto parse_args

:set_debug
set SOLR_LOG_LEVEL=DEBUG
set "PASS_TO_RUN_EXAMPLE=!PASS_TO_RUN_EXAMPLE! -Dsolr.log.level=%SOLR_LOG_LEVEL%"
SHIFT
goto parse_args

:set_warn
set SOLR_LOG_LEVEL=WARN
set "PASS_TO_RUN_EXAMPLE=!PASS_TO_RUN_EXAMPLE! -Dsolr.log.level=%SOLR_LOG_LEVEL%"
SHIFT
goto parse_args

:set_cloud_mode
set SOLR_MODE=solrcloud
SHIFT
goto parse_args

:set_server_dir

set "arg=%~2"
IF "%arg%"=="" (
  set SCRIPT_ERROR=Directory name is required!
  goto invalid_cmd_line
)
set firstChar=%arg:~0,1%
IF "%firstChar%"=="-" (
  set SCRIPT_ERROR=Expected directory but found %2 instead!
  goto invalid_cmd_line
)

REM See if they are using a short-hand name relative from the Solr tip directory
IF EXIST "%SOLR_TIP%\%~2" (
  set "SOLR_SERVER_DIR=%SOLR_TIP%\%~2"
) ELSE (
  set "SOLR_SERVER_DIR=%~2"
)
SHIFT
SHIFT
goto parse_args

:set_solr_home_dir

set "arg=%~2"
IF "%arg%"=="" (
  set SCRIPT_ERROR=Directory name is required!
  goto invalid_cmd_line
)

set firstChar=%arg:~0,1%
IF "%firstChar%"=="-" (
  set SCRIPT_ERROR=Expected directory but found %2 instead!
  goto invalid_cmd_line
)
set "SOLR_HOME=%~2"
SHIFT
SHIFT
goto parse_args

:set_solr_data_dir

set "arg=%~2"
IF "%arg%"=="" (
  set SCRIPT_ERROR=Directory name is required!
  goto invalid_cmd_line
)

set firstChar=%arg:~0,1%
IF "%firstChar%"=="-" (
  set SCRIPT_ERROR=Expected directory but found %2 instead!
  goto invalid_cmd_line
)
set "SOLR_DATA_HOME=%~2"
SHIFT
SHIFT
goto parse_args

:set_example

set "arg=%~2"
IF "%arg%"=="" (
  set SCRIPT_ERROR=Example name is required!
  goto invalid_cmd_line
)

set firstChar=%arg:~0,1%
IF "%firstChar%"=="-" (
  set SCRIPT_ERROR=Expected example name but found %2 instead!
  goto invalid_cmd_line
)

set EXAMPLE=%~2
SHIFT
SHIFT
goto parse_args

:set_memory

set "arg=%~2"
IF "%arg%"=="" (
  set SCRIPT_ERROR=Memory setting is required!
  goto invalid_cmd_line
)

set firstChar=%arg:~0,1%
IF "%firstChar%"=="-" (
  set SCRIPT_ERROR=Expected memory setting but found %2 instead!
  goto invalid_cmd_line
)

set SOLR_HEAP=%~2
set "PASS_TO_RUN_EXAMPLE=-m %~2 !PASS_TO_RUN_EXAMPLE!"
SHIFT
SHIFT
goto parse_args

:set_host
set "arg=%~2"
IF "%arg%"=="" (
  set SCRIPT_ERROR=Hostname is required!
  goto invalid_cmd_line
)

set firstChar=%arg:~0,1%
IF "%firstChar%"=="-" (
  set SCRIPT_ERROR=Expected hostname but found %2 instead!
  goto invalid_cmd_line
)

set SOLR_HOST=%~2
set "PASS_TO_RUN_EXAMPLE=-h %~2 !PASS_TO_RUN_EXAMPLE!"
SHIFT
SHIFT
goto parse_args

:set_port
set "arg=%~2"
IF "%arg%"=="" (
  set SCRIPT_ERROR=Port is required!
  goto invalid_cmd_line
)

set firstChar=%arg:~0,1%
IF "%firstChar%"=="-" (
  set SCRIPT_ERROR=Expected port but found %2 instead!
  goto invalid_cmd_line
)

set SOLR_PORT=%~2
set "PASS_TO_RUN_EXAMPLE=-p %~2 !PASS_TO_RUN_EXAMPLE!"
SHIFT
SHIFT
goto parse_args

:set_stop_key
set "arg=%~2"
IF "%arg%"=="" (
  set SCRIPT_ERROR=Stop key is required!
  goto invalid_cmd_line
)

set firstChar=%arg:~0,1%
IF "%firstChar%"=="-" (
  set SCRIPT_ERROR=Expected stop key but found %2 instead!
  goto invalid_cmd_line
)
set STOP_KEY=%~2
SHIFT
SHIFT
goto parse_args

:set_stop_all
set STOP_ALL=1
SHIFT
goto parse_args

:set_zookeeper

set "arg=%~2"
IF "%arg%"=="" (
  set SCRIPT_ERROR=Zookeeper connection string is required!
  goto invalid_cmd_line
)

set firstChar=%arg:~0,1%
IF "%firstChar%"=="-" (
  set SCRIPT_ERROR=Expected Zookeeper connection string but found %2 instead!
  goto invalid_cmd_line
)

set "ZK_HOST=%~2"
set "PASS_TO_RUN_EXAMPLE=-z %~2 !PASS_TO_RUN_EXAMPLE!"
SHIFT
SHIFT
goto parse_args

:set_addl_opts
set "arg=%~2"
set "SOLR_ADDL_ARGS=%~2"
SHIFT
SHIFT
goto parse_args

:set_addl_jetty_config
set "arg=%~2"
set "SOLR_JETTY_ADDL_CONFIG=%~2"
SHIFT
SHIFT
goto parse_args

:set_passthru
set "PASSTHRU=%~1=%~2"
IF NOT "%SOLR_OPTS%"=="" (
  set "SOLR_OPTS=%SOLR_OPTS% %PASSTHRU%"
) ELSE (
  set "SOLR_OPTS=%PASSTHRU%"
)
set "PASS_TO_RUN_EXAMPLE=%PASSTHRU% !PASS_TO_RUN_EXAMPLE!"
SHIFT
SHIFT
goto parse_args

:set_noprompt
set NO_USER_PROMPT=1
set "PASS_TO_RUN_EXAMPLE=-noprompt !PASS_TO_RUN_EXAMPLE!"

SHIFT
goto parse_args

REM Perform the requested command after processing args
:process_script_cmd

IF "%verbose%"=="1" (
  CALL :safe_echo "Using Solr root directory: %SOLR_TIP%"
  CALL :safe_echo "Using Java: %JAVA%"
  "%JAVA%" -version
  @echo.
)

IF NOT "%SOLR_HOST%"=="" (
  set SOLR_HOST_ARG=-Dhost=%SOLR_HOST%
) ELSE IF "%SOLR_JETTY_HOST%"=="" (
  set "SOLR_HOST_ARG=-Dhost=localhost"
) ELSE IF "%SOLR_JETTY_HOST%"=="127.0.0.1" (
  set "SOLR_HOST_ARG=-Dhost=localhost"
) ELSE (
  set SOLR_HOST_ARG=
)

IF "%SOLR_SERVER_DIR%"=="" set "SOLR_SERVER_DIR=%DEFAULT_SERVER_DIR%"

IF NOT EXIST "%SOLR_SERVER_DIR%" (
  set "SCRIPT_ERROR=Solr server directory %SOLR_SERVER_DIR% not found!"
  goto err
)

IF NOT "%EXAMPLE%"=="" goto run_example

:start_solr
IF "%SOLR_HOME%"=="" set "SOLR_HOME=%SOLR_SERVER_DIR%\solr"
IF EXIST "%cd%\%SOLR_HOME%" set "SOLR_HOME=%cd%\%SOLR_HOME%"

IF NOT EXIST "%SOLR_HOME%\" (
  IF EXIST "%SOLR_SERVER_DIR%\%SOLR_HOME%" (
    set "SOLR_HOME=%SOLR_SERVER_DIR%\%SOLR_HOME%"
  ) ELSE (
    set "SCRIPT_ERROR=Solr home directory %SOLR_HOME% not found!"
    goto err
  )
)

IF "%STOP_KEY%"=="" set STOP_KEY=solrrocks

@REM This is quite hacky, but examples rely on a different log4j2.xml
@REM so that we can write logs for examples to %SOLR_HOME%\..\logs
IF [%SOLR_LOGS_DIR%] == [] (
  set "SOLR_LOGS_DIR=%SOLR_SERVER_DIR%\logs"
) ELSE (
  set SOLR_LOGS_DIR=%SOLR_LOGS_DIR:"=%
)

set "EXAMPLE_DIR=%SOLR_TIP%\example"
set TMP_SOLR_HOME=!SOLR_HOME:%EXAMPLE_DIR%=!
IF NOT "%TMP_SOLR_HOME%"=="%SOLR_HOME%" (
  set "SOLR_LOGS_DIR=%SOLR_HOME%\..\logs"
  set "LOG4J_CONFIG=%SOLR_SERVER_DIR%\resources\log4j2.xml"
)

set IS_RESTART=0
IF "%SCRIPT_CMD%"=="restart" (
  IF "%SOLR_PORT%"=="" (
    set "SCRIPT_ERROR=Must specify the port when trying to restart Solr."
    goto err
  )
  set SCRIPT_CMD=stop
  set IS_RESTART=1
)

@REM stop logic here
IF "%SCRIPT_CMD%"=="stop" (
  IF "%SOLR_PORT%"=="" (
    IF "%STOP_ALL%"=="1" (
      set found_it=0
      for /f "usebackq" %%i in (`dir /b "%SOLR_TIP%\bin" ^| findstr /i "^solr-.*\.port$"`) do (
        set SOME_SOLR_PORT=
        For /F "delims=" %%J In ('type "%SOLR_TIP%\bin\%%i"') do set SOME_SOLR_PORT=%%~J
        if NOT "!SOME_SOLR_PORT!"=="" (
          for /f "tokens=2,5" %%j in ('netstat -aon ^| find "TCP " ^| find ":0 " ^| find ":!SOME_SOLR_PORT! "') do (
            @REM j is the ip:port and k is the pid
            IF NOT "%%k"=="0" (
              IF "%%j"=="%SOLR_JETTY_HOST%:!SOME_SOLR_PORT!" (
                set found_it=1
                @echo Stopping Solr process %%k running on port !SOME_SOLR_PORT!
                IF "%STOP_PORT%"=="" set /A STOP_PORT=!SOME_SOLR_PORT! - 1000
                "%JAVA%" %SOLR_SSL_OPTS% -Djetty.home="%SOLR_SERVER_DIR%" -jar "%SOLR_SERVER_DIR%\start.jar" STOP.PORT=!STOP_PORT! STOP.KEY=%STOP_KEY% --stop
                del "%SOLR_TIP%"\bin\solr-!SOME_SOLR_PORT!.port
                timeout /T 5
                REM Kill it if it is still running after the graceful shutdown
                For /f "tokens=2,5" %%M in ('netstat -nao ^| find "TCP " ^| find ":0 " ^| find ":!SOME_SOLR_PORT! "') do (
                  IF "%%N"=="%%k" (
                    IF "%%M"=="%SOLR_JETTY_HOST%:!SOME_SOLR_PORT!" (
                      @echo Forcefully killing process %%N
                      taskkill /f /PID %%N
                    )
                  )
                )
              )
            )
          )
        )
      )
      if "!found_it!"=="0" echo No Solr nodes found to stop.
    ) ELSE (
      set "SCRIPT_ERROR=Must specify the port when trying to stop Solr, or use -all to stop all running nodes on this host."
      goto err
    )
  ) ELSE (
    set found_it=0
    For /f "tokens=2,5" %%M in ('netstat -nao ^| find "TCP " ^| find ":0 " ^| find ":%SOLR_PORT% "') do (
      IF NOT "%%N"=="0" (
        IF "%%M"=="%SOLR_JETTY_HOST%:%SOLR_PORT%" (
          set found_it=1
          @echo Stopping Solr process %%N running on port %SOLR_PORT%
          IF "%STOP_PORT%"=="" set /A STOP_PORT=%SOLR_PORT% - 1000
          "%JAVA%" %SOLR_SSL_OPTS% -Djetty.home="%SOLR_SERVER_DIR%" -jar "%SOLR_SERVER_DIR%\start.jar" %SOLR_JETTY_CONFIG% STOP.PORT=!STOP_PORT! STOP.KEY=%STOP_KEY% --stop
          del "%SOLR_TIP%"\bin\solr-%SOLR_PORT%.port
          timeout /T 5
          REM Kill it if it is still running after the graceful shutdown
          For /f "tokens=2,5" %%j in ('netstat -nao ^| find "TCP " ^| find ":0 " ^| find ":%SOLR_PORT% "') do (
            IF "%%N"=="%%k" (
              IF "%%j"=="%SOLR_JETTY_HOST%:%SOLR_PORT%" (
                @echo Forcefully killing process %%N
                taskkill /f /PID %%N
              )
            )
          )
        )
      )
    )
    if "!found_it!"=="0" echo No Solr found running on port %SOLR_PORT%
  )

  IF "!IS_RESTART!"=="0" goto done
)

IF "!IS_RESTART!"=="1" set SCRIPT_CMD=start

IF "%SOLR_PORT%"=="" set SOLR_PORT=8983
IF "%STOP_PORT%"=="" set /A STOP_PORT=%SOLR_PORT% - 1000

IF DEFINED SOLR_JETTY_HOST (
  set "SOLR_OPTS=%SOLR_OPTS% -Dsolr.jetty.host=%SOLR_JETTY_HOST%"
)

IF "%SCRIPT_CMD%"=="start" (
  REM see if Solr is already running using netstat
  For /f "tokens=2,5" %%j in ('netstat -aon ^| find "TCP " ^| find ":0 " ^| find ":%SOLR_PORT% "') do (
    IF NOT "%%k"=="0" (
      IF "%%j"=="%SOLR_JETTY_HOST%:%SOLR_PORT%" (
        set "SCRIPT_ERROR=Process %%k is already listening on port %SOLR_PORT%. If this is Solr, please stop it first before starting (or use restart). If this is not Solr, then please choose a different port using -p PORT"
        goto err
      )
    )
  )
)

@REM determine if -server flag is supported by current JVM
"%JAVA%" -server -version > nul 2>&1
IF ERRORLEVEL 1 (
  set IS_JDK=false
  set "SERVEROPT="
  @echo WARNING: You are using a JRE without support for -server option. Please upgrade to latest JDK for best performance
  @echo.
) ELSE (
  set IS_JDK=true
  set "SERVEROPT=-server"
)
if !JAVA_MAJOR_VERSION! LSS 9  (
  "%JAVA%" -d64 -version > nul 2>&1
  IF ERRORLEVEL 1 (
    set "IS_64BIT=false"
    @echo WARNING: 32-bit Java detected. Not recommended for production. Point your JAVA_HOME to a 64-bit JDK
    @echo.
  ) ELSE (
    set IS_64bit=true
  )
) ELSE (
  set IS_64bit=true
)

REM Clean up and rotate logs. Default to false since 7.4 as log4j2 handles startup rotation
IF [%SOLR_LOG_PRESTART_ROTATION%] == [] (
  set SOLR_LOG_PRESTART_ROTATION=false
)
IF [%SOLR_LOG_PRESTART_ROTATION%] == [true] (
  REM Enable any of these if you require old remove/archive behavior
  REM call :run_utils "-remove_old_solr_logs 7" || echo "Failed removing old solr logs"
  REM call :run_utils "-archive_gc_logs"        || echo "Failed archiving old GC logs"
  REM call :run_utils "-archive_console_logs"   || echo "Failed archiving old console logs"
  call :run_utils "-rotate_solr_logs 9"     || echo "Failed rotating old solr logs"
)

IF NOT "%ZK_HOST%"=="" set SOLR_MODE=solrcloud

IF "%SOLR_MODE%"=="solrcloud" (
  IF "%ZK_CLIENT_TIMEOUT%"=="" set "ZK_CLIENT_TIMEOUT=15000"

  set "CLOUD_MODE_OPTS=-DzkClientTimeout=!ZK_CLIENT_TIMEOUT!"

  IF NOT "%ZK_HOST%"=="" (
    set "CLOUD_MODE_OPTS=!CLOUD_MODE_OPTS! -DzkHost=%ZK_HOST%"
  ) ELSE (
    IF "%verbose%"=="1" echo Configuring SolrCloud to launch an embedded Zookeeper using -DzkRun
    set "CLOUD_MODE_OPTS=!CLOUD_MODE_OPTS! -DzkRun"
  )
  IF EXIST "%SOLR_HOME%\collection1\core.properties" set "CLOUD_MODE_OPTS=!CLOUD_MODE_OPTS! -Dbootstrap_confdir=./solr/collection1/conf -Dcollection.configName=myconf -DnumShards=1"
) ELSE (
  set CLOUD_MODE_OPTS=
  IF NOT EXIST "%SOLR_HOME%\solr.xml" (
    set "SCRIPT_ERROR=Solr home directory %SOLR_HOME% must contain solr.xml!"
    goto err
  )
)

REM IP-based access control
set IP_ACL_OPTS=-Dsolr.jetty.inetaccess.includes="%SOLR_IP_WHITELIST%" ^
-Dsolr.jetty.inetaccess.excludes="%SOLR_IP_BLACKLIST%"

REM These are useful for attaching remove profilers like VisualVM/JConsole
IF "%ENABLE_REMOTE_JMX_OPTS%"=="true" (
  IF "!RMI_PORT!"=="" set RMI_PORT=1%SOLR_PORT%
  set REMOTE_JMX_OPTS=-Dcom.sun.management.jmxremote ^
-Dcom.sun.management.jmxremote.local.only=false ^
-Dcom.sun.management.jmxremote.ssl=false ^
-Dcom.sun.management.jmxremote.authenticate=false ^
-Dcom.sun.management.jmxremote.port=!RMI_PORT! ^
-Dcom.sun.management.jmxremote.rmi.port=!RMI_PORT!

  IF NOT "%SOLR_HOST%"=="" set REMOTE_JMX_OPTS=%REMOTE_JMX_OPTS% -Djava.rmi.server.hostname=%SOLR_HOST%
) ELSE (
  set REMOTE_JMX_OPTS=
)

REM Enable java security manager (limiting filesystem access and other things)
IF "%SOLR_SECURITY_MANAGER_ENABLED%"=="true" (
  set SECURITY_MANAGER_OPTS=-Djava.security.manager ^
-Djava.security.policy="%SOLR_SERVER_DIR%\etc\security.policy" ^
-Djava.security.properties="%SOLR_SERVER_DIR%\etc\security.properties" ^
-Dsolr.internal.network.permission=*
)

IF NOT "%SOLR_HEAP%"=="" set SOLR_JAVA_MEM=-Xms%SOLR_HEAP% -Xmx%SOLR_HEAP%
IF "%SOLR_JAVA_MEM%"=="" set SOLR_JAVA_MEM=-Xms512m -Xmx512m
IF "%SOLR_JAVA_STACK_SIZE%"=="" set SOLR_JAVA_STACK_SIZE=-Xss256k
set SOLR_OPTS=%SOLR_JAVA_STACK_SIZE% %SOLR_OPTS%
IF "%SOLR_TIMEZONE%"=="" set SOLR_TIMEZONE=UTC

IF "%GC_TUNE%"=="" (
  set GC_TUNE=-XX:+UseG1GC ^
    -XX:+PerfDisableSharedMem ^
    -XX:+ParallelRefProcEnabled ^
    -XX:MaxGCPauseMillis=250 ^
    -XX:+UseLargePages ^
    -XX:+AlwaysPreTouch
)

if !JAVA_MAJOR_VERSION! GEQ 9  (
  IF NOT "%GC_LOG_OPTS%"=="" (
    echo ERROR: On Java 9 you cannot set GC_LOG_OPTS, only default GC logging is available. Exiting
    GOTO :eof
  )
  set GC_LOG_OPTS="-Xlog:gc*:file=\"!SOLR_LOGS_DIR!\solr_gc.log\":time,uptime:filecount=9,filesize=20M"
) else (
  IF "%GC_LOG_OPTS%"=="" (
    rem Set defaults for Java 8
    set GC_LOG_OPTS=-verbose:gc ^
     -XX:+PrintHeapAtGC ^
     -XX:+PrintGCDetails ^
     -XX:+PrintGCDateStamps ^
     -XX:+PrintGCTimeStamps ^
     -XX:+PrintTenuringDistribution ^
     -XX:+PrintGCApplicationStoppedTime
  )
  if "%JAVA_VENDOR%" == "IBM J9" (
    set GC_LOG_OPTS=!GC_LOG_OPTS! "-Xverbosegclog:!SOLR_LOGS_DIR!\solr_gc.log" -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=9 -XX:GCLogFileSize=20M
  ) else (
    set GC_LOG_OPTS=!GC_LOG_OPTS! "-Xloggc:!SOLR_LOGS_DIR!\solr_gc.log" -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=9 -XX:GCLogFileSize=20M
  )
)

IF "%verbose%"=="1" (
  @echo Starting Solr using the following settings:
  CALL :safe_echo "    JAVA            = %JAVA%"
  CALL :safe_echo "    SOLR_SERVER_DIR = %SOLR_SERVER_DIR%"
  CALL :safe_echo "    SOLR_HOME       = %SOLR_HOME%"
  @echo     SOLR_HOST       = %SOLR_HOST%
  @echo     SOLR_PORT       = %SOLR_PORT%
  @echo     STOP_PORT       = %STOP_PORT%
  @echo     SOLR_JAVA_MEM   = %SOLR_JAVA_MEM%
  @echo     GC_TUNE         = !GC_TUNE!
  @echo     GC_LOG_OPTS     = %GC_LOG_OPTS%
  @echo     SOLR_TIMEZONE   = %SOLR_TIMEZONE%

  IF "%SOLR_MODE%"=="solrcloud" (
    @echo     CLOUD_MODE_OPTS = %CLOUD_MODE_OPTS%
  )

  IF NOT "%SOLR_OPTS%"=="" (
    @echo     SOLR_OPTS       = %SOLR_OPTS%
  )

  IF NOT "%SOLR_ADDL_ARGS%"=="" (
    CALL :safe_echo "     SOLR_ADDL_ARGS  = %SOLR_ADDL_ARGS%"
  )

  IF NOT "%SOLR_JETTY_ADDL_CONFIG%"=="" (
    CALL :safe_echo "     SOLR_JETTY_ADDL_CONFIG  = %SOLR_JETTY_ADDL_CONFIG%"
  )

  IF "%ENABLE_REMOTE_JMX_OPTS%"=="true" (
    @echo     RMI_PORT        = !RMI_PORT!
    @echo     REMOTE_JMX_OPTS = %REMOTE_JMX_OPTS%
  )

  IF NOT "%SOLR_LOG_LEVEL%"=="" (
    @echo     SOLR_LOG_LEVEL  = !SOLR_LOG_LEVEL!
  )

  IF NOT "%SOLR_DATA_HOME%"=="" (
    @echo     SOLR_DATA_HOME  = !SOLR_DATA_HOME!
  )

  @echo.
)

set START_OPTS=-Duser.timezone=%SOLR_TIMEZONE%
set START_OPTS=%START_OPTS% !GC_TUNE! %GC_LOG_OPTS%
IF NOT "!CLOUD_MODE_OPTS!"=="" set "START_OPTS=%START_OPTS% !CLOUD_MODE_OPTS!"
IF NOT "!IP_ACL_OPTS!"=="" set "START_OPTS=%START_OPTS% !IP_ACL_OPTS!"
IF NOT "%REMOTE_JMX_OPTS%"=="" set "START_OPTS=%START_OPTS% %REMOTE_JMX_OPTS%"
IF NOT "%SOLR_ADDL_ARGS%"=="" set "START_OPTS=%START_OPTS% %SOLR_ADDL_ARGS%"
IF NOT "%SOLR_HOST_ARG%"=="" set "START_OPTS=%START_OPTS% %SOLR_HOST_ARG%"
IF NOT "%SOLR_OPTS%"=="" set "START_OPTS=%START_OPTS% %SOLR_OPTS%"
IF NOT "!SECURITY_MANAGER_OPTS!"=="" set "START_OPTS=%START_OPTS% !SECURITY_MANAGER_OPTS!"
IF "%SOLR_SSL_ENABLED%"=="true" (
  set "SSL_PORT_PROP=-Dsolr.jetty.https.port=%SOLR_PORT%"
  set "START_OPTS=%START_OPTS% %SOLR_SSL_OPTS% !SSL_PORT_PROP!"
)
IF NOT "%SOLR_LOG_LEVEL%"=="" set "START_OPTS=%START_OPTS% -Dsolr.log.level=%SOLR_LOG_LEVEL%"

set SOLR_LOGS_DIR_QUOTED="%SOLR_LOGS_DIR%"
set SOLR_DATA_HOME_QUOTED="%SOLR_DATA_HOME%"

set "START_OPTS=%START_OPTS% -Dsolr.log.dir=%SOLR_LOGS_DIR_QUOTED%"
IF NOT "%SOLR_DATA_HOME%"=="" set "START_OPTS=%START_OPTS% -Dsolr.data.home=%SOLR_DATA_HOME_QUOTED%"
IF NOT DEFINED LOG4J_CONFIG set "LOG4J_CONFIG=%SOLR_SERVER_DIR%\resources\log4j2.xml"

cd /d "%SOLR_SERVER_DIR%"

IF NOT EXIST "%SOLR_LOGS_DIR%" (
  mkdir "%SOLR_LOGS_DIR%"
)
copy /Y NUL "%SOLR_LOGS_DIR%\.writable" > NUL 2>&1 && set WRITEOK=1
IF DEFINED WRITEOK (
  del "%SOLR_LOGS_DIR%\.writable"
) else (
  echo "ERROR: Logs directory %SOLR_LOGS_DIR% is not writable or could not be created. Exiting"
  GOTO :eof
)
echo " contexts etc lib modules resources scripts solr solr-webapp " > "%TEMP%\solr-pattern.txt"
findstr /i /C:" %SOLR_LOGS_DIR% " "%TEMP%\solr-pattern.txt" 1>nul
if %ERRORLEVEL% == 0 (
  echo "ERROR: Logs directory %SOLR_LOGS_DIR% is invalid. Reserved for the system. Exiting"
  GOTO :eof
)

IF NOT EXIST "%SOLR_SERVER_DIR%\tmp" (
  mkdir "%SOLR_SERVER_DIR%\tmp"
)

IF "%DEFAULT_CONFDIR%"=="" set "DEFAULT_CONFDIR=%SOLR_SERVER_DIR%\solr\configsets\_default\conf"

IF "%FG%"=="1" (
  REM run solr in the foreground
  title "Solr-%SOLR_PORT%"
  echo %SOLR_PORT%>"%SOLR_TIP%"\bin\solr-%SOLR_PORT%.port
  "%JAVA%" %SERVEROPT% %SOLR_JAVA_MEM% %START_OPTS% ^
    -Dlog4j.configurationFile="%LOG4J_CONFIG%" -DSTOP.PORT=!STOP_PORT! -DSTOP.KEY=%STOP_KEY% ^
    -Dsolr.solr.home="%SOLR_HOME%" -Dsolr.install.dir="%SOLR_TIP%" -Dsolr.default.confdir="%DEFAULT_CONFDIR%" ^
    -Djetty.port=%SOLR_PORT% -Djetty.home="%SOLR_SERVER_DIR%" ^
    -Djava.io.tmpdir="%SOLR_SERVER_DIR%\tmp" -jar start.jar %SOLR_JETTY_CONFIG% "%SOLR_JETTY_ADDL_CONFIG%"
) ELSE (
  START /B "Solr-%SOLR_PORT%" /D "%SOLR_SERVER_DIR%" ^
    "%JAVA%" %SERVEROPT% %SOLR_JAVA_MEM% %START_OPTS% ^
    -Dlog4j.configurationFile="%LOG4J_CONFIG%" -DSTOP.PORT=!STOP_PORT! -DSTOP.KEY=%STOP_KEY% ^
    -Dsolr.log.muteconsole ^
    -Dsolr.solr.home="%SOLR_HOME%" -Dsolr.install.dir="%SOLR_TIP%" -Dsolr.default.confdir="%DEFAULT_CONFDIR%" ^
    -Djetty.port=%SOLR_PORT% -Djetty.home="%SOLR_SERVER_DIR%" ^
    -Djava.io.tmpdir="%SOLR_SERVER_DIR%\tmp" -jar start.jar %SOLR_JETTY_CONFIG% "%SOLR_JETTY_ADDL_CONFIG%" > "!SOLR_LOGS_DIR!\solr-%SOLR_PORT%-console.log"
  echo %SOLR_PORT%>"%SOLR_TIP%"\bin\solr-%SOLR_PORT%.port

  REM now wait to see Solr come online ...
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" -Dsolr.default.confdir="%DEFAULT_CONFDIR%"^
    -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
    -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
    org.apache.solr.util.SolrCLI status -maxWaitSecs 30 -solr !SOLR_URL_SCHEME!://%SOLR_TOOL_HOST%:%SOLR_PORT%/solr
)

goto done

:run_example
REM Run the requested example

"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI run_example -script "%SDIR%\solr.cmd" -e %EXAMPLE% -d "%SOLR_SERVER_DIR%" ^
  -urlScheme !SOLR_URL_SCHEME! !PASS_TO_RUN_EXAMPLE!

REM End of run_example
goto done

:get_info
REM Find all Java processes, correlate with those listening on a port
REM and then try to contact via that port using the status tool
for /f "usebackq" %%i in (`dir /b "%SOLR_TIP%\bin" ^| findstr /i "^solr-.*\.port$"`) do (
  set SOME_SOLR_PORT=
  For /F "Delims=" %%J In ('type "%SOLR_TIP%\bin\%%i"') do set SOME_SOLR_PORT=%%~J
  if NOT "!SOME_SOLR_PORT!"=="" (
    for /f "tokens=2,5" %%j in ('netstat -aon ^| find "TCP " ^| find ":0 " ^| find ":!SOME_SOLR_PORT! "') do (
      IF NOT "%%k"=="0" (
        if "%%j"=="%SOLR_JETTY_HOST%:!SOME_SOLR_PORT!" (
          @echo.
          set has_info=1
          echo Found Solr process %%k running on port !SOME_SOLR_PORT!
          "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
            -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
            -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
            org.apache.solr.util.SolrCLI status -solr !SOLR_URL_SCHEME!://%SOLR_TOOL_HOST%:!SOME_SOLR_PORT!/solr
          @echo.
        )
      )
    )
  )
)
if NOT "!has_info!"=="1" echo No running Solr nodes found.
set has_info=
goto done

:parse_healthcheck_args
IF [%1]==[] goto run_healthcheck
IF "%1"=="-V" goto set_healthcheck_verbose
IF "%1"=="-c" goto set_healthcheck_collection
IF "%1"=="-collection" goto set_healthcheck_collection
IF "%1"=="-z" goto set_healthcheck_zk
IF "%1"=="-zkhost" goto set_healthcheck_zk
IF "%1"=="-zkHost" goto set_healthcheck_zk
IF "%1"=="-help" goto usage
IF "%1"=="-usage" goto usage
IF "%1"=="/?" goto usage
goto run_healthcheck

:set_healthcheck_verbose
set HEALTHCHECK_VERBOSE="-verbose"
SHIFT
goto parse_healthcheck_args

:set_healthcheck_collection
set HEALTHCHECK_COLLECTION=%~2
SHIFT
SHIFT
goto parse_healthcheck_args

:set_healthcheck_zk
set ZK_HOST=%~2
SHIFT
SHIFT
goto parse_healthcheck_args

:run_healthcheck
IF NOT DEFINED HEALTHCHECK_COLLECTION goto healthcheck_usage
IF NOT DEFINED HEALTHCHECK_VERBOSE set "HEALTHCHECK_VERBOSE="
IF NOT DEFINED HEALTHCHECK_ZK_HOST set "HEALTHCHECK_ZK_HOST=localhost:9983"
echo ZK_HOST: !ZK_HOST!
"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI healthcheck -collection !HEALTHCHECK_COLLECTION! -zkHost !ZK_HOST! %HEALTHCHECK_VERBOSE%
goto done

:run_assert
"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI %* 
if errorlevel 1 (
   exit /b 1
)
goto done

:run_autoscaling
"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI %* 
goto done:

:run_export
"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI %*
goto done:

:run_package
REM TODO: Compute the running Solr URL and populate it as a parameter (as has been done for the shell script)
REM Without that, users will have to supply -solrUrl parameter in every request. Life can be so hard for Windows users!
"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI %*
goto done:

:parse_config_args
IF [%1]==[] goto run_config
IF "%1"=="-z" goto set_config_zk
IF "%1"=="-zkhost" goto set_config_zk
IF "%1"=="-zkHost" goto set_config_zk
IF "%1"=="-s" goto set_config_url_scheme
IF "%1"=="-scheme" goto set_config_url_scheme
set "CONFIG_ARGS=!CONFIG_ARGS! %1"
SHIFT
goto parse_config_args

:set_config_zk
set ZK_HOST=%~2
SHIFT
SHIFT
goto parse_config_args

:set_config_url_scheme
set SOLR_URL_SCHEME=%~2
SHIFT
SHIFT
goto parse_config_args

:run_config
IF NOT "!ZK_HOST!"=="" SET "CONFIG_ARGS=!CONFIG_ARGS! -z !ZK_HOST!"
IF NOT "!SOLR_URL_SCHEME!"=="" SET "CONFIG_ARGS=!CONFIG_ARGS! -scheme !SOLR_URL_SCHEME!"

"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI config !CONFIG_ARGS!
if errorlevel 1 (
   exit /b 1
)
goto done

:get_version
"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI version
goto done

:run_utils
set "TOOL_CMD=%~1"
set q="-q"
IF "%verbose%"=="1"  set q=""
"%JAVA%" %SOLR_SSL_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI utils -s "%DEFAULT_SERVER_DIR%" -l "%SOLR_LOGS_DIR%" %q:"=% %TOOL_CMD%
if errorlevel 1 (
   exit /b 1
)
goto done

:parse_create_args
IF [%1]==[] goto run_create
IF "%1"=="-V" goto set_create_verbose
IF "%1"=="-c" goto set_create_name
IF "%1"=="-core" goto set_create_name
IF "%1"=="-collection" goto set_create_name
IF "%1"=="-d" goto set_create_confdir
IF "%1"=="-confdir" goto set_create_confdir
IF "%1"=="-n" goto set_create_confname
IF "%1"=="-confname" goto set_create_confname
IF "%1"=="-s" goto set_create_shards
IF "%1"=="-shards" goto set_create_shards
IF "%1"=="-rf" goto set_create_rf
IF "%1"=="-replicationFactor" goto set_create_rf
IF "%1"=="-p" goto set_create_port
IF "%1"=="-port" goto set_create_port
IF "%1"=="-help" goto usage
IF "%1"=="-usage" goto usage
IF "%1"=="/?" goto usage
goto run_create


:set_create_verbose
set CREATE_VERBOSE="-verbose"
SHIFT
goto parse_create_args

:set_create_name
set CREATE_NAME=%~2
SHIFT
SHIFT
goto parse_create_args

:set_create_confdir
set CREATE_CONFDIR=%~2
SHIFT
SHIFT
goto parse_create_args

:set_create_confname
set CREATE_CONFNAME=%~2
SHIFT
SHIFT
goto parse_create_args

:set_create_port
set CREATE_PORT=%~2
SHIFT
SHIFT
goto parse_create_args

:set_create_shards
set CREATE_NUM_SHARDS=%~2
SHIFT
SHIFT
goto parse_create_args

:set_create_rf
set CREATE_REPFACT=%~2
SHIFT
SHIFT
goto parse_create_args

:run_create
IF "!CREATE_NAME!"=="" (
  set "SCRIPT_ERROR=Name (-c) is a required parameter for %SCRIPT_CMD%"
  goto invalid_cmd_line
)
IF NOT DEFINED CREATE_VERBOSE set "CREATE_VERBOSE="
IF "!CREATE_CONFDIR!"=="" set CREATE_CONFDIR=_default
IF "!CREATE_NUM_SHARDS!"=="" set CREATE_NUM_SHARDS=1
IF "!CREATE_REPFACT!"=="" set CREATE_REPFACT=1
IF "!CREATE_CONFNAME!"=="" set CREATE_CONFNAME=!CREATE_NAME!

REM Find a port that Solr is running on
if "!CREATE_PORT!"=="" (
  for /f "usebackq" %%i in (`dir /b "%SOLR_TIP%\bin" ^| findstr /i "^solr-.*\.port$"`) do (
    set SOME_SOLR_PORT=
    For /F "Delims=" %%J In ('type "%SOLR_TIP%\bin\%%i"') do set SOME_SOLR_PORT=%%~J
    if NOT "!SOME_SOLR_PORT!"=="" (
      for /f "tokens=2,5" %%j in ('netstat -aon ^| find "TCP " ^| find ":0 " ^| find ":!SOME_SOLR_PORT! "') do (
        IF NOT "%%k"=="0" set CREATE_PORT=!SOME_SOLR_PORT!
      )
    )
  )
)
if "!CREATE_PORT!"=="" (
  set "SCRIPT_ERROR=Could not find a running Solr instance on this host! Please use the -p option to specify the port."
  goto err
)

if "!CREATE_CONFDIR!"=="_default" (
  echo WARNING: Using _default configset with data driven schema functionality. NOT RECOMMENDED for production use.
  echo          To turn off: bin\solr config -c !CREATE_NAME! -p !CREATE_PORT! -action set-user-property -property update.autoCreateFields -value false
)

if "%SCRIPT_CMD%"=="create_core" (
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
    -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
    -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
    org.apache.solr.util.SolrCLI create_core -name !CREATE_NAME! -solrUrl !SOLR_URL_SCHEME!://%SOLR_TOOL_HOST%:!CREATE_PORT!/solr ^
    -confdir !CREATE_CONFDIR! -configsetsDir "%SOLR_TIP%\server\solr\configsets" %CREATE_VERBOSE%
) else (
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" -Dsolr.default.confdir="%DEFAULT_CONFDIR%"^
    -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
    -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
    org.apache.solr.util.SolrCLI create -name !CREATE_NAME! -shards !CREATE_NUM_SHARDS! -replicationFactor !CREATE_REPFACT! ^
    -confname !CREATE_CONFNAME! -confdir !CREATE_CONFDIR! -configsetsDir "%SOLR_TIP%\server\solr\configsets" ^
    -solrUrl !SOLR_URL_SCHEME!://%SOLR_TOOL_HOST%:!CREATE_PORT!/solr %CREATE_VERBOSE%
)

goto done

:parse_delete_args
IF [%1]==[] goto run_delete
IF "%1"=="-V" goto set_delete_verbose
IF "%1"=="-c" goto set_delete_name
IF "%1"=="-core" goto set_delete_name
IF "%1"=="-collection" goto set_delete_name
IF "%1"=="-p" goto set_delete_port
IF "%1"=="-port" goto set_delete_port
IF "%1"=="-deleteConfig" goto set_delete_config
IF "%1"=="-help" goto usage
IF "%1"=="-usage" goto usage
IF "%1"=="/?" goto usage
goto run_delete

:set_delete_verbose
set DELETE_VERBOSE="-verbose"
SHIFT
goto parse_delete_args

:set_delete_name
set DELETE_NAME=%~2
SHIFT
SHIFT
goto parse_delete_args

:set_delete_port
set DELETE_PORT=%~2
SHIFT
SHIFT
goto parse_delete_args

:set_delete_config
set DELETE_CONFIG=%~2
SHIFT
SHIFT
goto parse_delete_args

:run_delete
IF NOT DEFINED DELETE_VERBOSE set "DELETE_VERBOSE="
IF "!DELETE_NAME!"=="" (
  set "SCRIPT_ERROR=Name (-c) is a required parameter for %SCRIPT_CMD%"
  goto invalid_cmd_line
)

REM Find a port that Solr is running on
if "!DELETE_PORT!"=="" (
  for /f "usebackq" %%i in (`dir /b "%SOLR_TIP%\bin" ^| findstr /i "^solr-.*\.port$"`) do (
    set SOME_SOLR_PORT=
    For /F "Delims=" %%J In ('type "%SOLR_TIP%\bin\%%i"') do set SOME_SOLR_PORT=%%~J
    if NOT "!SOME_SOLR_PORT!"=="" (
      for /f "tokens=2,5" %%j in ('netstat -aon ^| find "TCP " ^| find ":0 " ^| find ":!SOME_SOLR_PORT! "') do (
        IF NOT "%%k"=="0" set DELETE_PORT=!SOME_SOLR_PORT!
      )
    )
  )
)
if "!DELETE_PORT!"=="" (
  set "SCRIPT_ERROR=Could not find a running Solr instance on this host! Please use the -p option to specify the port."
  goto err
)

if "!DELETE_CONFIG!"=="" (
  set DELETE_CONFIG=true
)

"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
-Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
-classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
org.apache.solr.util.SolrCLI delete -name !DELETE_NAME! -deleteConfig !DELETE_CONFIG! ^
-solrUrl !SOLR_URL_SCHEME!://%SOLR_TOOL_HOST%:!DELETE_PORT!/solr %DELETE_VERBOSE%

goto done

REM Clumsy to do the state machine thing for -d and -n, but that's required for back-compat
:parse_zk_args
IF "%1"=="-upconfig" (
  goto set_zk_op
) ELSE IF "%1"=="-V" (
  goto set_zk_verbose
) ELSE IF "%1"=="upconfig" (
  goto set_zk_op
) ELSE IF "%1"=="-downconfig" (
  goto set_zk_op
) ELSE IF "%1"=="downconfig" (
  goto set_zk_op
) ELSE IF "%1"=="cp" (
  goto set_zk_op
) ELSE IF "%1"=="mv" (
  goto set_zk_op
) ELSE IF "%1"=="rm" (
  goto set_zk_op
) ELSE IF "%1"=="ls" (
  goto set_zk_op
) ELSE IF "%1"=="mkroot" (
  goto set_zk_op
) ELSE IF "%1"=="-n" (
  goto set_config_name
) ELSE IF "%1"=="-r" (
  goto set_zk_recurse
) ELSE IF "%1"=="-configname" (
  goto set_config_name
) ELSE IF "%1"=="-d" (
  goto set_configdir
) ELSE IF "%1"=="-confdir" (
  goto set_configdir
) ELSE IF "%1"=="-z" (
  goto set_config_zk
) ELSE IF "%1"=="/?" (
  goto zk_usage
) ELSE IF "%1"=="-h" (
  goto zk_usage
) ELSE IF "%1"=="-help" (
  goto zk_usage
) ELSE IF "!ZK_SRC!"=="" (
  if not "%~1"=="" (
    goto set_zk_src
  )
) ELSE IF "!ZK_DST!"=="" (
  IF "%ZK_OP%"=="cp" (
    goto set_zk_dst
  )
  IF "%ZK_OP%"=="mv" (
    goto set_zk_dst
  )
  set ZK_DST="_"
) ELSE IF NOT "%1"=="" (
  set ERROR_MSG="Unrecognized or misplaced zk argument %1%"
  goto zk_short_usage
)
goto run_zk

:set_zk_op
set ZK_OP=%~1
SHIFT
goto parse_zk_args

:set_zk_verbose
set ZK_VERBOSE="-verbose"
SHIFT
goto parse_zk_args

:set_config_name
set CONFIGSET_NAME=%~2
SHIFT
SHIFT
goto parse_zk_args

:set_configdir
set CONFIGSET_DIR=%~2
SHIFT
SHIFT
goto parse_zk_args

:set_config_zk
set ZK_HOST=%~2
SHIFT
SHIFT
goto parse_zk_args

:set_zk_src
set ZK_SRC=%~1
SHIFT
goto parse_zk_args

:set_zk_dst
set ZK_DST=%~1
SHIFT
goto parse_zk_args

:set_zk_recurse
set ZK_RECURSE="true"
SHIFT
goto parse_zk_args

:run_zk
IF "!ZK_OP!"=="" (
  set "ERROR_MSG=Invalid command specified for zk sub-command"
  goto zk_short_usage
)

IF "!ZK_HOST!"=="" (
  set "ERROR_MSG=Must specify -z zkHost"
  goto zk_short_usage
)

IF "!ZK_OP!"=="-upconfig" (
  set ZK_OP="upconfig"
)
IF "!ZK_OP!"=="-downconfig" (
  set ZK_OP="downconfig"
)

IF "!ZK_OP!"=="upconfig" (
  IF "!CONFIGSET_NAME!"=="" (
    set ERROR_MSG="-n option must be set for upconfig"
    goto zk_short_usage
  )
  IF "!CONFIGSET_DIR!"=="" (
    set ERROR_MSG="The -d option must be set for upconfig."
    goto zk_short_usage
  )
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI !ZK_OP! -confname !CONFIGSET_NAME! -confdir !CONFIGSET_DIR! -zkHost !ZK_HOST! %ZK_VERBOSE%^
  -configsetsDir "%SOLR_TIP%/server/solr/configsets"
) ELSE IF "!ZK_OP!"=="downconfig" (
  IF "!CONFIGSET_NAME!"=="" (
    set ERROR_MSG="-n option must be set for downconfig"
    goto zk_short_usage
  )
  IF "!CONFIGSET_DIR!"=="" (
    set ERROR_MSG="The -d option must be set for downconfig."
    goto zk_short_usage
  )
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI !ZK_OP! -confname !CONFIGSET_NAME! -confdir !CONFIGSET_DIR! -zkHost !ZK_HOST! %ZK_VERBOSE%
) ELSE IF "!ZK_OP!"=="cp" (
  IF "%ZK_SRC%"=="" (
    set ERROR_MSG="<src> must be specified for 'cp' command"
    goto zk_short_usage
  )
  IF "%ZK_DST%"=="" (
    set ERROR_MSG=<dest> must be specified for 'cp' command"
    goto zk_short_usage
  )
  IF NOT "!ZK_SRC:~0,3!"=="zk:" (
    IF NOT "!%ZK_DST:~0,3!"=="zk:" (
      set ERROR_MSG="At least one of src or dst must be prefixed by 'zk:'"
      goto zk_short_usage
  )
  )
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI !ZK_OP! -zkHost !ZK_HOST! -src !ZK_SRC! -dst !ZK_DST! -recurse !ZK_RECURSE! %ZK_VERBOSE%
) ELSE IF "!ZK_OP!"=="mv" (
  IF "%ZK_SRC%"=="" (
    set ERROR_MSG="<src> must be specified for 'mv' command"
    goto zk_short_usage
  )
  IF "%ZK_DST%"=="" (
    set ERROR_MSG="<dest> must be specified for 'mv' command"
    goto zk_short_usage
  )
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI !ZK_OP! -zkHost !ZK_HOST! -src !ZK_SRC! -dst !ZK_DST! %ZK_VERBOSE%
) ELSE IF "!ZK_OP!"=="rm" (
  IF "%ZK_SRC"=="" (
    set ERROR_MSG="Zookeeper path to remove must be specified when using the 'rm' command"
    goto zk_short_usage
  )
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI !ZK_OP! -zkHost !ZK_HOST! -path !ZK_SRC! -recurse !ZK_RECURSE! %ZK_VERBOSE%
) ELSE IF "!ZK_OP!"=="ls" (
  IF "%ZK_SRC"=="" (
    set ERROR_MSG="Zookeeper path to remove must be specified when using the 'ls' command"
    goto zk_short_usage
  )
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI !ZK_OP! -zkHost !ZK_HOST! -path !ZK_SRC! -recurse !ZK_RECURSE! %ZK_VERBOSE%
) ELSE IF "!ZK_OP!"=="mkroot" (
  IF "%ZK_SRC"=="" (
    set ERROR_MSG="Zookeeper path to create must be specified when using the 'mkroot' command"
    goto zk_short_usage
  )
  "%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
  -Dlog4j.configurationFile="file:///%SOLR_SERVER_DIR%\resources\log4j2-console.xml" ^
  -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
  org.apache.solr.util.SolrCLI !ZK_OP! -zkHost !ZK_HOST! -path !ZK_SRC! %ZK_VERBOSE%
) ELSE (
  set ERROR_MSG="Unknown zk option !ZK_OP!"
  goto zk_short_usage
)
goto done

 
:run_auth
IF "%1"=="-help" goto usage
IF "%1"=="-usage" goto usage

REM Options parsing.
REM Note: With the following technique of parsing, it is not possible
REM       to have an option without a value.
set "AUTH_PARAMS=%1"
set "option="
for %%a in (%*) do (
   if not defined option (
      set arg=%%a
      if "!arg:~0,1!" equ "-" set "option=!arg!"
   ) else (
      set "option!option!=%%a"
      if "!option!" equ "-d" set "SOLR_SERVER_DIR=%%a"
      if "!option!" equ "-s" set "SOLR_HOME=%%a"
      if not "!option!" equ "-s" if not "!option!" equ "-d" (
        set "AUTH_PARAMS=!AUTH_PARAMS! !option! %%a"
      )
      set "option="
   )
)
IF "%SOLR_SERVER_DIR%"=="" set "SOLR_SERVER_DIR=%DEFAULT_SERVER_DIR%"
IF NOT EXIST "%SOLR_SERVER_DIR%" (
  set "SCRIPT_ERROR=Solr server directory %SOLR_SERVER_DIR% not found!"
  goto err
)
IF "%SOLR_HOME%"=="" set "SOLR_HOME=%SOLR_SERVER_DIR%\solr"
IF EXIST "%cd%\%SOLR_HOME%" set "SOLR_HOME=%cd%\%SOLR_HOME%"
IF NOT EXIST "%SOLR_HOME%\" (
  IF EXIST "%SOLR_SERVER_DIR%\%SOLR_HOME%" (
    set "SOLR_HOME=%SOLR_SERVER_DIR%\%SOLR_HOME%"
  ) ELSE (
    set "SCRIPT_ERROR=Solr home directory %SOLR_HOME% not found!"
    goto err
  )
)

if "!AUTH_PORT!"=="" (
  for /f "usebackq" %%i in (`dir /b "%SOLR_TIP%\bin" ^| findstr /i "^solr-.*\.port$"`) do (
    set SOME_SOLR_PORT=
    For /F "Delims=" %%J In ('type "%SOLR_TIP%\bin\%%i"') do set SOME_SOLR_PORT=%%~J
    if NOT "!SOME_SOLR_PORT!"=="" (
      for /f "tokens=2,5" %%j in ('netstat -aon ^| find "TCP " ^| find ":0 " ^| find ":!SOME_SOLR_PORT! "') do (
        IF NOT "%%k"=="0" set AUTH_PORT=!SOME_SOLR_PORT!
      )
    )
  )
)
"%JAVA%" %SOLR_SSL_OPTS% %AUTHC_OPTS% %SOLR_ZK_CREDS_AND_ACLS% -Dsolr.install.dir="%SOLR_TIP%" ^
    -Dlog4j.configurationFile="file:///%DEFAULT_SERVER_DIR%\resources\log4j2-console.xml" ^
    -classpath "%DEFAULT_SERVER_DIR%\solr-webapp\webapp\WEB-INF\lib\*;%DEFAULT_SERVER_DIR%\lib\ext\*" ^
    org.apache.solr.util.SolrCLI auth %AUTH_PARAMS% -solrIncludeFile "%SOLR_INCLUDE%" -authConfDir "%SOLR_HOME%" ^
    -solrUrl !SOLR_URL_SCHEME!://%SOLR_TOOL_HOST%:!AUTH_PORT!/solr
goto done


:invalid_cmd_line
@echo.
IF "!SCRIPT_ERROR!"=="" (
  @echo Invalid command-line option: %1
) ELSE (
  @echo ERROR: !SCRIPT_ERROR!
)
@echo.
IF "%FIRST_ARG%"=="start" (
  goto start_usage
) ELSE IF "%FIRST_ARG:~0,1%" == "-" (
  goto start_usage
) ELSE IF "%FIRST_ARG%"=="restart" (
  goto start_usage
) ELSE IF "%FIRST_ARG%"=="stop" (
  goto stop_usage
) ELSE IF "%FIRST_ARG%"=="healthcheck" (
  goto healthcheck_usage
) ELSE IF "%FIRST_ARG%"=="create" (
  goto create_usage
) ELSE IF "%FIRST_ARG%"=="create_core" (
  goto create_core_usage
) ELSE IF "%FIRST_ARG%"=="create_collection" (
  goto create_collection_usage
) ELSE IF "%FIRST_ARG%"=="zk" (
  goto zk_short_usage
) ELSE IF "%FIRST_ARG%"=="auth" (
  goto auth_usage
) ELSE IF "%FIRST_ARG%"=="status" (
  goto status_usage
) ELSE (
  goto script_usage
)

:need_java_home
@echo Please set the JAVA_HOME environment variable to the path where you installed Java 1.8+
goto done

:need_java_vers
@echo Java 1.8 or later is required to run Solr.
goto done

:err
@echo.
@echo ERROR: !SCRIPT_ERROR!
@echo.
exit /b 1

:done
ENDLOCAL
exit /b 0

REM Tests what Java we have and sets some global variables
:resolve_java_info

CALL :resolve_java_vendor

set JAVA_MAJOR_VERSION=0
set JAVA_VERSION_INFO=
set JAVA_BUILD=0

FOR /f "usebackq tokens=3" %%a IN (`^""%JAVA%" -version 2^>^&1 ^| findstr "version"^"`) do (
  set JAVA_VERSION_INFO=%%a
  REM Remove surrounding quotes
  set JAVA_VERSION_INFO=!JAVA_VERSION_INFO:"=!

  REM Extract the major Java version, e.g. 7, 8, 9, 10 ...
  for /f "tokens=1,2 delims=._-" %%a in ("!JAVA_VERSION_INFO!") do (
    if %%a GEQ 9 (
      set JAVA_MAJOR_VERSION=%%a
    ) else (
      set JAVA_MAJOR_VERSION=%%b
    )
  )

  REM Don't look for "_{build}" if we're on IBM J9.
  if NOT "%JAVA_VENDOR%" == "IBM J9" (
    for /f "delims=_ tokens=2" %%a in ("!JAVA_VERSION_INFO!") do (
      set /a JAVA_BUILD=%%a
    )
  )
)
GOTO :eof

REM Set which JVM vendor we have
:resolve_java_vendor
"%JAVA%" -version 2>&1 | findstr /i "IBM J9" > nul
if %ERRORLEVEL% == 1 ( set "JAVA_VENDOR=Oracle" ) else ( set "JAVA_VENDOR=IBM J9" )

set JAVA_VENDOR_OUT=
GOTO :eof

REM Safe echo which does not mess with () in strings
:safe_echo
set "eout=%1"
set eout=%eout:"=%
echo !eout!
GOTO :eof
