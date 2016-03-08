#!/bin/bash

includes_path=$PWD/includes

# Import variables.
source $includes_path/variables.sh

# Check environment and deploy accordingly
if [ "$environment" = "dev" ]
    then

    # Import application deploy.
    source $includes_path/local_application_deploy.sh

else

    if [ "$environment" = "production" ] || [ "$environment" = "uat" ]
        then
        
        if cd $rootpath/flipit_application && git pull ; git rev-list $1.. > /dev/null 
            then

            # Import application deploy.
            source $includes_path/server_application_deploy.sh

        else
            echo "#### No or no correct GIT tag found. Try:"
            echo "bash deploy.sh v1"
            exit
        fi

    else
    
        # Import application deploy.
        source $includes_path/server_application_deploy.sh

    fi

fi

# If current environment is Production then static varnish cache needs to be refreshed.
if [ "$environment" = "production" ]
    then

    echo "######################################"
    echo "##### REFRESHING STATIC VARNISH CACHES"
    echo "######################################"
    
    curl -X "PURGE" -H "Content-Type:text/css" http://www.kortingscode.nl >/dev/null 2>&1
    curl -X "PURGE" -H "Content-Type:application/x-javascript" http://www.kortingscode.nl >/dev/null 2>&1
    curl -X "PURGE" -H "Content-Type:application/javascript" http://www.kortingscode.nl >/dev/null 2>&1

    curl -X "PURGE" -H "Content-Type:text/css" http://www.flipit.com >/dev/null 2>&1
    curl -X "PURGE" -H "Content-Type:application/x-javascript" http://www.flipit.com >/dev/null 2>&1
    curl -X "PURGE" -H "Content-Type:application/javascript" http://www.flipit.com >/dev/null 2>&1

fi
    
# If current environment is Test or uat static files need to be synced with Production.
# if [ "$environment" = "test" ] || [ "$environment" = "uat" ]
#     then

#     echo "#### Environment set to test or uat server, syncing shared files form production."
#     # Import file sync script.
#     source $rootpath/$includes_path/file_sync.sh

# fi

if [ "$2" = "reset_db" ] && [ "$environment" != "production" ]
    then

    source $rootpath/$includes_path/reset_db.sh

else
    echo "#### DB's are not reset."
fi


if [ "$2" = "set_share_permissions" ]
    then

    # Import permissions reset script.
    source $rootpath/$includes_path/permissions.sh

else
    echo "#### Permissions are not changed"    
fi

# When upgrading ubuntu the symbolic links for PHPMyAdmin are no longer followed.
# This is a temporary work-around to fix the problem.

sudo rm /usr/share/phpmyadmin/libraries/php-gettext/*
sudo ln /usr/share/php/php-gettext/* /usr/share/phpmyadmin/libraries/php-gettext

echo "######################################"
echo "##### DONE WITH THE DEPLOY OF $GITTAG "
echo "######################################"
