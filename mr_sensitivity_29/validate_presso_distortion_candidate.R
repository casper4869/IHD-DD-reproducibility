suppressPackageStartupMessages(library(MRPRESSO))
out<-normalizePath(Sys.getenv('MR_SENSITIVITY_DIR','.'),mustWork=TRUE)
source(file.path(out,'presso_exact_fast.R'));source(file.path(out,'presso_distortion_fast_candidate.R'));fast<-make_presso_distortion_fast(make_presso_exact_fast())
logs<-character()
for(k in 1:5){
 set.seed(712+k);n<-c(8,8,4,5,20)[k]
 d<-data.frame(bx=runif(n,.10,.35),sx=runif(n,.015,.025),sy=runif(n,.02,.04))
 if(k>=3)d$bx[seq(1,n,2)]<--d$bx[seq(1,n,2)]
 d$by<-.3*d$bx+rnorm(n,0,.01);if(k==2)d$by[1]<-d$by[1]+.4
 if(k==5)d$by[1:2]<-d$by[1:2]+c(.4,-.5)
 args<-list(BetaOutcome='by',BetaExposure='bx',SdOutcome='sy',SdExposure='sx',data=d,OUTLIERtest=TRUE,DISTORTIONtest=TRUE,NbDistribution=if(k<=2)1000 else 500,seed=45678)
 t0<-proc.time()[3];a<-suppressWarnings(do.call(MRPRESSO::mr_presso,args));state_a<-.Random.seed;t1<-proc.time()[3]
 z<-suppressWarnings(do.call(fast,args));state_z<-.Random.seed;t2<-proc.time()[3]
 comparison<-all.equal(a,z,tolerance=1e-10)
 stopifnot(isTRUE(comparison),identical(state_a,state_z));logs<-c(logs,paste('fixture',k,'n',n,'PASS all output components tolerance 1e-10 AND identical RNG state; official_seconds',round(t1-t0,3),'fast_seconds',round(t2-t1,3)))
}
writeLines(logs,file.path(out,'PRESSO_DISTORTION_CANDIDATE_VALIDATION.txt'));cat(paste(logs,collapse='\n'),'\n')
