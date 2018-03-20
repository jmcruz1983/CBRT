#!/bin/bash

trap tear_down INT TERM EXIT

set -e

export PATH=/usr/local/bin:$PATH

#BINs
git_bin=`which git`
kill_bin=`which kill`
curl_bin=`which curl`
find_bin=`which find`
mkdir_bin=`which mkdir`
unzip_bin=`which unzip`

# VARs
debug=false
clean_up=false
mvn_ver=3.5.2
skip_tests=false
test_name=ScriptTest
jenkins_ver=2.61
chromedriver_ver=2.36
no_color='\033[0m'
green_color='\e[92m'
java_home_18=$(find /Library/Java -name 'Home' | grep 1.8)
git_rev=63fa5aeaa3b59492ce4ea8f11ceab243e4a8afb8

# DIRs
base_dir=$( cd "$( dirname "$0" )" && pwd )
bin_dir=$base_dir/binaries
dw_dir=$base_dir/downloads
harness_dir=$base_dir/harness

usage()
{
	echo "Usage: `basename $0` options (-c chromedriver_version) (-m mvn_version) (-j jenkins_version) (-t test_name) (-d) (-n) (-u) (-h)";
	echo "-c chromedriver_version  :  specify chrome driver version (default $chromedriver_ver)"
	echo "-m mvn_version           :  specify mvn version (default $mvn_ver)"
	echo "-j jenkins_version       :  specify jenkins version (default $jenkins_ver)"
	echo "-t test_name             :  specify test to run (default $test_name)"
	echo "-d                       :  enable verbose output"
	echo "-n                       :  skip tests and run IDE"
	echo "-u                       :  clean-up before testing"
	echo "-h                       :  show this help"
}

tear_down(){
    # Tear-down environment
    if [ ! -z "$JUT_PID" ]; then
        $kill_bin -9 $JUT_PID
    fi
    pid_list=$(ps -ef | grep -i chrome | grep -v grep | awk '{print $2}')
    if [ ! -z "$pid_list" ]; then
        $kill_bin -9 $pid_list
    fi
}

run_jut_server(){
    # Setup jut server
    counter=30
    jut_server_log=$bin_dir/jut_server.log
    jut_server_bin=$harness_dir/target/appassembler/bin/jut-server
    export JENKINS_WAR=$jenkins_war
    chmod u+x $jut_server_bin
    ($jut_server_bin &> $jut_server_log) &
    jut_pid=$!
    export JUT_PID=$jut_pid
    while ! grep "Jenkins is running" $jut_server_log
    do
        sleep 1
        let counter=counter-1
        if [ $counter -eq 0 ]; then
            break;
        fi
    done
}

run_ide(){
    # Run IDE
    idea_log=$bin_dir/idea.log
    idea_bin=$($find_bin /Applications -type f -name idea -print -quit)
    "$idea_bin" &> $idea_log
}

print_green(){
    printf "$green_color$1$no_color\n"
}

while getopts "c:m:j:t:dnuh" option; do
    case $option in
        c )
            chromedriver_ver=$OPTARG
            ;;
        m )
            mvn_ver=$OPTARG
            ;;
        j )
            jenkins_ver=$OPTARG
            ;;
        t )
            test_name=$OPTARG
            ;;
        d )
            set -x
            debug=true
            ;;
        n )
            skip_tests=true
            ;;
        u )
            clean_up=true
            ;;
        * | h )
            usage
            exit 0
            ;;
    esac
done

mvn_ver_major=${mvn_ver%%.*}

#URLs
war_url="http://mirrors.jenkins.io/war/$jenkins_ver/jenkins.war"
repo_url="https://github.com/jenkinsci/acceptance-test-harness.git"
chromedriver_url="https://chromedriver.storage.googleapis.com/$chromedriver_ver/chromedriver_mac64.zip"
mvn_url="http://ftp.cixug.es/apache/maven/maven-$mvn_ver_major/$mvn_ver/binaries/apache-maven-$mvn_ver-bin.zip"

