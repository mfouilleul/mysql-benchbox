#!/usr/bin/perl -w
use strict;

#Config
use Getopt::Long qw(:config no_ignore_case);
use FindBin;

use POSIX;

use modules::Config::Tiny;
use modules::Utils;

use JSON;

use DBI;

if (!`which sysbench`) {
    print "ERROR: Sysbench isn't installed\n";
    exit 1;
}

my $sysbench_version = `sysbench --version`;

if ($sysbench_version =~ m/(0.5)/) {
    $sysbench_version = $1;
}else{
    print "ERROR: This Sysbench Version is not supported\n";
    exit 1;
}

my $version = "0.4";

my $ckpts = 1;

############--- OPTIONS ---###############

# Script Location
my $script_path = $FindBin::Bin . "/";

my $option_config = $script_path . "/benchbox.conf";
my $option_name = undef;
my $option_verbose = undef;
my $option_version = undef;
my $option_help = undef;

GetOptions (
    'c|config=s' => \$option_config,
    'v|verbose' => \$option_verbose,
    'version' => \$option_version,
    'n|name=s' => \$option_name,
    'h|help' => \$option_help
)or die exit(1);

if($option_version){
    print "BenchBox v$version\n";
    exit 0;
}

if($option_help){
    Utils->printHelp($version);
    exit 1;
}

my $option_name_tr = "";

if ($option_name) {
    $option_name_tr = $option_name;
    $option_name_tr =~ tr/[A-Z]/[a-z]/;
    $option_name_tr =~ tr/-/_/;
    $option_name_tr =~ tr/ /_/;
    $option_name_tr = "_" . $option_name_tr;
}else{
    $option_name = "Unnamed";
}

############--- CONFIGURATION FILE ---###############

unless (-e $option_config){
    print "ERROR: Configuration File Doesn't Exist!\n";
    exit 1;
}

my $cnf_file = Config::Tiny->new();
$cnf_file = Config::Tiny->read( $option_config );

#-- MySQL

# MySQL - Host
my $db_host = $cnf_file->{mysql}->{host};
if($db_host){
    Utils->trimText(\$db_host);
}else{
    print "ERROR: Configuration File : MySQL Host is not set\n";
    exit 1;
}

# MySQL - User
my $db_user = $cnf_file->{mysql}->{user};
if($db_user){
    Utils->trimText(\$db_user);
}else{
    print "ERROR: Configuration File : MySQL User is not set\n";
    exit 1;
}

# MySQL - Password
my $db_password = $cnf_file->{mysql}->{password};
if($db_password){
    Utils->trimText(\$db_password);
}else{
    $db_password = "";
}

# MySQL - Port
my $db_port = $cnf_file->{mysql}->{port};
if($db_port){
    Utils->trimText(\$db_port);
}else{
    $db_port = 3306;
}

# MySQL - DB
my $db_db = $cnf_file->{mysql}->{db};
if($db_db){
    Utils->trimText(\$db_db);
}else{
    print "ERROR: Configuration File : MySQL DB is not set\n";
    exit 1;
}

# MySQL - Engine
my $db_engine = $cnf_file->{mysql}->{table_engine};
if($db_engine){
    Utils->trimText(\$db_engine);
}else{
    $db_engine = "InnoDB"
}

#-- Sysbench

# Sysbench - LUA Script
my $lua_script = $cnf_file->{sysbench}->{lua_script};
if($lua_script){
    Utils->trimText(\$lua_script);
}else{
    $lua_script = "oltp";
}

# Sysbench - Table Count
my $tables_count = $cnf_file->{sysbench}->{tables_count};
if($tables_count){
    Utils->trimText(\$tables_count);
}else{
    $tables_count = 1
}

# Sysbench - Table Size
my $table_size = $cnf_file->{sysbench}->{table_size};
if($table_size){
    Utils->trimText(\$table_size);
}else{
    $table_size = 10000
}

# Sysbench - Report Interval
my $report_interval = $cnf_file->{sysbench}->{report_interval};
if($report_interval){
    Utils->trimText(\$report_interval);
}else{
    $report_interval = 1;
}

# Sysbench - Max Time
my $max_time = $cnf_file->{sysbench}->{max_time};
if($max_time){
    Utils->trimText(\$max_time);
    $max_time++;
}else{
    $max_time = 4;
}

# Sysbench - Options
my $options = $cnf_file->{sysbench}->{options};
if($options){
    Utils->trimText(\$options);
}else{
    $options = "";
}

#-- BenchBox

# BenchBox - Threads
my $numThreads_str = $cnf_file->{benchbox}->{num_threads};
my @numThreads = ();
if($numThreads_str){
    if ($numThreads_str =~ /\[(\d+)\.\.(\d+)\]/) {
        for (my $i = $1; $i <= $2; $i++){
            push(@numThreads, $i);
        }
    }else{
        Utils->trimText(\$numThreads_str);
        @numThreads = split(/,/, $numThreads_str);
    }
    
}else{
    $numThreads[0] = 1
}

# BenchBox - Output
my $output = $cnf_file->{benchbox}->{output};
if($output){
    Utils->trimText(\$output);
}else{
    $output = $script_path
}

