if(Sys.getenv('RUN_OPENGWAS_SENSITIVITY')!='YES')stop('Online retrieval disabled. Read README and provider terms before opting in.')
# Authorised targeted follow-up: exactly 29 fixed Figure 7 exposures, two outcomes.
# Official API only. Sequential, cached, minimum 95 s between HTTP requests.
# No retries, no crawling, no credential output or credential-containing objects saved.
suppressPackageStartupMessages({library(TwoSampleMR);library(ieugwasr);library(data.table);library(httr)})
out<-normalizePath(Sys.getenv('MR_SENSITIVITY_DIR','.'),mustWork=TRUE)
cache<-file.path(out,'cache');dir.create(cache,recursive=TRUE,showWarnings=FALSE)
d<-fread(file.path(out,'locked_candidates.csv'))
stopifnot(nrow(d)==29,uniqueN(d$id.exposure)==29)
source(file.path(out,'cache_guards.R'))
lock_signature(file.path(out,'fetch_input_signature.sha256'),list(candidate=d,p1=5e-6,r2=.001,kb=10000,proxies=FALSE,action=2,batch_size=3,outcomes=c('finn-b-I9_IHD','finn-b-F5_DEPRESSIO')))
fwrite(d,file.path(out,'locked_candidates.csv'))
ids<-d$id.exposure;outcomes<-c('finn-b-I9_IHD','finn-b-F5_DEPRESSIO')
jwt<-ieugwasr::get_opengwas_jwt();stopifnot(nzchar(jwt))
clock<-file.path(out,'last_request.txt');logfile<-file.path(out,'requests.csv')

rate_block<-file.path(out,'provider_retry_after.txt')
check_persistent_limit<-function(){
 if(file.exists(rate_block)){
  until<-suppressWarnings(as.numeric(readLines(rate_block,warn=FALSE)[1]))
  if(!is.finite(until))stop('Previous HTTP 429 has no valid Retry-After deadline. Consult the provider before manually clearing provider_retry_after.txt.')
  if(as.numeric(Sys.time())<until)stop('Provider Retry-After deadline has not elapsed; no request sent.')
 }
}
record_rate_limit<-function(response){
 header<-httr::headers(response)[['retry-after']]
 seconds<-suppressWarnings(as.numeric(header))
 until<-if(length(seconds)==1 && is.finite(seconds))as.numeric(Sys.time())+max(0,seconds) else Inf
 if(!is.finite(until) && length(header)==1){
  parsed<-suppressWarnings(as.POSIXct(header,format='%a, %d %b %Y %H:%M:%S',tz='GMT'))
  if(!is.na(parsed))until<-as.numeric(parsed)
 }
 writeLines(as.character(until),rate_block)
 stop('HTTP 429: stopped without retry; Retry-After block persisted across restarts.')
}

