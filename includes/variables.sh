# ------------------------------ #
#       Define variables         #
# ------------------------------ #

locales=(at au be br ca ch de dk es fi fr id in it jp my no pl pt se sg tr uk us za kr ar ru hk sk nz cl ie mx cn)

rootpath=$(pwd)

prodpath=/var/www/flipit.com

backupPath="$rootpath/backup"

productionip=178.18.91.234

user=flipit

webuser=_www

# ----------------------------- #

if [ "$environment" = "uat" ]
    then
    static_dirs=(images/upload rss sitemaps)
else
    static_dirs=(language images/upload rss sitemaps) 
fi

static_files=(robots.txt)
# static_files=(js/front_end/gtData.js js/back_end/gtData.js robots.txt)

writable_files=()
# writable_files=(js/front_end/gtData.js js/back_end/gtData.js)

LANGUAGE_DIR="$rootpath/language"

SHARE_DIR="$rootpath/shared"

RELEASE_DIR="$rootpath/releases"

LOCAL_DIR="$rootpath/local"
if [ ! -d $LOCAL_DIR ];
  then
    LOCAL_DIR="$rootpath/flipit_application/web/application/configs"
fi

NUM_RELEASES=3

SYMLINK_DIR="$rootpath/current"

timeStempBackup=$(date +"%Y-%m-%d-%H-%M")
TSD=$(date +"%d-%B-%Y")
TST=$(date +"%s")
TS=${TST}_${TSD}

GITTAG=$1

CUR_RLS_DIR="$RELEASE_DIR/${TS}_${GITTAG}"

environment=$(sed -n "/.*\ENV=\(.*\)/{s//\1/p;q}" $LOCAL_DIR/application.ini)

# ----------------------------- #

db_user=$(sed -n '/.*\.dsn.*\mysql\:\/\/\(.*\)\:.*/{s//\1/p;q}' $LOCAL_DIR/application.ini)

db_user_pass=$(sed -n '/.*\.dsn.*\mysql\:\/\/.*\:\(.*\)\@.*/{s//\1/p;q}' $LOCAL_DIR/application.ini)

db_host=$(sed -n '/.*\.dsn.*\@\(.*\)\/.*/{s//\1/p;q}' $LOCAL_DIR/application.ini)

db_redesign_user=$(sed -n '/.*\.red_dsn.*\mysql\:\/\/\(.*\)\:.*/{s//\1/p;q}' $LOCAL_DIR/application.ini)

db_redesign_user_pass=$(sed -n '/.*\.red_dsn.*\mysql\:\/\/.*\:\(.*\)\@.*/{s//\1/p;q}' $LOCAL_DIR/application.ini)

db_redesign_host=$(sed -n '/.*\.red_dsn.*\@\(.*\)\/.*/{s//\1/p;q}' $LOCAL_DIR/application.ini)

dir_to_db="$rootpath/databases"

# ---------- check if env is properly set ------------------- #

if [ "$environment" = "test" ] || [ "$environment" = "uat" ] || [ "$environment" = "production" ] || [ "$environment" = "dev" ]
    then

    echo "Environment is (properly) set to '$environment'!"

else

    echo "Environment is not (properly) set! Check your application.ini in local/"
    exit

fi
