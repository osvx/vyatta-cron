vyatta-cron
===========

Vyatta cron configuration templates and scripts

Depends on cron package (installed by default).

Configuration commands:

    system
        task-scheduler
            task <name>
                cron-spec <UNIX cron time spec>
                executable
                    arguments <arguments string>
                    path <path to executable>
                interval
                    <int32>[mhd]    

Example:

    system
        task-scheduler
            task mytask
                executable
                    path /config/scripts/mytask
                    arguments "arg1 arg2 arg3"
            task anothertask
                cron-spec "* * * 1 *"
                executable
                    path /config/scripts/anothertask

## interval

    set system task-scheduler task <name> interval <value><suffix>

Sets the task to execute every N minutes, hours, or days. Suffixes:

* m -- minutes
* h -- hours
* d -- days

If suffix is omitted, minutes are implied.

Examples:

Run every five minutes:

    set system task-schedule task TEST interval 5

or

    set system task-schedule task TEST interval 5m

Run every two hours:

    set system task-schedule task TEST interval 2h

Run every 7 days:

    set system task-schedule task TEST interval 7d

## cron-spec

This is usual UNIX cron time spec. For the cases "interval" is not enough.

    set system task-scheduler task TEST cron-spec "* * * 1 *"

## executable
Path and arguments of the executable to run.

    set system task-schedule task TEST executable path /config/scripts/myscript
    set system task-schedule task TEST executable arguments "arg1 arg2"


## Technical details

This package is just a wrapper for UNIX crontab, nothing more.

