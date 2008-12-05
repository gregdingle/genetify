
# TODO: why doesn't Sys.getenv in function body ?
main = function(qs=Sys.getenv('QUERY_STRING')) { 

    if (qs != '') {
        options(error = function(){ cat(geterrmessage()); })
        params = parseqs(qs)   
    }
    else {
        # options(error = recover)
        params = c(
            domain='localhost.com', 
            page='/genetify/test.php', 
            width=5, 
            callback='handleGraphs')
    } 
    
    requiredParams = c('domain', 'page', 'width', 'callback')
    t = mapply(assert, !is.na(params[requiredParams]), paste(requiredParams, 'is required'))
          

    if (exists('fr')) remove(fr)
    fr = getRewards(params['domain'], params['page'], params['gene_name'])
    attach(fr)         
      
    # TODO: handling of invalid plotting
    # if (length(fr) == 0) {
    #     filenames = c(
    #             'boxplot'=FALSE, 
    #             'stripchart'=FALSE
    #     )    
    #     printJSON(filenames, params['callback'])
    #     q()
    # }
    

    if (is.na(params['height'])) {
        params['height'] = length(unique(gene_variant)) + 1
    }
    filenames = writeGraph(reward ~ gene_variant, as.numeric(params['width']), as.numeric(params['height']))

    printJSON(filenames, params['callback'])
}    

printJSON = function(var, callback='') { 
    library(rjson)
    out = paste(callback, '(', toJSON(var), ')', sep='')
    cat(out)
}

parseqs = function(raw){
    library(CGIwithR, warn.conflicts=FALSE) 
    qs = scanText(raw)[1]
    split = strsplit(unlist(strsplit(qs, '&')  ), '=')
    parsed = unlist(lapply(split, function(l) {
        nl = list(l[[2]])
        names(nl) = l[[1]] 
        nl
    }))
    parsed
}                       

getRewards = function(domain='localhost.com', page='/genetify/test.php', gene_name='%') {
    
    # TODO: ssh tunneling
    # tunnel = 'ssh -L3307:127.0.0.1:3306 -p 22 -N -t -x gregdingle@spinnaker.joyent.us &'
    # system(tunnel)
    
    library(RMySQL)
    conn = dbConnect(MySQL(), host="localhost", user="gregdingle", password="", dbname="genetify")
    # dbListTables(conn) 
    # TODO: guard against sql injection
    sql = paste(
        'select * from variant_reward where domain_name = ', domain, 
        ' and page_name = ', page, 
        ' and gene_name like ', gene_name, 
        ' order by gene_name, variant_name', sep='"'
    )
    fr = dbGetQuery(conn, sql)
    # TODO: reorder factors
    dbDisconnect(conn)  
       
    fr
}
                          
graph = function(path, width, height, gfunc) {     
    # TODO: is it possible to change the Cairo context without re-intializing?
    Cairo(width, height, file=path, units='in', dpi=72, type='png')
    par(las=1, fig=c(0.33, 1, 0, 1))

    gfunc()
    axis(3) #draw axis above                  

    file.remove(path)
    dev.off() #writes file
}

writeGraph = function(form, width, height) { 
        
    # TODO: does device matter here?
    # quartz(width=width, height=height) 
    library(Cairo)
    
    basepath = paste(getwd(), '../graphs', sep='/')     
    filenames = c(
            'boxplot'='boxplot.png', 
            'stripchart'='stripchart.png'
    )    
    
    path = paste(basepath, filenames['boxplot'], sep='/')
    graph(path, width, height, function() { boxplot(
        form, 
        horizontal=TRUE, 
        varwidth=TRUE)
    })

    path = paste(basepath, filenames['stripchart'], sep='/')
    graph(path, width, height, function() { stripchart(
        form, 
        pch=1, 
        method='jitter', 
        jitter=0.1) 
    })
    
    filenames

    # TODO: reuse?
    # library(lattice)                        
    # bwplot(reward ~ variant_name | gene_name)

}   

assert = function(boolean, msg) {   
    if (boolean == FALSE) {
        cat(msg)
        q()
    }
}     

ftest = function(fr=getRewards(gene_name='mygene')){ 

    # TODO: figure out labels!!
    # fr$gene_variant = factor(fr$gene_variant)
    # levels(fr$gene_variant) = c(levels(fr$gene_variant)[4], levels(fr$gene_variant)[1:3])

    
    # mod = lm(scale(fr$reward, scale=FALSE) ~ FAC)
    mod = lm(fr$reward ~ fr$gene_variant)
    print(summary(mod))
    mod
}

bootY = function(fr=getRewards(gene_name='mygene')){ 
    
    fr$gene_variant = factor(fr$gene_variant)
    mod = lm(fr$reward ~ fr$gene_variant)
    fit = fitted(mod)
    e = residuals(mod)
    X = model.matrix(mod)
    
    bootlm = function(data, indices) { 
        y = fit + e[indices] 
        # mod = lm(y ~ X - 1)
    	mod = lm(y ~ fr$gene_variant)
    	coefficients(mod)
    } 
    
    library(boot)
    bootmod = boot(fr, bootlm, 1999)
    print(summary(bootmod))
    bootmod
}


# main()