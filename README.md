## CloudBees Test Runner (CBRT)

![](images/cloudbees.gif)

### WHAT IT IS:

This is the solution to take-home exercise **Part I**.

Solution to **Part II** can be found in [Risk Analysis](docs/risk_analysis.pdf) pdf file located inside docs subfolder.

This is a simple script that automates the setup of acceptance test harness (ATH) in order to run tests with a specifc jenkins version. 

### REQUIREMENTS:

CBRT requires:
* Mac-OSx
* Java 8
* Curl
* Chrome
* IntelliJ IDEA, if running IDE

#### WHY?
* Script was developed using my personal Mac laptop.
* Java, Chrome and Curl require admin priviledges to be installed.
* Java 8 is required due to compatibility with the specific checked-out code revision.
* I chose Chrome as it is one of most used and spread web explorers.
* Rest of dependecies like maven, chromedriver, jenkins war and ATH code are fetched using  curl.

### HOW TO USE IT:
1. FIRST,  clone the sources.
2. SECOND, Run ```./run_test.sh ``` and it will setup everything:
	* Download dependecies
	* Setup dependecies 
	* Run test
	* Generate and open test report
3. THIRD, Run ```./run_test.sh -h``` to get some help about usage.

### OBSERVATIONS:
* Specific ATH revision is checked-out as it is known to be compatible with Jenkins 2.61.
* CBTR offers the possibility of running test using different versions of Jenkins, Maven and Chrome driver.
* First time running would take longer as needs to setup everything. Consecutives runs would be faster as eveything is already setup.

### EXAMPLES OF USAGE:

``` bash
Juans-MacBook-Pro:cloudbees jmcruz$ ./run_test.sh -h
Usage: run_test.sh options (-c chromedriver_version) (-m mvn_version) (-j jenkins_version) (-t test_name) (-d) (-n) (-u) (-h)
-c chromedriver_version  :  specify chrome driver version (default 2.36)
-m mvn_version           :  specify mvn version (default 3.5.2)
-j jenkins_version       :  specify jenkins version (default 2.61)
-t test_name             :  specify test to run (default ScriptTest)
-d                       :  enable verbose output
-n                       :  skip tests and run IDE
-u                       :  clean-up before testing
-h                       :  show this help
```

### RUNNING IDE
You can avoid to run test automatically and open the IDE. For this you need to run following command ```./run_test.sh -n```.

This option allows you to debug and run test manually on the IntelliJ IDEA IDE.
![](images/cloudbees_ide.gif)