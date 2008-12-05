setHeader('content-type', 'text/html')

serverRoot = sub(SERVER$uri, '', SERVER$canonical_filename)
# cat(serverRoot)

bits = strsplit(SERVER$uri, '/')[[1]]
currentDir = paste(bits[1:length(bits)-1], collapse='/')
# cat(currentDir)

source(SERVER$canonical_filename, local=TRUE)