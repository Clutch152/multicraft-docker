#!/bin/bash

DIR_ROOT="/mc"
MC_DIR="$DIR_ROOT/multicraft"
MC_DIR2="$MC_DIR/multicraft"
MC_WEB_DIR="$DIR_ROOT/panel"
MC_WEB_DATAName="data.db"
MC_WEB_DATA="$MC_WEB_DIR/protected/data/$MC_WEB_DATAName"
MC_USER="multicraft"
MC_USERADD="/usr/sbin/useradd"
MC_GROUPADD="/usr/sbin/groupadd"
MC_USERDEL="/usr/sbin/userdel"
MC_GROUPDEL="/usr/sbin/groupdel"
install="1"
FILE="$DIR_ROOT/install.txt"
CFG="$MC_DIR2/multicraft.conf"
contentFile="";
if [ -f $FILE ]; then
   install=`cat $FILE`
fi

echo "install : $install"

### Multicraft user & directory setup

"$MC_GROUPADD" "$MC_USER"
if [ ! "$?" = "0" ]; then
    echo "Unable to Create User Group '$MC_USER'!"
fi

"$MC_USERADD" "$MC_USER" -g "$MC_USER" -s /bin/false
if [ ! "$?" = "0" ]; then
    echo "Unable to Create User '$MC_USER'!"
fi

