FROM ubuntu-upstart

#install apache and php
RUN apt-get update && apt-get install git wget apache2 php5 libapache2-mod-php5 curl crudini nano -y
RUN a2enmod rewrite
RUN apt-get install libapache2-mod-xsendfile sudo subversion php5-dev php-apc php5-mysql php5-mcrypt php5-curl php5-cli re2c -y
RUN apt-get install sysv-rc-conf -y && sysv-rc-conf apache2 on && sysv-rc-conf --list apache2
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY apache2.conf /etc/apache2/apache2.conf

#clone git repos
RUN mkdir /repo -m 777
WORKDIR /repo
RUN git clone https://github.com/TheRosettaFoundation/SOLAS-Match.git
RUN git clone https://github.com/chobie/php-protocolbuffers.git

#add basic config #TODO update to be generic
WORKDIR /repo/SOLAS-Match
RUN cp Common/conf/conf.template.ini Common/conf/conf.ini
RUN chmod a+rw /repo/SOLAS-Match/Common/conf/conf.ini
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini site location http://192.168.1.50/
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini site api http://192.168.1.50/api/
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini database server "127.0.0.1"
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini database username "tester"
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini database password "tester"

#install composer dependecies
WORKDIR /repo/SOLAS-Match/ui
RUN curl -s https://getcomposer.org/installer | php
RUN php composer.phar install
WORKDIR /repo/SOLAS-Match/api
RUN curl -s https://getcomposer.org/installer | php
RUN php composer.phar install

#install non composer dependecies
WORKDIR /repo/php-protocolbuffers
RUN phpize && ./configure && make && make install
RUN echo "extension=protocolbuffers.so" >>  /etc/php5/apache2/php.ini
RUN echo "[browscap]"  >>  /etc/php5/apache2/php.ini     >>  /etc/php5/apache2/php.ini
RUN echo "browscap = /etc/php5/apache2/php_browscap.ini"  >>  /etc/php5/apache2/php.ini    
RUN wget http://browscap.org/stream?q=PHP_BrowsCapINI -O /etc/php5/apache2/php_browscap.ini
RUN wget https://raw.githubusercontent.com/nathansmith/960-Grid-System/master/code/css/960.css -O  /repo/SOLAS-Match/resources/css/960.css
RUN sed  -e "s/AllowOverride.*/AllowOverride All/g" -i /etc/apache2/apache2.conf

#create sysmlinks and direcorties.
RUN sudo ln -s /repo/SOLAS-Match/* /var/www/
RUN chown -R  www-data:www-data /repo
RUN mkdir -p  /repo/SOLAS-Match/uploads -m 777
RUN mkdir -p  /repo/SOLAS-Match/ui/templating/templates_compiled -m 777
RUN mkdir -p  /repo/SOLAS-Match/ui/templating/cache -m 777
RUN chmod 777 /repo/SOLAS-Match/uploads
RUN chmod 777 /repo/SOLAS-Match/ui/templating/templates_compiled
RUN chmod 777 /repo/SOLAS-Match/ui/templating/cache

RUN apt-get install mysql-server mysql-client -y && sysv-rc-conf mysql on && sysv-rc-conf --list mysql
RUN sed -e "s/bind-address            = 127.0.0.1/bind-address            = 0.0.0.0/g" -i /etc/mysql/my.cnf
RUN service mysql start

WORKDIR /repo/SOLAS-Match/
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 -u root -e "create database SolasMatch;"
RUN service mysql start &&  mysql -h 127.0.0.1 -P 3306 -u root -e "CREATE USER 'tester'@'%.%.%.%' identified by 'tester';"
RUN service mysql start &&  mysql -h 127.0.0.1 -P 3306 -u root -e "GRANT ALL ON SolasMatch.* TO 'tester'@'%.%.%.%';"
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 -u root SolasMatch < api/vendor/league/oauth2-server/sql/mysql.sql
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 -u root SolasMatch < db/schema.sql
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 -u root SolasMatch < db/languages.sql
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 -u root SolasMatch < db/country_codes.sql
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 SolasMatch -e "INSERT INTO Users VALUES (1,'test','test@example.com','9deddc83b2f3f6f439d5afbe3128772e55fc4e7b36a01b8b5012fb9de13a601491d2ec5cc36e2e5956ec816eaa81a13cbc5f9ae33a4fd740e2c03260e2897a01',NULL,NULL,NULL,2069805492,'2015-03-15 01:16:16');"
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 SolasMatch -e " insert into SolasMatch.Admins (user_id) values (1);"

#expose webeserver port
EXPOSE 80
CMD ["/sbin/init"]
