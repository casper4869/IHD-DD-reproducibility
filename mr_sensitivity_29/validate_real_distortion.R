out<-normalizePath(Sys.getenv('MR_SENSITIVITY_DIR','.'),mustWork=TRUE)
source(file.path(out,'presso_exact_fast.R'));source(file.path(out,'presso_distortion_fast_candidate.R'))
f1<-make_presso_exact_fast();f2<-make_presso_distortion_fast(f1)
x<-readRDS(file.path(out,'pairs/ieu-a-1239__IHD.rds'))$dat
getfn<-function(x){if(is.call(x)&&identical(x[[1]],as.name('<-'))&&identical(x[[2]],as.name('getRandomBias')))return(x[[3]]);if(is.call(x))for(i in seq_along(x)){if(i>1){z<-getfn(x[[i]]);if(!is.null(z))return(z)}};NULL}
g1<-eval(getfn(body(f1)));g2<-eval(getfn(body(f2)))
x$Weights<-1/x$se.outcome^2
args<-list(BetaOutcome='beta.outcome',BetaExposure='beta.exposure',data=x,refOutlier=c(1,10,20))
set.seed(777);t<-proc.time()[3];a<-replicate(200,do.call(g1,args));s1<-.Random.seed;ta<-proc.time()[3]-t
set.seed(777);t<-proc.time()[3];b<-replicate(200,do.call(g2,args));s2<-.Random.seed;tb<-proc.time()[3]-t
stopifnot(isTRUE(all.equal(a,b,tolerance=1e-10)),identical(s1,s2))
writeLines(paste('Real 508-SNP data; 200 distortion draws; coefficients agree tolerance1e-10; RNG identical; seconds reference',ta,'candidate',tb),file.path(out,'PRESSO_REAL_DATA_DISTORTION_VALIDATION.txt'))