if [ "$install" -eq "1" ]
then

    echo "0" > "$DIR_ROOT/install.txt"

    MC_DAEMON_ID="1"
    MC_DAEMON_IP="`ifconfig 2>/dev/null | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | head -n1`"
    MC_DAEMON_PORT="25465"
    MC_DAEMON_DATAName="data.db"
    MC_DAEMON_DATA="$MC_DIR2/data/$MC_DAEMON_DATAName"
    MC_DAEMON_PW=${MC_DAEMON_PW:-"changeMe"}
    MC_FTP_IP=${MC_FTP_IP:-""}
    MC_FTP_PORT=${MC_FTP_PORT:-"21"}
    MC_FTP_SERVER=${MC_FTP_SERVER:-"y"}
    MC_DB_TYPE="sqlite"
    MC_KEY=${MC_KEY:-"0B10-A841-E555-3B78"}
    MC_LOCAL="y"
    MC_MULTIUSER="y"
    MC_PLUGINS="n"
    MC_WEB_USER="www-data"
    MC_CREATE_USER="y"
    MC_JAVA="/usr/bin/java"
    MC_ZIP="/usr/bin/zip"
    MC_UNZIP="/usr/bin/unzip"
    MC_DOWNLOAD=${DOWNLOAD_URL:-"https://www.multicraft.org/download/linux64"}

    if [ ! -d "$MC_DIR" ]; then
        mkdir "$MC_DIR"
    fi

    cd "$MC_DIR"
    wget -q "$MC_DOWNLOAD"
    tar -xzf linux64
    rm -f linux64
    cd "$MC_DIR/multicraft"

    echo
    echo "***"
    echo "*** INSTALLATION"
    echo "***"
    echo

    chown  "$MC_USER":"$MC_USER" -R $(ls | awk '{if($1 != "servers"){ print $1 }}')
    chmod -R 755 "$MC_DIR"
    rm -f "$MC_DIR2/bin/_weakref.so"
    rm -f "$MC_DIR2/bin/collections.so"
    rm -f "$MC_DIR2/bin/libpython2.5.so.1.0"
    rm -f "$MC_DIR2/bin/"*-py2.5*.egg

    if [ "$MC_KEY" != "no" ]; then
        echo
        echo "Creating Licence File"
        echo "$MC_KEY" > "$MC_DIR2/multicraft.key"
    fi

    ### Generate config

    function repl {
        LINE="$SETTING = `echo $1 | sed "s/['\\&,]/\\\\&/g"`"
    }

    SECTION=""
    cat "$CFG.dist" | while IFS="" read -r LINE
    do
        if [ "`echo $LINE | grep "^ *\[\w\+\] *$"`" ]; then
            SECTION="$LINE"
            SETTING=""
        else
            SETTING="`echo $LINE | sed -n 's/^ *\#\? *\([^ ]\+\) *=.*/\1/p'`"
        fi
        case "$SECTION" in
        "[multicraft]")
            case "$SETTING" in
            "user")         repl "$MC_USER" ;;
            "ip")           if [ "$MC_LOCAL" != "y" ]; then repl "$MC_DAEMON_IP";       fi ;;
            "port")         if [ "$MC_LOCAL" != "y" ]; then repl "$MC_DAEMON_PORT";     fi ;;
            "password")     repl "$MC_DAEMON_PW" ;;
            "id")           repl "$MC_DAEMON_ID" ;;
            "database")     if [ "$MC_DB_TYPE" = "sqlite" ]; then repl "sqlite:$MC_DAEMON_DATA";        fi ;;
            "webUser")      if [ "$MC_DB_TYPE" = "mysql" ]; then repl "";               else repl "$MC_WEB_USER"; fi ;;
            "baseDir")      repl "$MC_DIR2" ;;
            esac
        ;;
        "[ftp]")
            case "$SETTING" in
            "enabled")          if [ "$MC_FTP_SERVER" = "y" ]; then repl "true";    else repl "false"; fi ;;
            "ftpIp")            repl "$MC_FTP_IP" ;;
            "ftpPort")          repl "$MC_FTP_PORT" ;;
            "forbiddenFiles")   if [ "$MC_PLUGINS" = "n" ]; then repl "";           fi ;;
            esac
        ;;
        "[minecraft]")
            case "$SETTING" in
            "java") repl "$MC_JAVA" ;;
            esac
        ;;
        "[system]")
            case "$SETTING" in
            "unpackCmd")    repl "$MC_UNZIP"' -quo "{FILE}"' ;;
            "packCmd")      repl "$MC_ZIP"' -qr "{FILE}" .' ;;
            esac
            if [ "$MC_MULTIUSER" = "y" ]; then
                case "$SETTING" in
                "multiuser")    repl "true" ;;
                "addUser")      repl "$MC_USERADD"' -c "Multicraft Server {ID}" -d "{DIR}" -g "{GROUP}" -s /bin/false "{USER}"' ;;
                "addGroup")     repl "$MC_GROUPADD"' "{GROUP}"' ;;
                "delUser")      repl "$MC_USERDEL"' "{USER}"' ;;
                "delGroup")     repl "$MC_GROUPDEL"' "{GROUP}"' ;;
                esac
            fi
        ;;
        "[backup]")
            case "$SETTING" in
            "command")  repl "$MC_ZIP"' -qr "{WORLD}-tmp.zip" . -i "{WORLD}"*/*' ;;
            esac
        ;;
        esac
        echo "$LINE" >> "$CFG"
    done

    echo
    echo "Adjusting Directory Permissions '$MC_DIR' for '$MC_USER'"
    cd "$MC_DIR2"
    chown -R "$MC_USER":"$MC_USER" -R $(ls | awk '{if($1 != "servers"){ print $1 }}')
    chmod -R 755 "$MC_DIR2"
    chmod 555 "$MC_DIR2/launcher/launcher"
    chmod 555 "$MC_DIR2/scripts/getquota.sh"

    echo "Special Permissions"
    if [ "$MC_MULTIUSER" = "y" ]; then
        chown 0:"$MC_USER" "$MC_DIR2/bin/useragent"
        chmod 4550 "$MC_DIR2/bin/useragent"
    fi
    chmod 755 "$MC_DIR2/jar/"*.jar 2> /dev/null

    ### Install PHP frontend

    if [ "$MC_LOCAL" = "y" ]; then
        echo "Creating Web directory: '$MC_WEB_DIR'"
        mkdir -p "$MC_WEB_DIR"

        echo "Installing the Web Panel"
        cp -a panel/* "$MC_WEB_DIR"
        cp -a panel/.ht* "$MC_WEB_DIR"
        chown -R "$MC_WEB_USER":1000 "$MC_WEB_DIR"
        chmod -R o-rwx "$MC_WEB_DIR"
    fi

    "$MC_DIR2/bin/multicraft" set_permissions

    echo
    echo
    echo "***"
    echo "*** Installation complete!"
    echo "***"
    echo
    echo "Before starting the daemon, you must run the control panel installation program to initialize your database. (Example: example: http: //your.address/multicraft/install.php)"
    echo
    echo "$MC_DIR2/bin/multicraft start"
    echo

    cd "$MC_DIR2"

elif [ "$install" -eq "0" ]
then
    if [ -f "$MC_WEB_DIR/install.php" -a -f "$MC_WEB_DIR/protected/config/config.php" -a -f "$MC_WEB_DATA" ]; then
        rm "$MC_WEB_DIR/install.php"
    fi
fi
echo "install : $install"
echo "<VirtualHost *:80>
    DocumentRoot $MC_WEB_DIR
    <Directory $MC_WEB_DIR>
        Options +Indexes +FollowSymLinks +MultiViews
        Order Allow,Deny
        Allow from all
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog $MC_WEB_DIR/error.log
    CustomLog $MC_WEB_DIR/access.log combined
</VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf

service apache2 restart
/mc/multicraft/multicraft/bin/multicraft start

while true; do
    sleep 1
done

/bin/bash
