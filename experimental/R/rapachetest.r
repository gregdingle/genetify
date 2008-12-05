#
hrefify <- function(title) gsub('[\\.()]','_',title,perl=TRUE)
#
scrub <- function(str){
#
if (is.null(str)) return('NULL')
#
if (length(str) == 0) return('length 0 string')
#
cat("\n<!-- before as.character: (",str,")-->\n",sep='')
#
str <- as.character(str)
#
cat("\n<!-- after as.character: (",str,")-->\n",sep='')
#
str <- gsub('&','&amp;',str); str <- gsub('@','_at_',str);
#
str <- gsub('<','&lt;',str); str <- gsub('>','&gt;',str);
#
if (length(str) == 0 || is.null(str) || str == '')
#
str <- '&nbsp;'
#
str
#
}
#
cl<-'e'
#
zebary <- function(i){
#
cl <<- ifelse(cl=='e','o','e')
#
cat('<tr class="',cl,'"><td>',scrub(i),'</td></tr>\n',sep='')
#
}
#
zeblist <- function(i,l){
#
cl <<- ifelse(cl=='e','o','e')
#
cat('<tr class="',cl,'"><td class="l">',names(l)[i],'</td><td>')
#
if(is.list(l[[i]]))
#
zebra(names(l)[i],l[[i]])
#
else {
#
if (length(l[[i]]) > 1)
#
zebary(l[[i]])
#
else
#
cat(scrub(l[[i]]))
#
}
#
#
cat('</td></tr>\n',sep='')
#
}
#
zebra <- function(title,l){
#
cat('<h2><a name="',hrefify(title),'"> </a>',title,'</h2>\n<table><tbody>',sep='')
#
ifelse(is.list(l),lapply(1:length(l),zeblist,l), lapply(l,zebary))
#
cat('</tbody></table>\n<br/><hr/>')
#
}
#
 
#
# Output starts here
#
setContentType("text/html")
#
 
#
if(is.null(GET)){
#
called <- 1
#
} else {
#
called <- as.integer(GET$called) + 1
#
}
#
 
#
setCookie('called',called,expires=Sys.time()+100)
#
 
#
cat('<HTML><head><style type="text/css">\n')
#
cat('table { border: 1px solid #8897be; border-spacing: 0px; font-size: 10pt; }')
#
cat('td { border-bottom:1px solid #d9d9d9; border-left:1px solid #d9d9d9; border-spacing: 0px; padding: 3px 8px; }')
#
cat('td.l { font-weight: bold; width: 10%; }\n')
#
cat('tr.e { background-color: #eeeeee; border-spacing: 0px; }\n')
#
cat('tr.o { background-color: #ffffff; border-spacing: 0px; }\n')
#
cat('</style></head><BODY><H1>Canonical Test for RApache</H1>\n')
#
cat('<form enctype=multipart/form-data method=POST action="/R?called=',called,'">\n',sep='')
#
cat('Enter a string: <input type=text name=name value=""><br>\n',sep='')
#
cat('Enter another string: <input type=text name=name value=""><br>\n',sep='')
#
cat('Upload a file: <input type=file name=fileUpload><br>\n')
#
cat('Upload another file: <input type=file name=anotherFile><br>\n')
#
cat('<input type=submit name=Submit>')
#
 
#
cat("<hr>\n")
#
zebra('CGI GET Data',GET)
#
zebra('CGI POST Data',POST)
#
zebra('Cookies',COOKIES)
#
if (!is.null(FILES)){
#
cat('<h2>Files Uploaded in POST Data</h2>\n')
#
for (n in names(FILES)){
#
zebra(paste("Form Variable",n),FILES[[n]])
#
}
#
}
#
zebra("SERVER Variables",SERVER)
#
cat("</BODY></HTML>\n")
#
 
#
DONE