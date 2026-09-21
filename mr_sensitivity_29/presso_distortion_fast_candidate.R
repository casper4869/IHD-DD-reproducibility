# Exact computational candidate: keep sampling calls and their order unchanged.
make_presso_distortion_fast<-function(f){
 replacement<-quote(local({
  pool<-NULL;xx<-NULL;xy<-NULL
  function(BetaOutcome,BetaExposure,SdOutcome,SdExposure,data,refOutlier){
   stopifnot(length(BetaExposure)==1L)
   if(is.null(pool)){
    pool<<-setdiff(1:nrow(data),refOutlier)
    xx<<-data$Weights*data[,BetaExposure]^2
    xy<<-data$Weights*data[,BetaExposure]*data[,BetaOutcome]
   }
   indices<-c(refOutlier,replicate(nrow(data)-length(refOutlier),sample(pool)[1]))
   take<-indices[1:(length(indices)-length(refOutlier))]
   den<-sum(xx[take]);coef<-sum(xy[take])/den
   if(!is.finite(coef)||den<=1e-10*sum(xx)){
    mod<-lm(as.formula(paste0(BetaOutcome,' ~ -1 + ',BetaExposure)),weights=Weights,data=data[take,])
    return(mod$coefficients[BetaExposure])
   }
   setNames(coef,BetaExposure)
  }
 }))
 replace<-function(x){
  if(is.call(x)&&identical(x[[1]],as.name('<-'))&&identical(x[[2]],as.name('getRandomBias'))){x[[3]]<-replacement;return(x)}
  if(is.call(x)){for(i in seq_along(x))if(i>1 && (is.call(x[[i]])||is.expression(x[[i]])))x[[i]]<-replace(x[[i]])}
  x
 }
 body(f)<-replace(body(f));f
}