paced_api<-function(path,query=NULL,opengwas_jwt=jwt,method='GET',silent=TRUE,encode='json',timeout=300,override_429=FALSE,x_api_source='targeted-MR-revision'){
 stopifnot(!override_429,method=='GET',path %in% c('gwasinfo','gwasinfo/files','tophits','associations','ld/clump'))
 check_persistent_limit()
 last<-if(file.exists(clock))as.numeric(readLines(clock,warn=FALSE)[1]) else 0
 wait<-max(0,95-(as.numeric(Sys.time())-last))
 if(wait>0){cat('Pacing',path,round(wait),'seconds\n');flush.console();Sys.sleep(wait)}
 ieugwasr:::check_reset(override_429=FALSE)
 writeLines(as.character(as.numeric(Sys.time())),clock)
 h<-httr::add_headers(Authorization=paste('Bearer',opengwas_jwt),'X-Api-Source'=x_api_source)
 r<-if(is.null(query))httr::GET(paste0('https://api.opengwas.io/api/',path),h,httr::timeout(timeout)) else httr::POST(paste0('https://api.opengwas.io/api/',path),body=query,h,encode=encode,httr::timeout(timeout))
 hh<-httr::headers(r);status<-httr::status_code(r)
 row<-data.table(time_utc=format(Sys.time(),tz='UTC',usetz=TRUE),endpoint=path,status=status,allowance=as.character(hh[['x-allowance-remaining']] %||% ''),retry_after=as.character(hh[['retry-after']] %||% ''))
 fwrite(row,logfile,append=file.exists(logfile),col.names=!file.exists(logfile))
 cat('HTTP',status,path,'\n');flush.console()
 if(status==429)record_rate_limit(r)
 if(status!=200)stop(paste('HTTP',status,'stopped without retry; inspect provider status before resuming'))
 r
}
`%||%`<-function(a,b)if(is.null(a))b else a
assignInNamespace('api_query',paced_api,ns='ieugwasr')
meta<-file.path(cache,'gwas_metadata.rds')
if(!file.exists(meta)){m<-ieugwasr::gwasinfo(c(ids,outcomes),opengwas_jwt=jwt);saveRDS(m,meta);fwrite(as.data.table(m),file.path(out,'gwas_metadata.csv'))}
if(!file.exists(file.path(cache,'instruments_all.rds'))){
groups<-split(ids,ceiling(seq_along(ids)/3))
for(k in seq_along(groups)){
 f<-file.path(cache,sprintf('instruments_batch_%02d.rds',k))
 if(!file.exists(f)){
  cat('Instrument batch',k,'of',length(groups),'\n');flush.console()
  z<-TwoSampleMR::extract_instruments(groups[[k]],p1=5e-6,clump=TRUE,r2=.001,kb=10000,opengwas_jwt=jwt)
  saveRDS(z,f)
 }
}
ex<-rbindlist(lapply(seq_along(groups),function(k)readRDS(file.path(cache,sprintf('instruments_batch_%02d.rds',k)))),fill=TRUE)
stopifnot(all(ex$id.exposure %in% ids));saveRDS(as.data.frame(ex),file.path(cache,'instruments_all.rds'));fwrite(ex,file.path(out,'instruments_all.csv'))
}
ex<-readRDS(file.path(cache,'instruments_all.rds'))

# Only two official outcome VCFs, never thousands of small association queries.
priv<-file.path(out,'PRIVATE_NOT_FOR_ARCHIVE');dir.create(priv,showWarnings=FALSE)
vcfdir<-file.path(priv,'official_vcf');dir.create(vcfdir,showWarnings=FALSE)
needed<-if(file.exists(file.path(cache,'outcomes_all.rds')))character() else outcomes[!file.exists(file.path(vcfdir,paste0(outcomes,'.vcf.gz')))]
if(length(needed)){
 access<-ieugwasr::gwasinfo_files(needed,opengwas_jwt=jwt)
 for(id in needed){
  urls<-unlist(access[[id]],use.names=FALSE)
  link<-urls[grepl('\\.vcf\\.gz([?]|$)',urls) & !grepl('\\.tbi',urls)]
 stopifnot(length(link)==1)
  check_persistent_limit()
  last<-if(file.exists(clock))as.numeric(readLines(clock)[1]) else 0
  Sys.sleep(max(0,95-(as.numeric(Sys.time())-last)))
  writeLines(as.character(as.numeric(Sys.time())),clock)
  f<-file.path(vcfdir,paste0(id,'.vcf.gz'));tmp<-paste0(f,'.partial')
  r<-tryCatch(httr::GET(link,httr::write_disk(tmp,overwrite=TRUE),httr::timeout(1800)),error=function(e)stop('Official file download failed; no automatic retry'))
  status<-httr::status_code(r)
  if(status==429)record_rate_limit(r)
  if(status!=200)stop(paste('Official file HTTP',status,'; stopped without retry'))
  stopifnot(file.info(tmp)$size>0);file.rename(tmp,f)
 }
 rm(access,urls,link,r)
}
cat('Cached acquisition complete. Existing harmonised cache supports direct offline analysis; newly downloaded VCFs require extract_local_vcf.py then harmonise_local_vcf.R.\n')
