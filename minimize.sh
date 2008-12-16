cd genetify
test -f genetify.js.BACKUP || cp genetify.js genetify.js.BACKUP
../jsmin.py < genetify.js.BACKUP > genetify.js
