
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
    fr = getVariantRewards(params['domain'], params['page'], params['gene_name'])
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
        params['height'] = length(unique(gene_variant))
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
                       
getVariantRewards = function(domain, page, gene_name) {
    if (is.na(gene_name)) {
        gene_name = '%'    
    }
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
    dbDisconnect(conn)
    fr
}

graph = function(path, gfunc) { 
    Cairo(file=path)
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
    cat('hello')
    stop()
    Cairo(width=width, height=height, units='in', dpi=72, type="png")
    

    path = paste(basepath, filenames['boxplot'], sep='/')
    graph(path, function() { boxplot(
        form, 
        horizontal=TRUE, 
        varwidth=TRUE)
    })

    path = paste(basepath, filenames['stripchart'], sep='/')
    graph(path, function() { stripchart(
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

main()