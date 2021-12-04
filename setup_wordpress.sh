#!/bin/bash
# requirements:
# database server is mysql and assumed to be on the same box and running
# webs server is Apache2 standard location
# run in the root of the wordpress installation
mysql_username=root

# --------------------------------- checks
if [ -z $1 ]; then
  echo "ERROR: \$1 parameter (domain, e.g. tnv3) without TLD (will be .localhost) required"
  exit 1;
fi
if [ -z $2 ]; then
  echo "ERROR: \$2 parameter (general password) required for DB user"
  exit 1;
fi
if ! ps -A | grep -q mysqld; then
  echo "ERROR: mysqld not running on this server"
  exit 1;
fi
if ! ps -A | grep -q apache2; then
  echo "ERROR: Apache2 not running on this server"
  exit 1;
fi
if [ ! -d ./wp-admin ]; then
  echo "ERROR: ./wp-admin does not exist. are you in the root of Wordpress?"
  exit 1;
fi
# --------------------------------- inputs
# Bad substitution comes if we are not using BASH
input=$1
input_no_dev=${input/\.*/}

# --------------------------------- setup style
if [ -f ./wp-config.php ]; then
  read -p "./wp-config.php already exists. move to one side? (Y/n)" yn
  case $yn in
    [Y]* )
      echo "ok, renaming to wp-config-saved.php"
      if [ -f ./wp-config-saved.php ]; then rm ./wp-config-saved.php; fi
      mv ./wp-config.php ./wp-config-saved.php
      ;;
    * )
      echo "ok, exciting process. please resolve manually"
      exit 1;
      ;;
  esac
fi

# --------------------------------- db
db_name=$input_no_dev
db_password=$2
db_user_password=$2
echo "Please enter the root mysql password"
read mysql_password
db_exists=`mysql -u $mysql_username --password=$mysql_password -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$db_name'" | wc -c`
if [ $db_exists = 0 ]; then
  echo "DB [$db_name] does not exist yet"
else
  echo "DB [$db_name] already exists"
fi
read -p "(re-)create DB stuff? (Y/n)" yn
case $yn in
  [Y]* )
    if [ ! $db_exists = 0 ]; then
      mysql -u $mysql_username --password=$mysql_password -e "drop database $db_name;"
      mysql -u $mysql_username --password=$mysql_password -e "drop user '$db_name'@'localhost';"
    fi
    mysql -u $mysql_username --password=$mysql_password -e "create database $db_name;"
    mysql -u $mysql_username --password=$mysql_password -e "create user '$db_name'@'localhost' identified by '$db_user_password';grant all on $db_name.* to '$db_name'@'localhost' identified by '$db_user_password';"
    echo "created database [$db_name] with user [$db_name] password [$db_password]";
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

# --------------------------------- create wp-config.php
printf "<?php\n" >> wp-config.php
printf "define('DB_NAME', '$db_name');\n" >> wp-config.php
printf "define('DB_USER', '$db_name');\n" >> wp-config.php
printf "define('DB_PASSWORD', '$db_password');\n" >> wp-config.php
printf "define('DB_HOST', 'localhost');\n" >> wp-config.php
printf "define('DB_CHARSET', 'utf8');\n" >> wp-config.php
printf "define('DB_COLLATE', '');\n" >> wp-config.php

printf "define('AUTH_KEY',         '~?|mfEC!xg!6y=aDF:p!tm&9@Le!+{cw0^\`:cD|+4[\$~a17LZO^JG5UfK@vKvb!Z');\n" >> wp-config.php
printf "define('SECURE_AUTH_KEY',  'SbDU2(o|fI-0 ;-w:-e.7xF^@]pK+Z={amB}Jqzhy>6+d|6D-.PiV!yEalJ5)0=3');\n" >> wp-config.php
printf "define('LOGGED_IN_KEY',    '8SB#<6,bS(6yGLMF+O]/VF6W=RFur+d>+qhx6t?L|81(k\`|@eCiP2.>GSXkbwo7I');\n" >> wp-config.php
printf "define('NONCE_KEY',        'S3LJjjZvsVWMlA5)<|m d58c53h57^8-~)R|Ys(%sKrV@:Cp:0;7dKc/+CR+\`mw\$');\n" >> wp-config.php
printf "define('AUTH_SALT',        'W5(an)1&[eb:F#}kW]\{Q)1O~g/X\}uxe6t_3\`7[R@?LcOS<t=?sNB~zA:5!Hq&MWO');\n" >> wp-config.php
printf "define('SECURE_AUTH_SALT', 'XZp#;VDFSg0eJC+7a4NB3:*bfb\`+-FtK6,_..I^O!g~a46k]ngKv~8 g|5o<S]Cu');\n" >> wp-config.php
printf "define('LOGGED_IN_SALT',   'y|~+(K|^i>0XN8}+A9.}8Poq[.hJo8/e+2wmMZVH8|O/M4~6![~qqXr*-n!lz4 t');\n" >> wp-config.php
printf "define('NONCE_SALT',       'Nvv]}qP6#6s,7)nZV6Tqyt\$LJajL\$1Sl=kQlh|WE|~=|8?[e9V;TL@D7Sv~@ZOSG');\n" >> wp-config.php

printf "\$table_prefix  = 'wp_';\n" >> wp-config.php
printf "define('WP_DEBUG', false);\n" >> wp-config.php
printf "define('FS_METHOD', 'direct');\n" >> wp-config.php
printf "if ( !defined('ABSPATH') ) define('ABSPATH', dirname(__FILE__) . '/');\n" >> wp-config.php
printf "require_once(ABSPATH . 'wp-settings.php');\n" >> wp-config.php
printf "?>\n" >> wp-config.php

# --------------------------------- permissions
chown -R www-data wp-content

echo "now go to http://$input_no_dev.localhost/ to finish install"
