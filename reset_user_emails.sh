#!/bin/bash
# requirements:
# database server is mysql and assumed to be on the same box and running
# webs server is Apache2 standard location
# run in the root of the drupal installation
# D6 / D7 standard installation
mysql_username=root
mysql_password=queenpool1

# --------------------------------- checks
if ! ps -A | grep -q mysqld; then
  echo "ERROR: mysqld not running on this server"
  exit 1;
fi
if [ ! -d ./sites ]; then
  echo "ERROR: ./sites folder does not exist"
  exit 1;
fi
if [ ! -d ./sites/default ]; then
  echo "ERROR: ./sites/default does not exist"
  exit 1;
fi

# --------------------------------- get connection string D6
db_name=`grep ^'$db_url' ./sites/default/settings.php | cut -d "/" -f 4 | cut -d "'" -f 1`

# --------------------------------- get connection string D7
if [ $db_name = '' ]; then
  db_name = ''
  # TODO: 'database' => '
fi

# --------------------------------- update db
if [ $db_name = '' ]; then
  echo "failed to get db_name"
else
  mysql -u $mysql_username --password=$mysql_password -e "update users set mail = 'annesley_newholm@yahoo.it' where not mail = '' and not mail = 'annesley_newholm@yahoo.it';" $db_name
  echo "replaced all user emails in user table database [$db_name]"
fi
