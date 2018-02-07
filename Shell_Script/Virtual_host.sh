echo "enter virtualhost name"
read vhost
echo "choose magento version"
echo "1. Magento 1"
echo "2. Magento 2"
read magentoversion

 if [ "$magentoversion" == "1" ]
 then
  cd /etc/nginx/conf.d
  cp demom1.conf.back "$vhost".ecomextension.com.conf
  sed -i 's/demo1/'$vhost'/' "$vhost".ecomextension.com.conf
  mkdir -p /var/www/extension-demo/$vhost
  cd /var/www/extension-demo/$vhost
  echo -e "<?php\nphpinfo();\n?>" > index.php
  chown -R extensiondemo: /var/www/extension-demo/$vhost
  echo "checking nginx configurations"
  echo "--------------------------------------------------------------------------------------"
  nginx -t
  echo "--------------------------------------------------------------------------------------"
  echo "If everything is fine Please restart nginx and check below URL"
  echo ""$vhost".ecomextension.com"
  echo "do you want to create database ?"
  echo "y/n"
  read dbcreateconfirm
  if [ "$dbcreateconfirm" == "y" ]
  then
   echo "enter database name"
   read dbname
   echo "enter username"
   read dbuser
   echo "enter password"
   read dbpasswd
   mysql -uroot --password="$mysqlpass" -e "create user '$dbuser'@'localhost' identified by '$dbpasswd'"
   mysql -uroot --password="$mysqlpass" -e "create database $dbname"
   mysql -uroot --password="$mysqlpass" -e "grant all on $dbname.* to '$dbuser'@'%' identified by '$dbpasswd';"

  fi
  elif [ "$magentoversion" == "2" ]
 then
  echo "choose PHP version"
  echo "1. PHP 5.6"
  echo "2. PHP 7"
  read phpversion
  if [ $phpversion == "1" ]
  then
   cd /etc/nginx/conf.d
   cp demom2.conf.back "$vhost".ecomextension.com.conf
   sed -i 's/demo2/'$vhost'/' "$vhost".ecomextension.com.conf
   cd /etc/nginx/mage2
   cp magento21.nginx.conf "$vhost".nginx.conf
   mkdir -p /var/www/extension-demo/$vhost
   cd /var/www/extension-demo/$vhost
   echo -e "<?php\nphpinfo();\n?>" > index.php
   chown -R extensiondemo: /var/www/extension-demo/$vhost
   echo "checking nginx configurations"
   echo "--------------------------------------------------------------------------------------"
   nginx -t
   echo "--------------------------------------------------------------------------------------"
   echo "If everything is fine Please restart nginx and check below URL"
   echo "$(vhost).ecomextension.com"
   echo "do you want to create database ?"
                echo "y/n"
                read dbcreateconfirm
                if [ "$dbcreateconfirm" == "y" ]
                then
                        echo "enter database name"
                        read dbname
                        echo "enter username"
                        read dbuser
                        echo "enter password"
                        read dbpasswd
                        mysql -uroot --password="$mysqlpass" -e "create user '$dbuser'@'localhost' identified by '$dbpasswd'"
                        mysql -uroot --password="$mysqlpass" -e "create database $dbname"
                        mysql -uroot --password="$mysqlpass" -e "grant all on $dbname.* to '$dbuser'@'%' identified by '$dbpasswd';"

                fi
   elif [ $phpversion == "2" ]
  then
   cd /etc/nginx/conf.d
   cp demom2.conf.back "$vhost".ecomextension.com.conf
   sed -i 's/demo2/'$vhost'/' "$vhost".ecomextension.com.conf
   cd /etc/nginx/mage2
   cp magento22.nginx.conf "$vhost".nginx.conf
   mkdir -p /var/www/extension-demo/$vhost
   cd /var/www/extension-demo/$vhost
   echo -e "<?php\nphpinfo();\n?>" > index.php
   chown -R extensiondemo: /var/www/extension-demo/$vhost
   echo "checking nginx configurations"
   echo "--------------------------------------------------------------------------------------"
   nginx -t
   echo "--------------------------------------------------------------------------------------"
   echo "If everything is fine Please restart nginx and check below URL"
   echo ""$vhost".ecomextension.com"
   echo "do you want to create database ?"
                 echo "y/n"
                 read dbcreateconfirm
                 if [ "$dbcreateconfirm" == "y" ]
                 then
                         echo "enter database name"
                         read dbname
                         echo "enter username"
                         read dbuser
                         echo "enter password"
                         read dbpasswd
                         mysql -uroot --password="$mysqlpass" -e "create user '$dbuser'@'localhost' identified by '$dbpasswd'"
                         mysql -uroot --password="$mysqlpass" -e "create database $dbname"
                         mysql -uroot --password="$mysqlpass" -e "grant all on $dbname.* to '$dbuser'@'%' identified by '$dbpasswd';"
                 fi
  fi

 fi