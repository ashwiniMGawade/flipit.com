#!/bin/sh

# Set environment
if [ -z "$(grep APPLICATION_ENV ~/.bashrc)" ]; then
    echo export APPLICATION_ENV="production" >> ~/.bashrc
fi

# Running the deploy. Git pull, copy to release dir, setting symlinks, db migrations and cleaning old releases.
if [ $USER == flipit ]
    then

    cd $rootpath/flipit_application

    echo "######################################"
    echo "##### Starting deploy                 "
    echo "######################################"

    echo "##### Checking out files to new release directory ..."
	cd $rootpath/flipit_application && git read-tree $1 && git checkout-index -a -f --prefix=$CUR_RLS_DIR/
	shopt -s dotglob

    echo "######################################"
    echo "##### Getting dependencies            "
    echo "######################################"

    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    cd $CUR_RLS_DIR/ && composer install --no-dev

    echo "#### Creating default folders if they dont exist ..."
    mkdir -p $CUR_RLS_DIR/web/logs
    mkdir -p $LOCAL_DIR/logs
    mkdir -p $LOCAL_DIR/tmp
    mkdir -p $RELEASE_DIR
    mkdir -p $SHARE_DIR
    sudo chmod -R 775 $LOCAL_DIR/tmp/
    sudo chown -R www-data:flipit $LOCAL_DIR/
    touch $rootpath/history_deploy.txt || exit
    # touch $LOCAL_DIR/logs/cms || exit
    # touch $LOCAL_DIR/logs/conversion || exit
    for locale in "${locales[@]}"
    do
       mkdir -p $CUR_RLS_DIR/web/data/$locale
    done

	echo "##### Creating Symlinks for local files ..."
	ln -sf $LOCAL_DIR/application.ini $CUR_RLS_DIR/web/application/configs/application.ini
	rm -rf $CUR_RLS_DIR/web/public/tmp/
	ln -sf $LOCAL_DIR/tmp $CUR_RLS_DIR/web/public
    # ln -sf $LOCAL_DIR/logs/cms $CUR_RLS_DIR/web/logs
    # ln -sf $LOCAL_DIR/logs/conversion $CUR_RLS_DIR/web/logs

    echo "##### Creating Symlinks for static_dirs ..."
    for folder in "${static_dirs[@]}"
    do
    	cd $SHARE_DIR
    	rm -rf $CUR_RLS_DIR/web/public/$folder
    	ln -s $SHARE_DIR/public/$folder $CUR_RLS_DIR/web/public/$folder

		for locale in "${locales[@]}"
		do
			rm -rf $CUR_RLS_DIR/web/public/$locale/$folder
			ln -s $SHARE_DIR/public/$locale/$folder $CUR_RLS_DIR/web/public/$locale/$folder
        done
    done

    rm -rf $CUR_RLS_DIR/web/public/language
    ln -s $LANGUAGE_DIR/language $CUR_RLS_DIR/web/public/language

    for locale in "${locales[@]}"
    do
        rm -rf $CUR_RLS_DIR/web/public/$locale/language
        ln -s $LANGUAGE_DIR/$locale/language $CUR_RLS_DIR/web/public/$locale/language
    done

    echo "##### Creating Symlinks for static_files ..."
    # Flipit.com robots.txt
    rm -rf $CUR_RLS_DIR/web/public/flipit/robots.txt
    ln -s $SHARE_DIR/public/flipit/robots.txt $CUR_RLS_DIR/web/public/flipit/robots.txt

    for files in "${static_files[@]}"
    do
        cd $SHARE_DIR
        rm -rf $CUR_RLS_DIR/web/public/$files
        ln -s $SHARE_DIR/public/$files $CUR_RLS_DIR/web/public/$files

		for locale in "${locales[@]}"
		do
            rm -rf $CUR_RLS_DIR/web/public/$locale/$files
            ln -s $SHARE_DIR/public/$locale/$files $CUR_RLS_DIR/web/public/$locale/$files
        done
    done

    echo "Creating symlinks for import/ export excels"
    rm -rf $CUR_RLS_DIR/web/data/excels
    ln -s $SHARE_DIR/public/excels $CUR_RLS_DIR/web/data

    for locale in "${locales[@]}"
    do
       rm -rf $CUR_RLS_DIR/web/data/$locale/excels
       ln -s $SHARE_DIR/public/$locale/excels $CUR_RLS_DIR/web/data/$locale
    done

    echo "######################################"
    echo "##### Generating json feeds & Css     "
    echo "######################################"

    php $CUR_RLS_DIR/web/application/migration/generateAllShopsJsonForSearch.php
    php $CUR_RLS_DIR/web/application/migration/generateJsonForJsTranlastion.php
    lessc -x $CUR_RLS_DIR/web/public/css/front_end/all.less > $CUR_RLS_DIR/web/public/css/front_end/all.css
    lessc -x $CUR_RLS_DIR/web/public/css/landingpages/landingPage.less > $CUR_RLS_DIR/web/public/css/landingpages/landingPage.css

    echo "######################################"
    echo "##### Generate proxies for doctrine   "
    echo "######################################"

    cd $CUR_RLS_DIR/web/library
    php bin/doctrine orm:clear-cache:metadata && \
    php bin/doctrine orm:clear-cache:query && \
    php bin/doctrine orm:clear-cache:result && \
    php bin/doctrine orm:generate-proxies /tmp
    cd $rootpath/flipit_application

    echo "######################################"
    echo "##### DB migrations                   "
    echo "######################################"

    php $CUR_RLS_DIR/cli/console.php localeMigrations:migrate --no-interaction
    php $CUR_RLS_DIR/cli/console.php userMigrations:migrate --no-interaction

    echo "######################################"
    echo "##### Enabling current release        "
    echo "######################################"

    ln -sfn $CUR_RLS_DIR $SYMLINK_DIR

    echo "######################################"
    echo "##### Cleaning up old releases ...    "
    echo "######################################"

    echo ${TS}_${GITTAG}|cat - $rootpath/history_deploy.txt > $rootpath/deploy_hist.tmp && mv $rootpath/deploy_hist.tmp $rootpath/history_deploy.txt

    DEPLOY_COUNTER=0
    while read line
    do
        DEPLOY_COUNTER=$((DEPLOY_COUNTER+1))
        if test $DEPLOY_COUNTER -gt $NUM_RELEASES
        then
            if [ -d "$RELEASE_DIR/$line" ]; then
                echo "##### Removing old release $RELEASE_DIR/$line ..."
                rm -rf $RELEASE_DIR/$line
            fi
        fi
    done < $rootpath/history_deploy.txt

else
    echo "#### Trying to deploy with a different user then $user. Try:"
    echo "su $user"
    exit
fi
