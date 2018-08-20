#!/bin/bash

# Bash script to install a wordpress based site in Debian based system.
# Author: Shyam Sitaula
# Liscense: GPL v2
#
#
# This script automates below tasks:
# 
# 1. Make requried mysql database changes.
# 2. Make requried wordpress wp-config.php changes.
# 3. Make required linux group and permission changes.
# 4. Make requried apache2 config changes, enables, and restarts.
#


### ----------------
### Helper functions
### ----------------

# Print a heading
printHeading()  
{
    echo ',-Attention--'
    echo '|'
    echo "-> $1."
    echo 
}

# Get an input from user
getInput()
{
    echo -n "$1"
    read TEMPINP
    if [ $# -eq 2 ]; then 
        if [ $2 == '-nl' ]; then
            echo ''
        fi
    fi
}

# Halt till user presses a key
waitKeyPress()
{
    read TEMPINP
}

# Print a message
printMessage()
{
    echo $1
}


### --------------------
### Program/script start
### --------------------
echo ',--' 
echo '|'
echo '`-Start--'
echo '' 


# Getting basic info
getInput 'Project name: ' -nl
PROJ=$TEMPINP


###----------------
### Database changes
###----------------

printHeading 'Making database changes'
getInput 'Do you want to make database changes? [y/n] : ' -nl
TEMP=$TEMPINP
if [ x$TEMP == 'xy' ]; then
    getInput 'Do you want to create a new database? [y/n] : ' -nl
    TEMP=$TEMPINP
    if [ x$TEMP == 'xy' ]; then
        getInput 'Database name: ' -nl
        NDBNAME=$TEMPINP
        echo "CREATE DATABASE $NDBNAME;" | mysql -u root -p
    fi
    getInput 'Do you want to create a new user? [y/n] : ' -nl
    TEMP=$TEMPINP
    if [ x$TEMP == 'xy' ]; then
        getInput 'User name: '
        NDBUNAME=$TEMPINP
        getInput 'Password: ' -nl
        NDBUPASS=$TEMPINP
        echo "CREATE USER \`$NDBUNAME\`@\`localhost\` IDENTIFIED BY '$NDBUPASS';" | mysql -u root -p
    fi
    getInput 'Do you want to grant privileges to user? [y/n] : ' -nl
    TEMP=$TEMPINP
    if [ x$TEMP == 'xy' ]; then
        echo "GRANT ALL PRIVILEGES ON \`$NDBNAME\`.* TO \`$NDBUNAME\`@\`localhost\`;" | mysql -u root -p
    fi
fi

printMessage 'Press any key to proceed ... '
waitKeyPress


###----------------------
### wp-config.php changes
###----------------------

printHeading 'Editing wp-config.php'
getInput 'Do you want to edit wp-config? [y/n] : ' -nl
TEMP=$TEMPINP
if [ x$TEMP == 'xy' ]; then
    getInput 'Database name: '
    DBNAME=$TEMPINP
    getInput 'Database user name: '
    DBUSER=$TEMPINP
    getInput 'Database user password: ' -nl
    DBUPASS=$TEMPINP

    if [ -f $PROJ/wp-config.php ]; then
        sed -e "s/define('DB_NAME', '.*')/define('DB_NAME', '$DBNAME')/g" \
            -e "s/define('DB_USER', '.*')/define('DB_USER', '$DBUSER')/g" \
            -e "s/define('DB_PASSWORD', '.*')/define('DB_PASSWORD', '$DBUPASS')/g" \
        $PROJ/wp-config.php > $PROJ/wp-config-new.php

        mv $PROJ/wp-config-new.php $PROJ/wp-config.php
    else
        echo "Error: $PROJ/wp-config.php file is missing ! "
        echo 'Exiting ... '
        exit 1
    fi

    echo '--> Success : wp-config.php updated.'
    echo ''
fi

printMessage 'Press any key to proceed ... '
waitKeyPress


### ----------------------------------
### File group and permission changes.
### To make sure that apache has the required permissions in this project/dir.
### ----------------------------------

printHeading 'Making file group and permission changes.'
getInput 'Do you want to make file group and permission changes? [y/n] : ' -nl
TEMP=$TEMPINP
if [ x$TEMP == 'xy' ]; then
    getInput 'Do you want to change group to apache? [y/n] : ' -nl
    TEMP=$TEMPINP
    if [ x$TEMP == 'xy' ]; then
        chgrp -R www-data $PROJ 
    fi
    getInput 'Do you want to give write permission to group? [y/n] : ' -nl
    TEMP=$TEMPINP
    if [ x$TEMP == 'xy' ]; then
        chmod -R g+w $PROJ 
    fi
fi

printMessage 'Press any key to proceed ... '
waitKeyPress


### --------------
### Apache changes
### --------------

printHeading 'Making apache config changes. '
getInput 'Do you want to make apache config changes? [y/n] : ' -nl
TEMP=$TEMPINP
if [ x$TEMP == 'xy' ]; then
    getInput 'Do you want to create .conf file? [y/n] : '
    TEMP=$TEMPINP
    if [ x$TEMP == 'xy' ]; then
        getInput 'Port: ' -nl
        PORT=$TEMPINP
        getInput 'ServerAdmin: ' -nl
        SERVERADMIN=$TEMPINP
        getInput 'ServerName: ' -nl
        SERVERNAME=$TEMPINP
        getInput 'ServerAlias: ' -nl
        SERVERALIAS=$TEMPINP
        getInput 'DocumentRoot: ' -nl
        DOCROOT=$TEMPINP

        cat > "$PROJ.conf" << __EOF__  
Listen 80
<VirtualHost *:80>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request's Host: header to
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	#ServerName www.example.com

	ServerAdmin webmaster@localhost
	ServerName localhost
	ServerAlias www.localhost
	DocumentRoot /var/www

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined

	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	# after it has been globally disabled with "a2disconf".
	#Include conf-available/serve-cgi-bin.conf

	<Directory "/var/www">
		Allow from all
		Require all granted
	</Directory>
</VirtualHost>
__EOF__
        
        sed  -e "s/Listen 80/Listen $PORT/" \
             -e "s/<VirtualHost \*:80>/<VirtualHost *:$PORT>/" \
             -e "s/ServerAdmin webmaster@localhost/ServerAdmin $SERVERADMIN/" \
             -e "s/ServerName localhost/ServerName $SERVERNAME/" \
             -e "s/ServerAlias www.localhost/ServerAlias $SERVERALIAS/" \
             -e "s#DocumentRoot /var/www*#DocumentRoot $DOCROOT#"  \
             -e "s#<Directory \"/[^\"]*#<Directory \"$DOCROOT#" \
             $PROJ.conf > $PROJ.conf.n
    
        mv $PROJ.conf.n $PROJ.conf
        if [ -f "/etc/apache2/sites-available/$PROJ.conf" ]; then
            echo "Alert: $PROJ.conf already present."
            getInput 'Do you want to override? [y/n] : '
            TEMP=$TEMPINP 
            if [ x$TEMP == 'xy' ]; then
                mv $PROJ.conf /etc/apache2/sites-available
            fi
        else
            mv $PROJ.conf /etc/apache2/sites-available
        fi
    fi
    getInput 'Do you want to enable the site? [y/n] : ' -nl
    TEMP=$TEMPINP
    if [ x$TEMP == 'xy' ]; then
        # TODO: How to handle error/success message?
        a2ensite $PROJ
    fi
    getInput 'Do you want to restart apache? [y/n] : ' -nl
    TEMP=$TEMPINP
    if [ x$TEMP == 'xy' ]; then
        # TODO: How to handle error/success message?
        systemctl restart apache2
    fi
fi

printMessage 'Press any key to proceed ... '
waitKeyPress


### -------------------
### Program/script done
### -------------------
echo ',-Please check exit status--'
echo '|'
echo '`-End--'
echo ''

