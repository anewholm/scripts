#!/bin/bash
# requirements:
# webs server is Apache2 standard location

# --------------------------------- checks
if ! ps -A | grep -q apache2; then
  echo "ERROR: Apache2 not running on this server"
  exit 1;
fi
if [ -z $1 ]; then
  echo "ERROR: \$1 parameter (domain name without TLD, which will be .localhost) required"
  exit 1;
fi

# --------------------------------- webserver
# Bad substitution comes if we are not using BASH
input=$1
input_no_dev=${input/.localhost/}
virtualhost_filename=$input_no_dev.conf
hostname=$input_no_dev
if [[ $hostname != *"."* ]]; then
	hostname=$hostname.localhost
else
	echo ""
	read -p "WARNING: hostname $hostname contains a . so .localhost was NOT added. Ok? (Y/n)" yn
  case $yn in
    [Y]* )
      echo "ok, using $hostname"
      ;;
    * )
      echo "ok, exciting process. please resolve manually"
      exit 1;
      ;;
  esac
fi

if [ "$(id -u)" != "0" ]; then
  echo "WARNING: need to be root to setup the virtual host"
else
  if [ -f /etc/apache2/sites-enabled/$virtualhost_filename ]; then
    echo "/etc/apache2/sites-enabled/$virtualhost_filename already exists"
  else
    current_directory=`pwd`
    if [ -f /etc/apache2/sites-available/$virtualhost_filename ]; then
      rm /etc/apache2/sites-available/$virtualhost_filename
      rm /etc/apache2/sites-enabled/$virtualhost_filename
    fi
    printf "<VirtualHost *:80>\n \
            ServerName $hostname\n \
            ServerAlias www.$hostname\n \
            DocumentRoot $current_directory\n \
    </VirtualHost>" > /etc/apache2/sites-available/$virtualhost_filename
    ln -s /etc/apache2/sites-available/$virtualhost_filename /etc/apache2/sites-enabled/$virtualhost_filename
    apache2ctl restart
    echo "created virtual host $hostname.conf and restarted server"
  fi

  if grep -q $hostname /etc/hosts; then
    echo "$hostname already exists in /etc/hosts";
  else
    echo "127.0.0.1        $hostname" >> /etc/hosts
    echo "127.0.0.1        www.$hostname" >> /etc/hosts
    echo "added $hostname to /etc/hosts"
  fi
fi
