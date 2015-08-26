FROM ubuntu-upstart
MAINTAINER Alan Barrett <alanabarrett0@gmail.com>

ENV TERM dumb

# Install apache and php
RUN apt-get update && apt-get install git wget apache2 php5 libapache2-mod-php5 curl crudini nano -y
RUN a2enmod rewrite
RUN apt-get install libapache2-mod-xsendfile sudo subversion php5-dev php-apc php5-mysql php5-mcrypt php5-curl php5-cli re2c -y
RUN apt-get install sysv-rc-conf -y && sysv-rc-conf apache2 on && sysv-rc-conf --list apache2
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY apache2.conf /etc/apache2/apache2.conf

# Clone git repos
RUN mkdir /repo -m 777
WORKDIR /repo
RUN git clone https://github.com/TheRosettaFoundation/SOLAS-Match.git
RUN git clone https://github.com/chobie/php-protocolbuffers.git

# Add basic config #TODO update ubuntu64 to be generic
WORKDIR /repo/SOLAS-Match
RUN git checkout docker
RUN cp Common/conf/conf.template.ini Common/conf/conf.ini
RUN chmod a+rw /repo/SOLAS-Match/Common/conf/conf.ini
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini site location http://ubuntu64/
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini site api http://127.0.0.1/api/
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini database server "127.0.0.1"
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini database username "tester"
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini database password "tester"
RUN crudini --set /repo/SOLAS-Match/Common/conf/conf.ini files upload_path "'uploads/'"

# Install composer dependencies
WORKDIR /repo/SOLAS-Match/ui
RUN curl -s https://getcomposer.org/installer | php
RUN php composer.phar install
WORKDIR /repo/SOLAS-Match/api
RUN curl -s https://getcomposer.org/installer | php
RUN php composer.phar install

# Install non composer dependencies
WORKDIR /repo/php-protocolbuffers
RUN phpize && ./configure && make && make install
RUN echo "extension=protocolbuffers.so" >>  /etc/php5/apache2/php.ini
RUN echo "[browscap]"  >>  /etc/php5/apache2/php.ini     >>  /etc/php5/apache2/php.ini
RUN echo "browscap = /etc/php5/apache2/php_browscap.ini"  >>  /etc/php5/apache2/php.ini    
RUN wget http://browscap.org/stream?q=PHP_BrowsCapINI -O /etc/php5/apache2/php_browscap.ini
RUN wget https://raw.githubusercontent.com/nathansmith/960-Grid-System/master/code/css/960.css -O  /repo/SOLAS-Match/resources/css/960.css
RUN sed  -e "s/AllowOverride.*/AllowOverride All/g" -i /etc/apache2/apache2.conf

# Create symlinks and directories
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
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 -u root --default-character-set=utf8 SolasMatch < db/country_codes.sql
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 SolasMatch -e "INSERT INTO Users VALUES (1,'test','test@example.com','9deddc83b2f3f6f439d5afbe3128772e55fc4e7b36a01b8b5012fb9de13a601491d2ec5cc36e2e5956ec816eaa81a13cbc5f9ae33a4fd740e2c03260e2897a01',NULL,NULL,NULL,2069805492,'2015-03-15 01:16:16');"
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 SolasMatch -e "INSERT INTO UserPersonalInformation VALUES (1, 1, NULL, NULL, NULL, NULL, 1785, NULL, NULL, NULL, NULL, 0);"
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 SolasMatch -e "INSERT INTO oauth_clients (id, secret, name, auto_approve) VALUES('yub78q7gabcku73FK47A4AIFK7GAK7UGFAK4', 'sfvg7gir74bi7ybawQFNJUMSDCPOPi7u238OH88rfi', 'trommons', 1);"
#TODO update ubuntu64 to be generic
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 SolasMatch -e "INSERT INTO oauth_client_endpoints (client_id, redirect_uri) VALUES ('yub78q7gabcku73FK47A4AIFK7GAK7UGFAK4', 'http://ubuntu64/login/');"
RUN service mysql start && mysql -h 127.0.0.1 -P 3306 SolasMatch -e " insert into SolasMatch.Admins (user_id) values (1);"

# Install RabbitMQ (SOLAS-Match gives error if it is not running, even if C++ back end if not running)

# upstart (initctl) will not work, but init should start RabbitMQ later
# So make initctl return true
# Note there are other upstart errors before this point, but they do not stop the build
# https://github.com/docker/docker/issues/1024
# https://www.nesono.com/node/368
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# First remove any existing old installation
RUN apt-get remove rabbitmq-server -y
WORKDIR /repo
RUN wget https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
RUN apt-key add rabbitmq-signing-key-public.asc
RUN echo "deb http://www.rabbitmq.com/debian/ testing main" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install rabbitmq-server -y

