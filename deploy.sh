# TODO: use git instead of svn

# svn co http://genetify.com/svn/genetify ./
svn revert *
svn up                      

# cat genetify.js | python jsmin.py > temp.js
# mv temp.js genetify.js

cd packer
perl jsPacker.pl -e62 -f -i ../genetify.js -o ../genetify.js
cd ..
