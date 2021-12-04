#!/bin/bash
# requirements:
# database server is mysql and assumed to be on the same box and running
# webs server is Apache2 standard location
# run in the root of the drupal installation
# D6 / D7 standard installation
mysql_username=root

# --------------------------------- checks
if [ -z $1 ]; then
  echo "ERROR: \$1 parameter (domain, e.g. tnv3, without TLD, will be .localhost) required"
  exit 1;
fi
if [ -z $2 ]; then
  echo "ERROR: \$2 parameter (general password) required for DB User"
  exit 1;
fi
if ! ps -A | grep -q mysqld; then
  echo "ERROR: mysqld not running on this server"
  exit 1;
fi
if [ ! -d ./sites ]; then
  echo "ERROR: ./sites folder does not exist"
  exit 1;
fi
if [ ! -d ./sites/all ]; then
  echo "ERROR: ./sites/all does not exist"
  exit 1;
fi
if [ ! -d ./sites/default ]; then
  echo "ERROR: ./sites/default does not exist"
  exit 1;
fi

# --------------------------------- folders, files and permissions
if [ ! -d ./sites/default/files ]; then
  mkdir ./sites/default/files
  echo "created the files directory"
fi
chmod a+rw ./sites/default/files
if [ ! -f ./sites/default/settings.php ]; then
  cp ./sites/default/default.settings.php ./sites/default/settings.php
  echo "created the settings.php writeable"
fi
chmod 777 ./sites/default/settings.php

chmod 777 sites/all/modules
chmod 777 sites/all
echo "set 777 on sites/all/modules for webserver direct install"

# --------------------------------- connection string D6
db_password=$2
db_user_password=$2
echo "Please enter the root mysql password"
read mysql_password
if grep -q "\$db_url = 'mysql://username:password@localhost/databasename';" ./sites/default/settings.php; then
  sed "s/\$db_url = 'mysql:\/\/username:password@localhost\/databasename';/\$db_url = 'mysql:\/\/$1:$db_user_password@localhost\/$1';/g" ./sites/default/settings.php > ./sites/default/settings2.php
  rm ./sites/default/settings.php
  mv ./sites/default/settings2.php ./sites/default/settings.php
  chmod 777 ./sites/default/settings.php
  echo "set \$db_url to $1 in settings.php using general password supplied"
fi

# --------------------------------- connection string D7
# TODO: D7

# --------------------------------- db
db_exists=`mysql -u $mysql_username --password=$mysql_password -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$1'" | wc -c`
if [ $db_exists = 0 ]; then
  echo "DB [$1] does not exist yet"
else
  echo "DB [$1] already exists"
fi
read -p "(re-)create DB stuff? (Y/n)" yn
case $yn in
  [Y]* )
    if [ ! $db_exists = 0 ]; then
      mysql -u $mysql_username --password=$mysql_password -e "drop database $1;"
      mysql -u $mysql_username --password=$mysql_password -e "drop user '$1'@'localhost';"
    fi
    mysql -u $mysql_username --password=$mysql_password -e "create database $1;"
    mysql -u $mysql_username --password=$mysql_password -e "create user '$1'@'localhost' identified by '$db_user_password';grant all on $1.* to '$1'@'localhost' identified by '$db_user_password';"
    echo "created database [$1] with user [$1] password [$db_password]";
    ;;
  [n]* )
    ;;
  []* )
    ;;
  * ) echo "eh?"
    ;;
esac

# --------------------------------- webserver
bash /var/www/setup_hostname.sh $1

# --------------------------------- extra help
# drush cc all

echo "now go to http://$1.localhost/install.php to finish install"
echo "and then chmod a-w ./sites/default/settings.php"