# BenchBox - SHOW VARIABLES
my $show_variables = $cnf_file->{benchbox}->{show_variables};
if($show_variables){
    Utils->trimText(\$output);
    if ($show_variables =~ m/(yes|1|on)/i) {
        $show_variables = 1;
    }else{
        $show_variables = 0;
    }
}else{
    $show_variables = 0;
}

unless (-e $output){
    print "ERROR: Ouput Dir Doesn't Exist!\n";
    exit 1;
}

my $output_file = "$output/" . Utils->getNowCondensed() . "_" . $db_host . "_" . $db_port . $option_name_tr . ".json";

my $OUTPUT;
$OUTPUT->{info}->{sysbench} = $sysbench_version;
$OUTPUT->{info}->{name} = $option_name;
$OUTPUT->{info}->{filename} = $output_file;
$OUTPUT->{info}->{hostname} = $db_host;
$OUTPUT->{info}->{port} = $db_port;
$OUTPUT->{info}->{datetime} = Utils->getNow();
$OUTPUT->{info}->{threads} = \@numThreads;
$OUTPUT->{info}->{report_interval} = $report_interval;
$OUTPUT->{info}->{max_time} = $max_time;


# Show Variables	
my $dsn = "DBI:mysql:database=$db_db;host=$db_host;port=$db_port;mysql_connect_timeout=10;mysql_read_timeout=10";
my $dbh = DBI->connect($dsn, $db_user, $db_password);
my $sth = $dbh->prepare("SELECT lower(VARIABLE_NAME), VARIABLE_VALUE FROM information_schema.GLOBAL_VARIABLES");
$sth->execute;
my $result = $sth->fetchall_arrayref();
my @variables;    
foreach ( @$result ) {
    my $variable = {
                    n => $$_[0],
                    v => $$_[1]
                };
    push(@variables,$variable);
}
$OUTPUT->{variables} = \@variables;

my ($tps, $rds, $wrs, $rt);

print "Sysbench Version: $sysbench_version; Name: " . $option_name . "; Outfile: $output_file\n";

if ($sysbench_version =~ m/0.5/) {
    my $cmd = "sysbench --test=$lua_script --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password=$db_password --mysql-db=$db_db --mysql-table-engine=$db_engine $options --oltp-tables-count=$tables_count --oltp-table-size=$table_size prepare";  
    my $result = `$cmd`;
    if ($result =~ m/(ERROR|FATAL)/) {
        print $result;
        exit 1;
    }else{
        print "INFO: Prepare\n";
    }
    
    foreach my $threads (@numThreads){
        $cmd = "sysbench --test=$lua_script --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password=$db_password --mysql-db=$db_db --mysql-table-engine=$db_engine --oltp-tables-count=$tables_count --num-threads=$threads --report-interval=$report_interval --max-time=$max_time $options run";  
        my $result = `$cmd`;
        
        if ($option_verbose) {
            print $result;
        }
        
        if ($result =~/(ERROR|FATAL)/i) {
            print $result;
            exit 1;
        }else{
            my @lines = split("\n", $result);
            
            my @tps = ();
            my @rds = ();
            my @wrs = ();
            my @rt = ();
            
            my $lines_ckpt = 0;
            
            foreach my $line (@lines){
                if ($line =~ /\[.*\](.*)/) {
                    $lines_ckpt++;
                    my $checkpoint = $1;
                    
                    $checkpoint =~ /threads: \d+, tps: (\d+\.\d+), reads\/s: (\d+\.\d+), writes\/s: (\d+\.\d+), response time: (\d+\.\d+)ms \(95%\)/;
                    
                    my ($tps_, $rds_, $wrs_, $rt_) = ($1, $2, $3, $4);
                    
                    push(@tps, $tps_);
                    push(@rds, $rds_);
                    push(@wrs, $wrs_);
                    push(@rt, $rt_);
                    
                }
            }
            
            if ($ckpts == 1 || $ckpts > $lines_ckpt) {
                $ckpts = $lines_ckpt;
            }
            
            #$tps->{$threads}->{full} = \@tps;
            #$rds->{$threads}->{full} = \@rds;
            #$wrs->{$threads}->{full} = \@wrs;
            #$rt->{$threads}->{full} = \@rt;
            
            $tps->{$threads}->{avg} = Utils->getAVG(\@tps);
            $rds->{$threads}->{avg} = Utils->getAVG(\@rds);
            $wrs->{$threads}->{avg} = Utils->getAVG(\@wrs);
            $rt->{$threads}->{avg} = Utils->getAVG(\@rt);
            
            print "INFO: Done with $threads Thread(s)\n";
        }
    }
    
    $cmd = "sysbench --test=$lua_script --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password=$db_password --mysql-db=$db_db --mysql-table-engine=$db_engine $options --oltp-tables-count=$tables_count --oltp-table-size=$table_size cleanup";  
    $result = `$cmd`;
    if ($result =~ m/(ERROR|FATAL)/) {
        print $result;
        exit 1;
    }else{
        print "INFO: Cleanup\n";
    }
}

$OUTPUT->{info}->{ckpts} = $ckpts;
$OUTPUT->{bench}->{tps} = $tps;
$OUTPUT->{bench}->{rds} = $rds;
$OUTPUT->{bench}->{wrs} = $wrs;
$OUTPUT->{bench}->{rt} = $rt;

# Write Output
open (OUTFILE, ">>$output_file");
print OUTFILE to_json($OUTPUT);
close (OUTFILE);
