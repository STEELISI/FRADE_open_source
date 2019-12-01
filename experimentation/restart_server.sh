. ../../config

if [ "$server_service" == "nginx" ]; then
service php5-fpm restart
service nginx restart
fi

if [ "$server_service" == "apache2" ]; then
service apache2 restart
fi
