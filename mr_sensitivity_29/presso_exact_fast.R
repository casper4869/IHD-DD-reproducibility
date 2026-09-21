# Single-exposure computational optimisation of MRPRESSO::mr_presso 1.0.
# Only two internal helpers are replaced. All tests, thresholds, RNG draw order,
# outlier correction and distortion calculations retain the installed source.
# Weighted no-intercept leave-one-out slopes use the exact sufficient-statistic
# identity (Sxy-w*x*y)/(Sxx-w*x*x), avoiding repeated identical regressions.
make_presso_exact_fast<-function(){
 f<-MRPRESSO::mr_presso;code<-as.list(body(f))
 original_rss<-NULL
 for(e in code)if(is.call(e)&&identical(e[[1]],as.name('<-'))&&identical(as.character(e[[2]]),'getRSS_LOO'))original_rss<-e[[3]]
 code<-append(code,list(substitute(original_getRSS_LOO<-ORIGINAL,list(ORIGINAL=original_rss))),after=1)
 replacement_rss<-quote(function(BetaOutcome,BetaExposure,data,returnIV){
  stopifnot(length(BetaExposure)==1L)
  x<-data[,BetaExposure];y<-data[,BetaOutcome];w<-data[,'Weights']
  xx<-w*x*x;xy<-w*x*y;den<-sum(xx)-xx
  if(any(!is.finite(den)|den<=1e-10*sum(xx)))return(original_getRSS_LOO(BetaOutcome,BetaExposure,data,returnIV))
  slope<-(sum(xy)-xy)/den
  rss<-sum(w*(y-slope*x)^2,na.rm=TRUE)
  if(returnIV)list(rss,slope) else rss
 })
 replacement_random<-quote(local({
  mu<-NULL
  function(BetaOutcome,BetaExposure,SdOutcome,SdExposure,data){
   stopifnot(length(BetaExposure)==1L)
   if(is.null(mu)){
    # Use the original weighted lm predictions once, preserving reference
    # floating-point predictions and caching only invariant work.
    models<-lapply(seq_len(nrow(data)),function(i)lm(as.formula(paste0(BetaOutcome,' ~ -1 + ',BetaExposure)),weights=Weights,data=data[-i,]))
    mu<<-vapply(seq_len(nrow(data)),function(i)as.numeric(predict(models[[i]],newdata=data[i,,drop=FALSE])),numeric(1))
   }
   z<-cbind(rnorm(nrow(data),data[,BetaExposure],data[,SdExposure]),rnorm(nrow(data),mu,data[,SdOutcome]),data$Weights)
   colnames(z)<-c(BetaExposure,BetaOutcome,'Weights');z
  }
 }))
 for(i in seq_along(code))if(is.call(code[[i]])&&identical(code[[i]][[1]],as.name('<-'))){
  nm<-as.character(code[[i]][[2]])
  if(identical(nm,'getRSS_LOO'))code[[i]][[3]]<-replacement_rss
  if(identical(nm,'getRandomData'))code[[i]][[3]]<-replacement_random
 }
 body(f)<-as.call(code);f
}
