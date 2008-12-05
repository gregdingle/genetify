Cairo = function (width = 640, height = 480, file = "", type = "png", 
    pointsize = 12, bg = "transparent", canvas = "white", units = "px", 
    dpi = "auto", ...) 
{
    ctype <- tolower(type)
    # if (!ctype %in% names(.supported.types)) 
    #     stop("Unknown output type `", type, "'.")
    # ctype <- .supported.types[ctype == names(.supported.types)]
    ctype = 'png'
    if (is.null(file) || !nchar(file)) 
        file <- if (ctype != "x11") 
            paste("plot.", ctype, sep = "")
        else Sys.getenv("DISPLAY")
    if (typeof(file) == "character" && length(file) != 1) 
        stop("file must be a character vector of length 1 or a connection")
    else if (inherits(file, "connection") && (summary(file)$opened != 
        "opened" || summary(file)$"can write" != "yes")) 
        stop("connection must be open and writeable")
    if (length(units) != 1 || !units %in% c("px", "pt", "in", 
        "cm", "mm")) 
        stop("invalid unit (supported are px, pt, in, cm and mm)")
    if (any(dpi == "auto" || dpi == "")) 
        dpi <- 0
    if (length(dpi) != 1 || !is.numeric(dpi) || dpi < 0) 
        stop("invalid dpi specification (must be 'auto' or a positive number)")
    dpi <- as.double(dpi)
    umpl <- as.double(c(-1, 1/72, 1, 1/2.54, 1/25.4)[units == 
        c("px", "pt", "in", "cm", "mm")])
    gdn <- .External("cairo_create_new_device", as.character(ctype), 
        file, width, height, pointsize, bg, canvas, umpl, dpi, 
        ..., PACKAGE = "Cairo")          

        cat('hello')    
        
        
    # par(bg = bg)
    # invisible(structure(gdn, class = c("Cairo", paste("Cairo", 
    #     toupper(ctype), sep = "")), type = as.character(ctype), 
    #     file = file))
}

CairoPNG = function (filename = "Rplot%03d.png", width = 480, height = 480, 
    pointsize = 12, bg = "white", res = NA, ...) 
{
    Cairo(width, height, type = "png", file = filename, pointsize = pointsize, 
        bg = bg, ...)
}


# TODO: extra // 
serverRoot = sub(SERVER$uri, '', SERVER$canonical_filename)

bits = strsplit(SERVER$uri, '/')[[1]]
currentDir = paste(bits[1:length(bits)-1], collapse='/')

path = paste(serverRoot, 'genetify/graphs', 'test.png', sep='/')


#
# Output starts here
#
setContentType("text/html")
cat('<HTML><head><title>r test page</title></head><body>')

# sink('/dev/null')
cat('<b>hello</b>')  
cat(Sys.getenv("DISPLAY"))
library(Cairo)
write(1:10, file=path)


# CairoPNG()           
sink('/dev/null')
CairoPNG(filename=path) 
# plot(1:10, 1:10)
# dev.off() #writes file   
# cat('hello')  


# setHeader('content-type',"text/html")
# cat(Sys.getenv("DISPLAY"))
# library(Cairo)
# sink('/dev/null')
# # CairoPNG()       
# cat('hello')  
# sink()
# quit()
# stop()

cat('</body></HTML>')