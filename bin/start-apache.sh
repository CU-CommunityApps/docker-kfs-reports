#!/bin/sh

service apache2 start
tail -f /var/log/apache2/error.log -f /var/log/apache2/other_vhosts_access.log
