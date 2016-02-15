require(jsonlite)
require(pheatmap)
require(factoextra)
require(survival)

#clustering_result<-NULL
miRNA.m <- NULL
mRNA.m <- NULL
clinical.m <- NULL

#mRNA.m<-read.csv('data/mRNA.sample.csv')
#miRNA.m<-read.csv('data/miRNA.sample.csv')
#clinical.m<-read.csv('data/time.cencer.csv')

test<-NULL

miRNA.cl<-NULL
mRNA.cl<-NULL

metric.s<- c('Euclidean Distance', 'Correlation')
algorithm.s<- c('Kmeans', 'Spectral Clustering')


## helper function
file_content <- function(file) {
  return(readChar(file, file.info(file)$size))
}
## generate visualization data
vis_data <- function(mRNA.cl, miRNA.cl){
  mRNA.k<-length(mRNA.cl$size)
  mRNA.label<- rep("mRNA", mRNA.k)
  mRNA.key <- as.character(sort.int(mRNA.cl$size,decreasing = T,index.return = T)$ix)
  mRNA.height <- sort.int(mRNA.cl$size,decreasing = T,index.return = T)$x
  mRNA.id <- mRNA.key
  mRNA.offsetValue <-c(0, cumsum(sort.int(mRNA.cl$size,decreasing = T,index.return = T)$x)[1:mRNA.k-1])
  rv1<-data.frame(label = mRNA.label, key = mRNA.key, height = mRNA.height, order = c(0:(mRNA.k-1)),
                  offsetValue = mRNA.offsetValue, links = c(1:mRNA.k), incoming = c(1:mRNA.k))
  
  miRNA.k<-length(miRNA.cl$size)
  miRNA.label<- rep("miRNA", miRNA.k)
  miRNA.key <- as.character(sort.int(miRNA.cl$size, decreasing = T,index.return = T)$ix)
  miRNA.height <- sort.int(miRNA.cl$size,decreasing = T,index.return = T)$x
  miRNA.id <- mRNA.key
  miRNA.offsetValue <-c(0, cumsum(sort.int(miRNA.cl$size,decreasing = T,index.return = T)$x)[1:miRNA.k-1])
  rv2<-data.frame(label = miRNA.label, key = miRNA.key, height = miRNA.height, order = c(0:(miRNA.k-1)),
                  offsetValue = miRNA.offsetValue, links = c(1:miRNA.k), incoming = c(1:miRNA.k))
  
  df <- data.frame(source=integer(),
                   target=integer(), 
                   count=integer(), 
                   outOffset=integer(),
                   inOffset= integer())
  
  for (i in 1:length(mRNA.cl$size)){
    for (j in 1:length(miRNA.cl$size)){
      count<-sum((mRNA.cl$cluster == as.integer(mRNA.key[i]) & miRNA.cl$cluster == as.integer(miRNA.key[j])))
      df<-rbind(df,data.frame(source= as.integer(mRNA.key[i]),
                              target=as.integer(miRNA.key[j]), 
                              count=count, 
                              outOffset=0,
                              inOffset= 0 )) 
    }
  }
  for (i in 1:nrow(df)){
    source <- df$source[i]
    target <- df$target[i]
    df$outOffset[i] <- sum(df$count[df$source == source & df$count>df$count[i]])
    df$inOffset[i] <- sum(df$count[df$target == target & df$count>df$count[i]])
  }
  
  rv1$links <- lapply(mRNA.key, function(x){
    idx<- df$source == as.numeric(x)
    tmp<- df[idx,]
    return(tmp[order(tmp$count, decreasing = T),])
  })
  rv2$incoming <- lapply(miRNA.key, function(x){
    idx<- df$target == as.numeric(x)
    tmp<- df[idx,]
    return(tmp[order(tmp$count, decreasing = T),])
  })
  return(list(rv1,rv2))
}


