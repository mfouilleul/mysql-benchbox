# About

BenchBox allows you to automate, archive and visualize your MySQL benchmarks did with SysBench (oltp tests).
It is composed by a set of Perl scripts and a Web Interface. The SysBench versions currently supported by BenchBox are 0.4x and 0.5.

![Charts](https://raw.githubusercontent.com/mfouilleul/BenchBox/master/screenshots/2.png)

# SysBench
"[SysBench](https://launchpad.net/sysbench) is a modular, cross-platform and multi-threaded benchmark tool for evaluating OS parameters that are important for a system running a database under intensive load."

SysBench is written in C and released under the GNU GPL v2 licence.

# Download

BenchBox is released as open source and is available at [GitHub](https://github.com/mfouilleul/benchbox).
Find official releases in [https://github.com/mfouilleul/benchbox/releases](https://github.com/mfouilleul/benchbox/releases).

# Requirements

BenchBox is based on SysBench, the versions currently supported are SysBench 0.4x and SysBench 0.5 (Recommended).

Prerequisites for BenchBox Perl Scripts:
- SysBench 0.4x or higher
- Perl v5.8 or higher
- Perl modules DBI and DBD::mysql

Prerequisites for BenchBox Web Interface:
- Web Server (Apache, NginX...)
- PHP

# Quickstart

Note that the installation of the BenchBox requirements (SysBench, Web Server...) are not covered here.

Our setup for this Quickstart:
- Debian 6
- SysBench 0.5
- Apache2 + PHP5 (Web Server)
- Perl v5.16

## Installation

Download the latest BenchBox version from [https://github.com/mfouilleul/benchbox/releases](https://github.com/mfouilleul/benchbox/releases).
Unpack the BenchBox archive directly in your Web Server document root:

```
cd /var/www/
wget https://github.com/mfouilleul/BenchBox/archive/beta.tar.gz
tar -xzvf beta.tar.gz
cd BenchBox-beta/
chown -R www-data:www-data *
```

Here is the BenchBox architecture
```
root@seksi-srv:/var/www/BenchBox-beta# ll
total 28
drwxrwxr-x 3 www-data www-data 4096 Sep 12 21:09 benchbox-scripts
drwxrwxr-x 2 www-data www-data 4096 Sep 12 21:09 css
drwxrwxr-x 2 www-data www-data 4096 Sep 12 21:09 fonts
-rw-rw-r-- 1 www-data www-data 3800 Sep 12 21:09 index.php
drwxrwxr-x 2 www-data www-data 4096 Sep 12 21:09 js
drwxrwxr-x 2 www-data www-data 4096 Sep 12 21:09 json
-rw-rw-r-- 1 www-data www-data  254 Sep 12 21:09 README.md
drwxrwxr-x 2 www-data www-data 4096 Sep 12 21:09 screenshots
```

- **benchbox-scripts**: BenchBox Perl Scripts.
- **json**: Benchmark Outfiles.

## Configuration

The configuration file is splitted in three parts:
```
# cd benchbox-scripts/
vi benchbox.conf

[benchbox]
num_threads=2,4,6,8,16,32,64,128,256
output=../json
show_variables=1

[sysbench]
oltp_lua=/usr/local/sysbench/tests/db/oltp.lua
read_only=on
tables_count=4
table_size=100000
report_interval=1
max_time=3
options=--oltp-test-mode=simple --oltp-reconnect-mode=session

[mysql]
host=127.0.0.1
port=3306
user=mfo
password=
db=sysbench
table_engine=InnoDB
```
**benchbox**

- num_threads: Number of threads used by SysBench. The [1..16] notation is also available = increment by 1 from 1 to 16 threads.
- output: Outfiles directory
- show_variables: dump MySQL variables during benchmark

**sysbench**

- oltp_lua: SysBench OLTP lua script
- read_only: Enable/Disable SELECT only on SysBench transactions
- tables_count: Number of tables on which Sysbench will work
- table_size: 
- report_interval: Number of seconds between two SysBench checkpoints
- max_time: Duration (in sec) of the SysBench tests
- options: Add your SysBench options here

**mysql**

- host: MySQL target Server
- port:
- user: MySQL user used by SysBench 
- password:
- db: Database use by SysBench
- table_engine:

## MySQL User and Schema

Before started BenchBox, you should create the Sysbench user and schema on the target databases (as specified in the benchbox.conf): 

```
CREATE DATABASE sysbench;
```

```
GRANT ALL PRIVILEGES ON sysbench.* TO sysbench;
```

## Execution

```
# perl benchbox.pl --help
BenchBox v0.3

Usage: perl benchbox.pl [OPTIONS]

  -h, --help                     Display this help.
  -n=STRING,--name=STRING        Name your bench.
  -c, --config                   Manually specify a benchbox.conf file (Default value is <benchbox dir>/benchbox.conf).
  -v, --version                  Output version information.
  --verbose                      Print SysBench Outputs.
```

### Run
```
# perl benchbox.pl -n "My First Test"
Sysbench Version: 0.5x; Name: My First Test; Threads: 3,4,5; Outfile: ../json/20140914120605_127.0.0.1_3306_my_first_test.json
INFO: Prepare
INFO: Run with 3 Thread(s)
INFO: Run with 4 Thread(s)
INFO: Run with 5 Thread(s)
INFO: Cleanup
```

# BenchBox Web Interface

The BenchBox Interface is a single page interface.
Firstly we'll have the list of your benchmarks, you can filtered them via the Search Bar on the top.

![List](https://raw.githubusercontent.com/mfouilleul/BenchBox/master/screenshots/1.png)

Click on a benchmark (.json) to show its details and charts.

![Charts](https://raw.githubusercontent.com/mfouilleul/BenchBox/master/screenshots/2.png)

# Bugs
Please report bugs on the [Issues page](https://github.com/mfouilleul/benchbox/issues)
