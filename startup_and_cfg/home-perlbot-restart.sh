#/bin/sh

kill `cat /home/chrisangell/etc/chrisbot/v3/data/logs/home-perlbot.pid` && perl /home/chrisangell/etc/chrisbot/v3/startup_and_cfg/home-perlbot.pl