# plot the survival image
SURV_PLOT<-function(g1,g2,g3, plotname){
  op <- read.csv("../data/input/time_cencer.csv")
  
  mRNA_cluster <-read.csv("../data/input/mRNA_group.csv")
  miRNA_cluster<-read.csv("../data/input/miRNA_group.csv")
  
  mRNA_cluster<-as.factor(mRNA_cluster[,2])
  miRNA_cluster<-as.factor(miRNA_cluster[,2])
  indicator<-data.frame(mRNA_cluster=mRNA_cluster, miRNA_cluster=miRNA_cluster,
                        joint=interaction(mRNA_cluster,miRNA_cluster))
  
  index <- matrix()
  length(index)<-length(mRNA_cluster)
  if(is.na(g1)){  
    png(type='cairo',filename=plotname,width=700,height=500)
    #cat('save file')
    sink('/dev/null')  
    plot(x = rep(-50, 200), y = rep(0,200),ylim=c(0,1),xlim=c(1,230), xlab="Time (Month)", ylab = "Survival Probability", cex.axis=1.5, font.axis = 2)
    
    text(5, 0.05, paste("p-value =", 0), adj = c(0,0), font=2 )
    title(main = list("Kaplan-Meier Survival Plot", cex = 2, font = 2))
    #legend(140,1, c(paste(g1,'(n = 301)'), paste(g2,'(n = 322)')), col=c(1:2), lwd=3)
    dev.off()
    sink()
  }
  else{
    if(!is.na(g1))
    {
      g1_<-unlist(strsplit(g1, ","))
      l<-length(g1_)
      for(i in 1:l){
        #cat(g1[i])
        if(substr(g1_[i], 1, 1)=='m')
        {
          if(substr(g1_[i], 2, 2) == 'i'){
            index[which(indicator[,2]== unlist(strsplit(g1_[i],"_"))[2])] <-1
          }
          else{
            index[which(indicator[,1]== unlist(strsplit(g1_[i],"_"))[2])] <-1
          }
        }
        else
        {
          index[which(indicator[,3]==g1_[i])] <-1
        }
      }
      #cat('\n')
    }
    else{
    }
    if(!is.na(g2))
    {
      g2_<-unlist(strsplit(g2,","))
      l<-length(g2_)
      for(i in 1:l){
        #cat(g2_[i])
        if(substr(g2_[i], 1, 1)=='m')
        {
          if(substr(g2_[i], 2, 2) == 'i'){
            index[which(indicator[,2]==unlist(strsplit(g2_[i],"_"))[2])] <-2
          }
          else{
            index[which(indicator[,1]==unlist(strsplit(g2_[i],"_"))[2])] <-2
          }
        }
        else
        {
          index[which(indicator[,3]==g2_[i])] <-2     
        }
      }
    }
    if(!is.na(g3))
    {
      g3<-unlist(strsplit(g3,","))	
      #cat(g3)
    }
    
    
    fit<-survfit(Surv(op[which(!is.na(index)),2]/30,op[which(!is.na(index)),3])~as.factor(index[which(!is.na(index))]))
    sdf<-survdiff(Surv(op[which(!is.na(index)),2]/30,op[which(!is.na(index)),3])~as.factor(index[which(!is.na(index))]))  
    p.val =( 1 - pchisq(sdf$chisq, length(sdf$n) - 1) )
    #cat(p.val)
    png(type='cairo',filename=plotname,width=700,height=500)
    #cat('save file')
    sink('/dev/null')  
    #plot(fit, col=c(1:2), xlab="Time(Month)", ylab="Survival Probability",lwd=3)
    plot(fit, col=c(1:2),lwd=4,cex.axis=1.5, font.axis = 2)
    
    mtext("Time (Month)", side=1, line=2.5, col="black", cex=1.5)
    mtext("Survival Probability", side=2, line=2.5, col="black", cex=1.5)
    
    text(5, 0.05, paste("p-value =", round(p.val, digits = 10)), adj = c(0,0), font=2, cex=1.4 )
    title(main = list("Kaplan-Meier Survival Plot", cex = 2, font = 2))
    #legend(140,1, c(paste(g1,'(n = 301)'), paste(g2,'(n = 322)')), col=c(1:2), lwd=3)
    legend(140,1, c('group 1', 'group 2'),col=c(1:2), lwd=3)
    
    dev.off()
    sink()
  }
}

