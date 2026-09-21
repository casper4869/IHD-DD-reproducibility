suppressPackageStartupMessages({library(TwoSampleMR);library(data.table)})
out<-normalizePath(Sys.getenv('MR_SENSITIVITY_DIR','.'),mustWork=TRUE)
stopifnot(file.exists(file.path(out,'vcf_extraction_audit.json')))
meta <- readRDS(file.path(out,'cache/gwas_metadata.rds'))
ids <- c('finn-b-I9_IHD','finn-b-F5_DEPRESSIO')
oy <- rbindlist(lapply(ids,function(id){
 d <- fread(file.path(out,paste0(id,'_selected.csv')),na.strings=c('.','NA',''))
 m <- meta[meta$id==id,,drop=FALSE]; stopifnot(nrow(m)==1)
 stopifnot(!anyDuplicated(d$rsid), all(is.finite(d$beta)),all(is.finite(d$se)),all(d$se>0),all(d$LP>=0),all(d$eaf>=0 & d$eaf<=1))
 d[,p:=10^(-LP)];d[,trait:=m$trait]
 # Variant-specific SS is absent in these VCFs: leave n unknown, do not invent it.
 d[,n:=as.numeric(n)]
 TwoSampleMR:::format_d(as.data.frame(d))
}),fill=TRUE)
stopifnot(!anyDuplicated(oy[,paste(SNP,id.outcome)]))
saveRDS(as.data.frame(oy),file.path(out,'cache/outcomes_all.rds'));fwrite(oy,file.path(out,'outcomes_all.csv'))
ex <- readRDS(file.path(out,'cache/instruments_all.rds'))
h <- TwoSampleMR::harmonise_data(ex,as.data.frame(oy),action=2)
stopifnot(length(unique(h$id.exposure))==29,length(unique(h$id.outcome))==2)
saveRDS(h,file.path(out,'cache/harmonised_all.rds'));fwrite(h,file.path(out,'harmonised_all.csv'))
writeLines(capture.output(sessionInfo()),file.path(out,'sessionInfo_harmonisation.txt'))
writeLines(c('COMPLETE','Exposure instruments: official API; outcomes: exact-ID official VCFs; no proxies; harmonise action=2.'),file.path(out,'FETCH_COMPLETE.txt'))
cat('Local harmonisation complete:',nrow(h),'rows;',sum(h$mr_keep),'retained across 58 pairs\n')
