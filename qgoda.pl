#! /usr/bin/env perl

use strict;

sub usage_error;
sub display_usage;

use Getopt::Long;

use Qgoda;
use Locale::TextDomain qw(com.cantanea.qgoda);

my %options;
GetOptions (
            'w|watch' => \$options{watch},
            'q|quiet' => \$options{quiet},
	    'h|help' => \$options{help},
	    'v|verbose' => \$options{verbose},
	    ) or exit 1;

display_usage if $options{help};

my $method = $options{watch} ? 'watch' : 'build';
Qgoda->new(%options)->$method;

sub display_usage {
    my $msg = __x('Usage: {program} [OPTIONS]
Mandatory arguments to long options, are mandatory to short options, too.

  -w, --watch                 watch for changes
  -q, --quiet                 quiet mode
  -h, --help                  display this help and exit
  -v, --verbose               display progress on standard error

The Qgoda static site generator renders your site by default into the
directory "_site" inside the current working directory.
', program => $0);

    print $msg;

    exit 0;
}

sub usage_error {
    my $message = shift;
    if ($message) {
        $message =~ s/\s+$//;
        $message = "$0: $message\n";
    }
    else {
        $message = '';
    }
    die <<EOF;
${message}Usage: $0 [OPTIONS]
Try '$0 --help' for more information!
EOF
}
