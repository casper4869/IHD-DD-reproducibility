suppressPackageStartupMessages({library(data.table);library(MRPRESSO)})
out<-normalizePath(Sys.getenv('MR_SENSITIVITY_DIR','.'),mustWork=TRUE)
stopifnot(file.exists(file.path(out,'CORE_COMPLETE.txt')))
stopifnot(file.exists(file.path(out,'PRESSO_IMPLEMENTATION_VALIDATION.txt')))
source(file.path(out,'presso_exact_fast.R'));presso_impl<-make_presso_exact_fast()
stopifnot(file.exists(file.path(out,'PRESSO_DISTORTION_CANDIDATE_VALIDATION.txt')),file.exists(file.path(out,'PRESSO_REAL_DATA_DISTORTION_VALIDATION.txt')))
source(file.path(out,'presso_distortion_fast_candidate.R'));presso_impl<-make_presso_distortion_fast(presso_impl)
source(file.path(out,'cache_guards.R'))
lock_signature(file.path(out,'presso_input_signature.sha256'),list(harmonised=digest::digest(file=file.path(out,'cache/harmonised_all.rds'),algo='sha256'),draws='max(10000,100*n)',seed=20260921,implementation=digest::digest(file=file.path(out,'presso_exact_fast.R'),algo='sha256')))
lock_signature(file.path(out,'presso_distortion_signature.sha256'),list(implementation=digest::digest(file=file.path(out,'presso_distortion_fast_candidate.R'),algo='sha256'),compatibility='Validated outputs and identical RNG; existing v1 completed caches retained'))
dest<-file.path(out,'presso');dir.create(dest,showWarnings=FALSE)
files<-list.files(file.path(out,'pairs'),pattern='\\.rds$',full.names=TRUE)
worker<-as.integer(Sys.getenv('PRESSO_WORKER','1'));workers<-as.integer(Sys.getenv('PRESSO_WORKERS','1'))
include<-Sys.getenv('PRESSO_PAIR_INDICES','');selected<-if(nzchar(include))as.integer(strsplit(include,',',fixed=TRUE)[[1]]) else seq_along(files)[(seq_along(files)-1)%%workers==worker-1]
for(i in seq_along(files)){
 if(!i %in% selected)next
 key<-sub('\\.rds$','',basename(files[i]));f<-file.path(dest,paste0(key,'.rds'));if(file.exists(f))next
 x<-readRDS(files[i])$dat;n<-nrow(x);B<-max(10000,100*n)
 cat('PRESSO',i,'/',length(files),key,'SNPs',n,'draws',B,'\n');flush.console()
 if(n<4){z<-list(status='NOT_ESTIMABLE',reason='Fewer than 4 SNPs')} else {
  z<-tryCatch(list(status='COMPLETED',implementation='Validated single-exposure algebraic optimisation v2 of MRPRESSO 1.0; distortion pool/statistic cache; identical sampling order',nsnp=n,NbDistribution=B,seed=20260921+i,result=presso_impl(BetaOutcome='beta.outcome',BetaExposure='beta.exposure',SdOutcome='se.outcome',SdExposure='se.exposure',data=x,OUTLIERtest=TRUE,DISTORTIONtest=TRUE,NbDistribution=B,SignifThreshold=.05,seed=20260921+i)),error=function(e)list(status='FAILED',reason=conditionMessage(e),nsnp=n,NbDistribution=B))
 }
 saveRDS(z,f);writeLines(capture.output(str(z,max.level=4)),file.path(dest,paste0(key,'.txt')));gc()
}
finished<-list.files(dest,pattern='\\.rds$',full.names=TRUE)
if(length(finished)==length(files)){
summaries<-lapply(finished,function(f){z<-readRDS(f);data.table(pair=sub('\\.rds$','',basename(f)),status=z$status,nsnp=if(is.null(z$nsnp))NA_integer_ else z$nsnp,detail=if(is.null(z$reason))'' else z$reason)})
fwrite(rbindlist(summaries,fill=TRUE),file.path(out,'presso_status.csv'))
writeLines('QUEUE_TRAVERSED: inspect presso_status.csv for failed/not-estimable pairs',file.path(out,'PRESSO_COMPLETE.txt'))
}