print_green "> Settings"
echo "> DEBUG=$debug"
echo "> TEST=$test_name"
echo "> MVN_VERSION=$mvn_ver"
echo "> JENKINS_VERSION=$jenkins_ver"
echo "> CHROMEDRIVER_VERSION=$chromedriver_ver"
echo "> GIT_REVISION=$git_rev"

# Cleanup
if [ $clean_up == true ]; then
    print_green "> Cleanup dependencies"
    rm -rf $bin_dir
    rm -rf $harness_dir
fi

#Download dependencies
print_green "> Downloading dependencies"
$mkdir_bin -p $dw_dir
$mkdir_bin -p $bin_dir

# Setup maven
mvn_home=$bin_dir/apache-maven-$mvn_ver
if [ ! -d $mvn_home ]; then
    # Download maven
    mvn_zip=$dw_dir/apache-maven-$mvn_ver-bin.zip
    print_green "> Setting Up Maven Version $mvn_ver"
    if [ ! -f $mvn_zip ]; then
        $curl_bin -s -o $mvn_zip $mvn_url
    fi
    # Extract maven
    if [ -f $mvn_zip ]; then
        $unzip_bin -qq -o $mvn_zip -d $bin_dir
    fi
fi
# Add to path mvn home
if [ -d $mvn_home ]; then
  export PATH=$mvn_home/bin:$PATH
fi

# Download jenkins
jenkins_war=$dw_dir/jenkins-$jenkins_ver.war
if [ ! -f $jenkins_war ] ; then
    print_green "> Downloading Jenkins Version $jenkins_ver"
    $curl_bin -L -s -o $jenkins_war $war_url
fi

# Setup chromedriver
chromedriver_home=$bin_dir/chrome_driver_$chromedriver_ver
if [ ! -d $chromedriver_home ]; then
    # Download chromedriver
    chromedriver_zip=$dw_dir/chromedriver_$chromedriver_ver.zip
    print_green "> Setting Up Chrome Driver Version $chromedriver_ver"
    if [ ! -f $chromedriver_zip ]; then
        $curl_bin -s -o $chromedriver_zip $chromedriver_url
    fi
    # Extract maven
    if [ -f $chromedriver_zip ]; then
        $unzip_bin -qq -o $chromedriver_zip -d $chromedriver_home
    fi
fi
# Add to path mvn home
if [ -d $chromedriver_home ]; then
  export PATH=$chromedriver_home:$PATH
fi

# Code checkout
if [ ! -d $harness_dir ]; then
   $git_bin clone $repo_url $harness_dir --quiet
fi

# Set specific revision
cd $harness_dir
$git_bin checkout $git_rev --quiet

# Set JAVA_HOME
export JAVA_HOME=$java_home_18

# Setup maven depencencies
mvn_bin=`which mvn`

# Maven cleanup
if [ $clean_up == true ]; then
    print_green "> Run mvn cleanup"
    $mvn_bin -q clean
fi

# Install maven depencencies
print_green "> Setup mvn dependencies"
$mvn_bin -q install -DskipTests

# Run JUT server
print_green "> Starting JUT server with Jenkins Version $jenkins_ver"
run_jut_server
print_green "> JUT server is ready!"
export BROWSER=chrome

if [ $skip_tests == true ]; then
    print_green "> Starting IDE"
    $mvn_bin -q generate-resources
    run_ide
else
    print_green "> Running $test_name"
    $mvn_bin -q surefire-report:report -Dtest=$test_name

    print_green "> Generate test report"
    # Need to run site like this to avoid NoClassDefFoundError with DependencyFilter
    $mvn_bin -q org.apache.maven.plugins:maven-site-plugin:2.2:site

    print_green "> Open test report"
    open $harness_dir/target/site/surefire-report.html
fi

