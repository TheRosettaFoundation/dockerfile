cd /repo/SOLAS-Match/
service mysql start
mysql -h 127.0.0.1 -P 3306 -u root -e "create database SolasMatch;"
mysql -h 127.0.0.1 -P 3306 -u root -e "CREATE USER 'tester'@'%.%.%.%' identified by 'tester';"
mysql -h 127.0.0.1 -P 3306 -u root -e "GRANT ALL ON SolasMatch.* TO 'tester'@'%.%.%.%';"
mysql -h 127.0.0.1 -P 3306 -u root SolasMatch < api/vendor/league/oauth2-server/sql/mysql.sql
mysql -h 127.0.0.1 -P 3306 -u root SolasMatch < db/schema.sql
mysql -h 127.0.0.1 -P 3306 -u root SolasMatch < db/languages.sql
mysql -h 127.0.0.1 -P 3306 -u root --default-character-set=utf8 SolasMatch < db/country_codes.sql
mysql -h 127.0.0.1 -P 3306 SolasMatch -e "INSERT INTO Users VALUES (1,'test','test@example.com','9deddc83b2f3f6f439d5afbe3128772e55fc4e7b36a01b8b5012fb9de13a601491d2ec5cc36e2e5956ec816eaa81a13cbc5f9ae33a4fd740e2c03260e2897a01',NULL,NULL,NULL,2069805492,'2015-03-15 01:16:16');"
mysql -h 127.0.0.1 -P 3306 SolasMatch -e "INSERT INTO UserPersonalInformation VALUES (1, 1, NULL, NULL, NULL, NULL, 1785, NULL, NULL, NULL, NULL, 0);"
mysql -h 127.0.0.1 -P 3306 SolasMatch -e "INSERT INTO oauth_clients (id, secret, name, auto_approve) VALUES('yub78q7gabcku73FK47A4AIFK7GAK7UGFAK4', 'sfvg7gir74bi7ybawQFNJUMSDCPOPi7u238OH88rfi', 'trommons', 1);"
#TODO update ubuntu64 to be generic
mysql -h 127.0.0.1 -P 3306 SolasMatch -e "INSERT INTO oauth_client_endpoints (client_id, redirect_uri) VALUES ('yub78q7gabcku73FK47A4AIFK7GAK7UGFAK4', 'http://ubuntu64/login/');"
mysql -h 127.0.0.1 -P 3306 SolasMatch -e " insert into SolasMatch.Admins (user_id) values (1);"
