#! /bin/false

# Copyright (C) 2016 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Qgoda::Splitter;

use strict;

use Locale::TextDomain qw('com.cantanea.qgoda');
use YAML::XS;

use Qgoda::Util qw(empty front_matter read_body);

sub new {
    my ($class, $path) = @_;

    my $front_matter = front_matter $path;
    if (!defined $front_matter) {
        my $error = $! ? $! : __"no front matter";
        die __x("error reading front matter from '{filename}': {error}\n",
                filename => $path. error => $error);    
    }
    my $meta = YAML::XS::Load($front_matter);

    my $body = read_body $path;
    if (!defined $front_matter) {
        my $error = $! ? $! : __"no body found";
        die __x("error reading body from '{filename}': {error}\n",
                filename => $path. error => $error);    
    }

    my @first =  grep { !empty } split /
                (
                <!--QGODA-XGETTEXT-->(?:.*?)<!--\/QGODA-XGETTEXT-->
                |
                [ \011-\015]*
                \n
                [ \011-\015]*
                \n
                [ \011-\015]*
                )
                /sx, $body;

    my @chunks;
    foreach my $chunk (@first) {
        if ($chunk =~ /^[ \011-\015]+$/) {
            push @chunks, $chunk;
        } else {
            my $head = $1 if $chunk =~ s/^([ \011-\015]+)//;        
            my $tail = $1 if $chunk =~ s/([ \011-\015]+)$//;
            push @chunks, $head if !empty $head;
            push @chunks, $chunk if !empty $chunk;
            push @chunks, $tail if !empty $tail;
        }
    }

    foreach my $chunk (@chunks) {
        if ($chunk =~ /[^ \011-\015]+$/) {
            if ($chunk =~ /^<!--QGODA-XGETTEXT-->(.*?)<!--\/QGODA-XGETTEXT-->$/s) {
                my $string = $1;
                $chunk = bless \$string, 'b';
            } else {
                my $string = $chunk;
                $chunk = bless \$string, 't';
            }
        } else {
            my $string = $chunk;
            $chunk = bless \$string, 's';
        }
    }

    bless {
        __meta => $meta,
        __body => $body,
        __chunks => \@chunks,
    }, $class;
}

sub meta {
    shift->{__meta};
}

sub chunks {
    my ($self) = @_;

    map { $$_ } grep { 's' ne ref } @{$self->{__chunks}};
}

sub reassemble {
    my ($self, $callback) = @_;

    my $output = '';
    foreach my $chunk (@{$self->{__chunks}}) {
        if ('s' eq ref $chunk) {
            $output .= $$chunk;
        } elsif ('b' eq ref $chunk) {
            $output .= "<!--QGODA-XGETTEXT-->"
                . $callback->($$chunk)
                . "<!--/QGODA-XGETTEXT-->";
        } else {
            $output .= $callback->($$chunk);
        }
    }

    return $output;
}

1;