# Replace initctl
RUN unlink /sbin/initctl
RUN dpkg-divert --rename --remove /sbin/initctl


# Backend C++ Application Prerequisites

RUN apt-get install build-essential libmysqlclient-dev -y
RUN apt-get build-dep qt5-default -y
RUN apt-get install qt5-default -y
RUN apt-get install qt5-qmake -y

WORKDIR /repo
RUN mkdir -p  /repo/dependencies -m 777
RUN chmod 777 /repo/dependencies

# Install rabbitmq-c (C Library for RabbitMQ)
RUN apt-get install cmake -y
WORKDIR /repo
RUN wget https://github.com/alanxz/rabbitmq-c/archive/v0.7.0.tar.gz
RUN gunzip v0.7.0.tar.gz
RUN tar xvf v0.7.0.tar
RUN mv rabbitmq-c-0.7.0 /repo/dependencies/rabbitmq-c
WORKDIR /repo/dependencies/rabbitmq-c/librabbitmq
RUN cmake ..
RUN cmake --build .
RUN cmake --build . --target install

# Install amqpcpp (C++ Library for rabbitmq-c for RabbitMQ)
WORKDIR /repo/dependencies
RUN git clone https://github.com/TheRosettaFoundation/amqpcpp.git
WORKDIR /repo/dependencies/amqpcpp
RUN make
WORKDIR /repo/dependencies/amqpcpp
RUN cp -p libamqpcpp.so /usr/local/lib/
RUN chown root:root /usr/local/lib/libamqpcpp.so
RUN cp -p libamqpcpp.a /usr/local/lib/
RUN chown root:root /usr/local/lib/libamqpcpp.a
RUN cp -p include/AMQPcpp.h /usr/local/include/
RUN chown root:root /usr/local/include/AMQPcpp.h

# Template Library
WORKDIR /repo/dependencies
RUN apt-get install libctemplate-dev -y

# Backend C++ Application
WORKDIR /repo
RUN git clone https://github.com/TheRosettaFoundation/SOLAS-Match-Backend.git
WORKDIR /repo/SOLAS-Match-Backend
RUN git checkout qt5
RUN git pull origin qt5

# Links
WORKDIR /etc
RUN mkdir -p  /etc/SOLAS-Match -m 777
RUN chmod 777 /etc/SOLAS-Match
WORKDIR /etc/SOLAS-Match
RUN ln -s /repo/SOLAS-Match-Backend/templates/ templates
RUN ln -s /repo/SOLAS-Match-Backend/schedule.xml schedule.xml

# Configuration for Backend
WORKDIR /repo/SOLAS-Match-Backend
RUN cp conf.template.ini conf.ini
RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini database username "tester"
RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini database password "tester"

RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini mail server '"localhost"'
RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini mail password '""'
RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini mail user '""'
RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini mail admin_emails '"alanabarrett0@gmail.com"'

RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini site url http://ubuntu64/
RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini site system_email_address "'alanabarrett0@gmail.com'"
RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini site notifications_monitor_email_address "'alanabarrett0@gmail.com'"
RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini site log '"/etc/SOLAS-Match/output.log"'
RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini site max_threads 15

RUN crudini --set /repo/SOLAS-Match-Backend/conf.ini email-footer donate_link '"http://www.therosettafoundation.org/donate/"'

WORKDIR /etc/SOLAS-Match
RUN ln -s /repo/SOLAS-Match-Backend/conf.ini conf.ini

# Schedule (speeded up) for Backend
WORKDIR /repo/SOLAS-Match-Backend
RUN cp -p schedule.xml schedule.xml.git
COPY schedule.xml /repo/SOLAS-Match-Backend/schedule.xml

# Compile Backend C++ Application
WORKDIR  /repo/SOLAS-Match-Backend
RUN qmake
RUN make

# Links in PluginHandler/
WORKDIR /repo/SOLAS-Match-Backend/PluginHandler
RUN ln -s /repo/SOLAS-Match-Backend/conf.ini conf.ini
RUN ln -s /repo/SOLAS-Match-Backend/schedule.xml schedule.xml
RUN ln -s /repo/SOLAS-Match-Backend/templates templates

# Script to run Backend C++ Application
WORKDIR /repo/SOLAS-Match-Backend
COPY run_daemon.sh /repo/SOLAS-Match-Backend/run_daemon.sh
RUN chmod 755 run_daemon.sh

# Expose web server port
EXPOSE 80
CMD ["/sbin/init"]
