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

my $sysbench_version;

if (`sysbench --version` =~ m/0.5/) {
    $sysbench_version = "0.5x";
}elsif(`sysbench --version` =~ m/0.4/){
    $sysbench_version = "0.4x";
}else{
    print "ERROR: This Sysbench Version is not supported\n";
    exit 1;
}

my $version = "0.2";

my $ckpts = 1;

############--- OPTIONS ---###############

# Script Location
my $script_path = $FindBin::Bin . "/";

my $option_config = $script_path . "/benchbox.conf";
my $option_action = undef;
my $option_name = undef;
my $option_verbose = undef;
my $option_version = undef;
my $option_help = undef;

GetOptions (
    'c|config=s' => \$option_config,
    'a|action=s' => \$option_action,
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

# Sysbench - LUA Script
my $oltp_lua = $cnf_file->{sysbench}->{oltp_lua};
if($oltp_lua){
    Utils->trimText(\$oltp_lua);
}else{
    $oltp_lua = "oltp";
}

# Sysbench - Read Only
my $read_only = $cnf_file->{sysbench}->{read_only};
if($read_only){
    Utils->trimText(\$read_only);
}else{
    $read_only = "on"
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

#-- Benchmark

# Benchmark - Threads
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
    $OUTPUT->{info}->{sysbench} = $sysbench_version;
    $OUTPUT->{info}->{name} = $option_name;
    $OUTPUT->{info}->{filename} = $output_file;
    $OUTPUT->{info}->{hostname} = $db_host;
    $OUTPUT->{info}->{port} = $db_port;
    $OUTPUT->{info}->{datetime} = Utils->getNow();
    $OUTPUT->{info}->{threads} = \@numThreads;
    $OUTPUT->{info}->{read_only} = $read_only;
    $OUTPUT->{info}->{report_interval} = $report_interval;
    $OUTPUT->{info}->{max_time} = $max_time;
    
    my ($tps, $rds, $wrs, $rt);
    
    print "Sysbench Version: $sysbench_version; Name: " . $option_name . "; Threads: " . join(",",@numThreads) . "; Outfile: $output_file\n";
    
    # Sysbench Version 0.4x
    if ($sysbench_version eq "0.4x") {
        foreach my $threads (@numThreads){
            my $cmd = "sysbench --test=$oltp_lua --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password=$db_password --mysql-db=$db_db --mysql-table-engine=$db_engine --oltp-read-only=$read_only --num-threads=$threads $options run";  
            my $result = `$cmd`;
            if ($option_verbose) {
                print $result;
            }
            
            if ($result =~/(ERROR|FATAL)/i) {
                print "ERROR: Sysbench Error with this call : $cmd\n";
                exit 1;
            }else{
                $result =~ /total time:\s*(\d+\.?\d*)s/;
                my $total_time = $1;
                $result =~ /read:\s*(\d+)/;
                my $rds_ = $1;
                $rds_ = floor($rds_ / $total_time);
                $rds->{$threads}->{full} = $rds_;
                $rds->{$threads}->{avg} = $rds_;
                $result =~ /write:\s*(\d+)/;
                my $wrs_ = $1;
                $wrs_ = floor($wrs_ / $total_time);
                $wrs->{$threads}->{full} = $wrs_;
                $wrs->{$threads}->{avg} = $wrs_;
                $result =~ /transactions:.*\((\d+\.\d+)\s/;
                my $tps_ = $1;
                $tps->{$threads}->{full} = $tps_;
                $tps->{$threads}->{avg} = $tps_;
                $result =~ /approx\..*(\d+\.\d+)ms/;
                my $rt_ = $1;
                $rt->{$threads}->{full} = $rt_;
                $rt->{$threads}->{avg} = $rt_;
                
                print "INFO: Done with $threads Thread(s)\n";
            }
        }
    }
    
    # Sysbench Version 0.5x
    if ($sysbench_version eq "0.5x") {
        foreach my $threads (@numThreads){
            my $cmd = "sysbench --test=$oltp_lua --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password=$db_password --mysql-db=$db_db --mysql-table-engine=$db_engine --oltp-read-only=$read_only --num-threads=$threads --report-interval=$report_interval --max-time=$max_time $options run";  
            my $result = `$cmd`;
            
            if ($option_verbose) {
                print $result;
            }
            
            if ($result =~/(ERROR|FATAL)/i) {
                print "ERROR: Sysbench Error with this call : $cmd\n";
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
                
                $tps->{$threads}->{full} = \@tps;
                $rds->{$threads}->{full} = \@rds;
                $wrs->{$threads}->{full} = \@wrs;
                $rt->{$threads}->{full} = \@rt;
                
                $tps->{$threads}->{avg} = Utils->getAVG(\@tps);
                $rds->{$threads}->{avg} = Utils->getAVG(\@rds);
                $wrs->{$threads}->{avg} = Utils->getAVG(\@wrs);
                $rt->{$threads}->{avg} = Utils->getAVG(\@rt);
                
                print "INFO: Done with $threads Thread(s)\n";
            }
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
    
}else{
    my $cmd = "sysbench --test=$oltp_lua --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password=$db_password --mysql-db=$db_db --mysql-table-engine=$db_engine $options --oltp-table-size=$table_size $option_action";  
    my $result = `$cmd`;
    if ($result =~ m/(ERROR|FATAL)/) {
        print "ERROR: Sysbench Error with this call : $cmd\n";
        exit 1;
    }else{
        print "INFO: Done\n";
    }
}


