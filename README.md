# dockerfile
Dockerfile and associated files for SOLAS-Match

This Dockerfile creates an image for The Rosetta Foundation's (http://www.therosettafoundation.org/) Translation Commons (http://trommons.org/)

It supports the Web Application "SOLAS-Match" and the C++ back end which sends e-mails etc.

It builds an image using this command...<br />
sudo docker build -t therosetta/trommons:v3 https://github.com/TheRosettaFoundation/dockerfile.git<br />
This image is available on https://hub.docker.com/

The image can be used for SOLAS-Match development using the following process...

* Create a 64 bit Ubuntu VM called "ubuntu64" (or use existing VM or real system, the name can be different if necessary)<br />
(distributions other than Ubuntu should work)

* When creating this VM do not install Apache (this is to leave port 80 free)<br />
(is it also possible to issue "sudo update-rc.d -f apache2 remove", if you have Apache installed to stop it running)

* Install docker:<br />
wget -qO- https://get.docker.com/ | sh<br />
sudo usermod -aG docker YOUR_UNIX_USER_NAME

* sudo docker run -d -p 80:80 --name solas --hostname=solas therosetta/trommons:v3

* "sudo docker ps" should now show your running Docker container with a name of "solas"

* "sudo docker exec -i -t solas bash" will open a bash shell inside the container

* Then, if you did not use the name "ubuntu64" for your VM, issue the following commands (replacing "ubuntu64" with your actual hostname)<br />
export TERM=dumb<br />
crudini --set /repo/SOLAS-Match/Common/conf/conf.ini site location http://ubuntu64/<br />
crudini --set /repo/SOLAS-Match-Backend/conf.ini site url http://ubuntu64/<br />
mysql -h 127.0.0.1 -P 3306 SolasMatch -e "UPDATE oauth_client_endpoints SET redirect_uri='http://ubuntu64/login/' WHERE client_id='yub78q7gabcku73FK47A4AIFK7GAK7UGFAK4';"

* To see the front end log: view /var/log/apache2/error.log

* Keep the bash shell open (if desired to get the backend running below)

* You should now be able to browse to "http://ubuntu64" in your browser and Trommons will come up and should function

* There is a user called "test@example.com" with a password of "test", login with these.

* To get the Backend C++ Application to run you will first need to create an organisation and maybe a project on the front end UI first.<br />
This gets the SOLAS_MATCH exchange created (for RabbitMQ).

* In your bash shell, to run the Backend C++ Application issue teh following commands<br />
cd /repo/SOLAS-Match-Backend<br />
./run_daemon.sh &disown<br />
ps -ef | grep Plugin
# Note the process number so that later you can kill the Backend Process using "kill PROCESS_NUMBER"

* To see the Backend C++ log: "view /etc/SOLAS-Match/output.log" or "tail --lines=50 /etc/SOLAS-Match/output.log"

* (The RabbitMQ log: "view /var/log/rabbitmq/rabbit@solas64.log", Settings etc are here... https://www.rabbitmq.com/relocate.html)

* To get SMTP working, install postfix...<br />
Edit /etc/postfix/main.cf to set: smtpd_use_tls=no<br />
Then issue: postfix reload

* Issue "exit" to exit the shell (when desired)

* Issue "sudo docker stop solas" to stop the container

* Issue "sudo docker start solas" to start the container at a later stage with all your data changes intact

* Do not issue "docker run..." again unless you want to start a new container without your data changes (use a different name)

Alan Barrett
alanabarrett0@gmail.com