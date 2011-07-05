## OK Batch ##

This is a simple tool for putting a HTML GUI around a cron job, written
to give a customer insight into the workings of an HTTP mirror.

It lets you:

   * see the status of the job (running/not, last run, etc.)
   * look at recent logs
   * manually trigger a job


## Installation ##

Something like this:

    # Create working directories
    mkdir /var/www/ok-batch/ /var/www/ok-batch/run/
    chmod ugo+rwxt  /var/www/ok-batch/run/

    # Copy stuff
    cp -a ok-* /var/www/ok-batch/

    # Symlink to activate cron jobs and CGI script
    ln -s /var/www/ok-batch/ok-batch.cron /etc/cron.d/
    ln -s /var/www/ok-batch/ok-batch.py /var/www/cgi-bin/

    # Edit job definitions
    vim /var/www/ok-batch/ok-*.{config,sh}


## Example ##

The files in this repo are configured for a real-world "example" of an
HTTP mirror job which runs `wget` every 15 minutes.

