# dockerfile
Dockerfile and associated files for SOLAS-Match

This Dockerfile creates an image for The Rosetta Foundation's (http://www.therosettafoundation.org/) Translation Commons (http://trommons.org/)

It so far supports the Web Application "SOLAS-Match", not the C++ back end which sends e-mails etc.

It builds an image using this command...<br />
sudo docker build -t therosetta/trommons:v2 https://github.com/TheRosettaFoundation/dockerfile.git<br />
This image is available on https://hub.docker.com/

The image can be used for SOLAS-Match development using the following process...

* Create a 64 bit Ubuntu VM called "ubuntu64" (or use existing VM or real system, the name can be different if necessary)<br />
(distributions other than Ubuntu should work)

* When creating this VM do not install Apache (this is to leave port 80 free)<br />
(is it also possible to issue "sudo update-rc.d -f apache2 remove", if you have Apache installed to stop it running)

* Install docker:<br />
wget -qO- https://get.docker.com/ | sh<br />
sudo usermod -aG docker YOUR_UNIX_USER_NAME

* sudo docker run -d -p 80:80 --name solas --hostname=solas therosetta/trommons:v2

* "sudo docker ps" should now show your running Docker container with a name of "solas"

* "sudo docker exec -i -t solas bash" will open a bash shell inside the container

* If you did not use the name "ubuntu64" for your VM, issue the following commands (replacing "ubuntu64" with your actual hostname)<br />
export TERM=dumb<br />
crudini --set /repo/SOLAS-Match/Common/conf/conf.ini site location http://ubuntu64/<br />
mysql -h 127.0.0.1 -P 3306 SolasMatch -e "UPDATE oauth_client_endpoints SET redirect_uri='http://ubuntu64/login/' WHERE client_id='yub78q7gabcku73FK47A4AIFK7GAK7UGFAK4';"

* You should now be able to browse to "http://ubuntu64" in your browser and Trommons will come up and should function

* There is a user called "test@example.com" with a password of "test"

* Issue "exit" to exit the shell (if desired)

* Issue "sudo docker stop solas" to stop the container

* Issue "sudo docker start solas" to start the container at a later stage with all your data changes intact

* Do not issue "docker run..." again unless you want to start a new container without your data changes (use a different name)

Alan Barrett
alanabarrett0@gmail.com