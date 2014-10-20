##########
#Class Utils
##########
package Utils;

use strict;

use POSIX qw(strftime);
    
sub trimText{
    my ($self, $text) = @_;
    #Cleaning
    $$text =~ s/^\s+//;
    $$text =~ s/\s+$//; 
    $$text =~ s/\r\n$/\n/;
    chomp($$text);
}

sub getNow{
    my ($self) = @_;
    my $now_string = strftime "%Y-%m-%d %H:%M:%S", localtime;
    return $now_string;
}

sub getNowCondensed{
    my ($self) = @_;
    my $now_string = strftime "%Y%m%d%H%M%S", localtime;
    return $now_string;
}

sub printHelp{
    my ( $self, $version) = @_;
    
    print "BenchBox v$version\n\n";
    
    print "Usage: perl benchbox.pl [OPTIONS]\n\n";
    
    print "  -h, --help                     Display this help.\n";
    print "  -a=STRING,--action=STRING      BenchBox Action: [auto], prepare, cleanup, run.\n";
    print "  -n=STRING,--name=STRING        Name your bench.\n";
    print "  -c, --config                   Manually specify a benchbox.conf file (Default value is <benchbox dir>/benchbox.conf).\n";
    print "  -v, --version                  Output version information.\n";
    print "  --verbose                      Print SysBench Outputs.\n";
    
    print "\n";
}

sub getAVG{
    my ($self, $list) = @_;
    my $avg;
    foreach(@{$list}){
        $avg += $_;
    }
    
    $avg = $avg / (scalar @$list);
    
    return $avg;
}

1;
