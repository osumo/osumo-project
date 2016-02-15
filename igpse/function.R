

for (i in 1:nrow(df)){
  source <- df$source[i]
  target <- df$target[i]
  df$outOffset[i] <- sum(df$count[df$source == source & df$count>df$count[i]])
  df$inOffset[i] <- sum(df$count[df$target == target & df$count>df$count[i]])
}

lapply(mRNA.key, function(x){
      idx<- df$source == as.numeric(x)
      return(df[idx,])
})




sum(df$count)


