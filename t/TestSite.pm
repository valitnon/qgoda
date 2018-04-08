#! /bin/false # -*- perl -*-

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

package TestSite;

use strict;

use File::Spec;
use File::Path;
use YAML::XS;

use Qgoda::Util qw(empty write_file);

sub new {
    my ($class, %options) = @_;

    if (empty $options{name}) {
        require Carp;
        Carp::croak("The option 'name' is mandatory");
    }

    my $self = bless \%options, $class;
    $self->setup;

    return $self;
}

sub setup {
    my ($self) = @_;

    my ($volume, $directory) = File::Spec->splitpath(__FILE__);

    my $repodir = File::Spec->catpath($volume, $directory, '..');
    $self->{repodir} = $repodir;
    chdir $repodir or die "cannot chdir to '$repodir': $!\n";

    my $rootdir = File::Spec->catpath($volume, $directory, $self->{name});
    $self->{rootdir} = $rootdir;
    mkdir $rootdir;
    chdir $rootdir or die "cannot chdir to '$rootdir': $!\n";

    $self->__setupConfig;

    return $self;
}

sub __setupConfig {
    my ($self) = @_;

    if (empty $self->{config}) {
        unlink '_config.yaml';
        return $self;
    }

    my $yaml = YAML::XS::Dump($self->{config});
    write_file '_config.yaml', $yaml or die;

    return $self;
}

sub tearDown {
    my ($self) = @_;

    my ($volume, $directory) = File::Spec->splitpath(__FILE__);

    my $repodir = File::Spec->catpath($volume, $directory, '..');
    chdir $repodir or die "cannot chdir to '$repodir': $!\n";

    File::Path::remove_tree($repodir);

    return $self;
}
1;
