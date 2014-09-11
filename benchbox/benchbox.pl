#!/usr/bin/perl -w
use strict;

#Config
use Getopt::Long qw(:config no_ignore_case);
use FindBin;

use POSIX;

use modules::Config::Tiny;
use modules::Utils;

use JSON;

if (!`which sysbench`) {
    print "ERROR: Sysbench isn't installed\n";
    exit 1;
}

my $version = "0.1";

############--- OPTIONS ---###############

# Script Location
my $script_path = $FindBin::Bin . "/";

my $option_config = $script_path . "/benchbox.conf";
my $option_action = undef;
my $option_name = undef;
my $option_verbose = undef;
my $option_version = undef;

GetOptions (
    'c|config=s' => \$option_config,
    'a|action=s' => \$option_action,
    'v|verbose' => \$option_verbose,
    'version' => \$option_version,
    'n|name=s' => \$option_name
)or die exit(1);

if($option_version){
    print "BenchBox v$version\n";
    exit 0;
}

if($option_action){
    
    if ($option_action !~ m/(prepare|run|cleanup)/) {
        print "ERROR: uknown action \"$option_action\"\n";
        exit 1;
    }
    
}else{
    print "ERROR: Please specify an action (prepare, run or cleanup)\n";
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

# Sysbench - Read Only
my $read_only = $cnf_file->{sysbench}->{read_only};
if($read_only){
    Utils->trimText(\$read_only);
}else{
    $read_only = "on"
}

# Sysbench - Options
my $options = $cnf_file->{sysbench}->{options};
if($options){
    Utils->trimText(\$options);
}else{
    $options = "";
}

# Sysbench - Table Size
my $table_size = $cnf_file->{sysbench}->{table_size};
if($table_size){
    Utils->trimText(\$table_size);
}else{
    $table_size = 10000
}

#-- Benchmark

# Benchmark - Threads
my $numThreads_str = $cnf_file->{benchbox}->{num_threads};
my @numThreads = ();
if($numThreads_str){
    Utils->trimText(\$numThreads_str);
    @numThreads = split(/,/, $numThreads_str);
}else{
    $numThreads[0] = 1
}

# Benchmark - Output
my $output = $cnf_file->{benchbox}->{output};
if($output){
    Utils->trimText(\$output);
}else{
    $output = $script_path
}

unless (-e $output){
    print "ERROR: Ouput Dir Doesn't Exist!\n";
    exit 1;
}

if ($option_action eq "run") {
    
    my $output_file = "$output/" . Utils->getNowCondensed() . "_" . $db_host . "_" . $db_port . $option_name_tr . ".json";
    
    my $OUTPUT;
    $OUTPUT->{info}->{name} = $option_name;
    $OUTPUT->{info}->{filename} = $output_file;
    $OUTPUT->{info}->{hostname} = $db_host;
    $OUTPUT->{info}->{port} = $db_port;
    $OUTPUT->{info}->{datetime} = Utils->getNow();
    $OUTPUT->{info}->{threads} = \@numThreads;
    my @d = ();
    my @rds = ();
    my @wrs = ();
    my @tps = ();
    my @rt = ();
    
    print "Name: " . $option_name . "; Threads: " . join(",",@numThreads) . "; Outfile: $output_file\n";
    foreach my $threads (@numThreads){
        my $cmd = "sysbench --test=oltp --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password=$db_password --mysql-db=$db_db --mysql-table-engine=$db_engine --oltp-read-only=$read_only --num-threads=$threads $options run";  
        my $result = `$cmd`;
        
        if ($option_verbose) {
            print $result;
        }
        
        if ($result =~/ERROR/i) {
            print "ERROR: Sysbench Error with this call : $cmd\n";
            exit 1;
        }else{
            $result =~ /total time:\s*(\d+\.?\d*)s/;
            my $total_time = $1;
            push(@d, $total_time);
            $result =~ /read:\s*(\d+)/;
            my $reads = $1;
            $reads = floor($reads / $total_time);
            push(@rds, $reads);
            $result =~ /write:\s*(\d+)/;
            my $writes = $1;
            $writes = floor($writes / $total_time);
            push(@wrs, $writes);
            $result =~ /transactions:.*\((\d+\.\d+)\s/;
            my $tps = $1;
            push(@tps, $tps);
            $result =~ /approx\..*(\d+\.\d+)ms/;
            my $resp_time = $1;
            push(@rt, $resp_time);
            
            print "INFO: Done with $threads Thread(s)\n";
        }
    }
    
    $OUTPUT->{bench}->{d} = \@d;
    $OUTPUT->{bench}->{rds} = \@rds;
    $OUTPUT->{bench}->{wrs} = \@wrs;
    $OUTPUT->{bench}->{tps} = \@tps;
    $OUTPUT->{bench}->{rt} = \@rt;
    
    # Write Output
    open (OUTFILE, ">>$output_file");
    print OUTFILE to_json($OUTPUT);
    close (OUTFILE);
    
}else{
    my $cmd = "sysbench --test=oltp --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password=$db_password --mysql-db=$db_db --mysql-table-engine=$db_engine $options --oltp-table-size=$table_size $option_action";  
    my $result = `$cmd`;
    
    if ($result =~/ERROR/) {
        print "ERROR: Sysbench Error with this call : $cmd\n";
        exit 1;
    }else{
        print "INFO: Done\n";
    }
}

