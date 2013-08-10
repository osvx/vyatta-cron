#!/usr/bin/perl
#
# vyatta-update-ctontab.pl: crontab generator
#
# Maintainer: Daniil Baturin <daniil@baturin.org>
#
# Copyright (C) 2013 SO3Group
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

use lib "/opt/vyatta/share/perl5/";

use strict;
use warnings;
use Getopt::Long;
use Vyatta::Config;



my $default_user = "root";
my $crontab = "/etc/crontab";

my $crontab_template = <<EOL;
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# m h dom mon dow user	command
17 *	* * *	root    cd / && run-parts --report /etc/cron.hourly
25 6	* * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 6	* * 7	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 6	1 * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
#

EOL

my $crontab_header = "### Added by /opt/vyatta/sbin/vyatta-update-crontab.pl ###\n";

sub error
{
    my ($task, $msg) = @_;
    die("Error in task $task: $msg");
}

sub clear_crontab
{
    open(HANDLE, ">$crontab");
    select(HANDLE);
    print $crontab_template;
    close(HANDLE);
}

sub update_crontab
{
    my $config = new Vyatta::Config();
    $config->setLevel("system task-scheduler task");

    my $crontab_append = $crontab_header;

    my @tasks = $config->listNodes();

    foreach my $task (@tasks)
    {
        my $minutes = "*";
        my $hours = "*";
        my $days ="*";

        my $user = $default_user;
        my $executable = undef;
        my $arguments = undef;

        my $interval = undef;
        my $crontab_spec = undef;

        my $crontab_string = undef;

        # Unused now
        my $months = "*";
        my $days_of_week = "*";

        # Executable is mandatory
        $executable = $config->returnValue("$task executable path");
        if( !defined($executable) )
        {
            error($task, "must define executable");
        }

        # Arguments are optional
        $arguments = $config->returnValue("$task executable arguments");
        $arguments = "" unless defined($arguments);

        $interval = $config->returnValue("$task interval");
        $crontab_spec = $config->returnValue("$task crontab-spec");

        # "interval" and "crontab-spec" are mutually exclusive
        if( defined($interval) &&
            defined($crontab_spec) )
        {
            error($task, "can not use interval and crontab-spec at the same time!");
        }

        if( defined($interval) )
        {
            my ($value, $suffix) = ($interval =~ /(\d+)([mdh]){0,1}/);

            if( !defined($suffix) || ($suffix eq 'm') )
            {
                $minutes = "*/$value";
            }
            elsif( $suffix eq 'h' )
            {
                $hours = "*/$value";
            }
            elsif( $suffix eq 'd' )
            {
                $days = "*/$value";
            }

            $crontab_string = "$minutes $hours $days $months $days_of_week $user $executable $arguments\n"
        }
        elsif( defined($crontab_spec) )
        {
            $crontab_string = "$crontab_spec $user $executable $arguments\n";
        }
        else
        {
            error($task, "must define either interval or crontab-spec")
        }

        $crontab_append .= $crontab_string;
    }

    open(HANDLE, ">$crontab") || die("Could not open /etc/crontab for write");
    select(HANDLE);
    print $crontab_template;
    print $crontab_append;
    close(HANDLE);
}


## Get options and decide with action
my $delete;
my $update;

GetOptions(
    "delete" => \$delete,
    "update" => \$update,
);

clear_crontab()  if defined($delete);
update_crontab() if defined($update);

exit(0);
