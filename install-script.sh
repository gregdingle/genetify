
test -f genetify/genetify.js || echo 'This script needs to be run from the genetify root check out dir'

mysql -u root -p

# TODO: mysql execute all from bash
CREATE DATABASE genetify;
USE genetify;
SOURCE schema.sql;

CREATE USER genetify_user IDENTIFIED BY 'mypassword';
GRANT ALL ON genetify.* TO 'genetify_user'@'%';
FLUSH PRIVILEGES;

vi genetify/CONFIG.php

# shell
chmod 777 genetify/cache
chmod 777 genetify/Browscap/cache



# TODO: full install script...

# "$RANDOM$RANDOM$RANDOM" password
user=me
host=genetify.com
pass=mypass
db=genetify_database
cat genetify/CONFIG.php | sed "s/localhost/$host/" | sed "s/gregdingle/$user/" | sed "s/pass/$pass/" | sed "s/genetify/$db/"
