# cat genetify.js | python jsmin.py > temp.js
# mv temp.js genetify.js

cd packer
perl jsPacker.pl -e62 -f -i ../genetify.js -o ../genetify.js
cd ..
