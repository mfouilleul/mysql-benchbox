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
    my ( $self, $version, $os) = @_;
    
    print "Glimpsee Agent (" . $$version . ") \n\n";
    
    print "Usage: glimpsee [OPTIONS]\n\n";
    
    print "  -h, --help		Display this help.\n";
    print "  -c, --config		Manually specify a glimpsee.cnf file (Default value is <glimpsee dir>/etc/glimpsee.cnf).\n";
    print "  -d, --daemonize	Fork to the background and detach from the shell.\n";
    print "  --stop		Stop a running Glimpsee Agent\n";
    print "  --status		Check the Glimpsee Agent status\n";
    print "  -v, --version		Output version information.\n";
    
    print "\n";
}

1;