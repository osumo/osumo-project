# server.R
shinyServer(function(input, output, session) {
    loadData.mRNA <- function(){
        if(is.null(input$mRNA)){
            return(NULL)
        } else {
            mRNA.m<<-read.csv(input$mRNA$datapath)
        }

        return(dim( mRNA.m )) 
    }

    loadData.miRNA <- function(){
        if(is.null(input$miRNA)){
            return(NULL)
        } else {
            miRNA.m<<-read.csv(input$miRNA$datapath)
        }

        return(dim(miRNA.m))
    }

    loadData.clinical<- function(){
        if(is.null(input$clinical)){
            return(NULL)
        } else {
            clinical.m<<-read.csv(input$clinical$datapath)
        }

        return(dim(clinical.m))
    }

    clusters <- reactiveValues(cl1 = NULL, cl2 = NULL, combine = NULL)

    mRNACluster.b <- eventReactive(
        input$mRNACluster,
        {
            clusters$cl1 <- kmeans(t(mRNA.m), centers = input$mRNA_clusters_k)
            return(as.numeric(clusters$cl1$cluster))
        }
    )

    miRNACluster.b <- eventReactive(
        input$miRNACluster,
        {
            clusters$cl2 <-kmeans(t(miRNA.m), centers = input$miRNA_clusters_k)
            return(as.numeric(clusters$cl2$cluster))
        }
    )

    output$mRNA.info<-reactive({loadData.mRNA()})
    output$miRNA.info<-reactive({loadData.miRNA()})
    output$clinical.info<-reactive({loadData.clinical()})

    output$mRNAheatmapplot <- renderPlot({
        cl<-mRNACluster.b()
        k <- max(cl)
        data <- t(mRNA.m)

        cluster_index<-matrix()
        length(cluster_index)<-k

        for(i in 1:k) {
            cluster_index[i]<-length(cl[cl == i])
        }

        ord<-order(cluster_index, decreasing=T)

        temp = data[cl == ord[1],];

        seperation<-matrix(nrow=10,ncol=dim(data)[2])
        temp<-rbind(temp, seperation)

        for(i in 2:k) {
            temp<-rbind(temp , data[cl == ord[i],],  seperation)
        }

        color_palette <- colorRampPalette(rev(c("#D73027",
                                                "#FC8D59",
                                                "#FEE090",
                                                "#FFFFBF",
                                                "#E0F3F8",
                                                "#91BFDB",
                                                "#4575B4")))

        pheatmap(temp[,1:dim(data)[2]],
                 cluster_rows=F,
                 cluster_cols=F,
                 show_rownames=F,
                 show_colnames=F,
                 width=100,
                 height=200,
                 border_color=NA,
                 color=color_palette(100))
    })

    output$miRNAheatmapplot <- renderPlot({
        cl<-miRNACluster.b()
        k <- max(cl)
        data <- t(miRNA.m)

        cluster_index<-matrix()
        length(cluster_index)<-k

        for(i in 1:k) {
            cluster_index[i]<-length(cl[cl == i])
        }

        ord<-order(cluster_index, decreasing=T)
        temp = data[cl == ord[1],];

        seperation<-matrix(nrow=10,ncol=dim(data)[2])
        temp<-rbind(temp, seperation)

        for(i in 2:k) {
            temp<-rbind(temp , data[cl == ord[i],],  seperation)
        }

        color_palette <- colorRampPalette(rev(c("#D73027",
                                                "#FC8D59",
                                                "#FEE090",
                                                "#FFFFBF",
                                                "#E0F3F8",
                                                "#91BFDB",
                                                "#4575B4")))

        pheatmap(temp[,1:dim(data)[2]],
                 cluster_rows=F,
                 cluster_cols=F,
                 show_rownames=F,
                 show_colnames=F,
                 width=100,
                 height=200,
                 border_color=NA,
                 color=color_palette(100))
    })

    # surv<-function(selectedlists){
    #     #get the node
    #     selectedlists$GROUP1$node
    # }

    # output$results = renderPlot({
    #     #test<<- input$mydata
    #     barplot(as.numeric(input$mydata$GROUP1$node))
    # })

    output$clustering.info = renderPlot({
        if(length(input$mydata$GROUP1$node) > 0) {
            idx<-c(rep(1,400),rep(2,223))
            sm <-sample.int(623, size = 120)
            surv<-Surv(clinical.m$time, clinical.m$cencer)
            fit<-survfit(surv ~ as.factor(idx))
            sdf<-survdiff(surv ~ as.factor(idx))
            p.val =( 1 - pchisq(sdf$chisq, length(sdf$n) - 1) )
            plot(fit, col=c(1:5),lwd=4,cex.axis=1.5, font.axis = 2)
        }
    })

    observe({
        if(!is.null(clusters$cl1) & !is.null(clusters$cl2)) {
            clusters$combine <- vis_data(clusters$cl1, clusters$cl2)
            session$sendCustomMessage(type='myCallbackHandler',
                                      toJSON(clusters$combine))
        }
    })

    # observe({
    #     test<<-input$mydata
    # })
})

