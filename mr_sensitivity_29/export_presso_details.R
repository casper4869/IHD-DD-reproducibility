suppressPackageStartupMessages(library(data.table))
out<-normalizePath(Sys.getenv('MR_SENSITIVITY_DIR','.'),mustWork=TRUE)
stopifnot(file.exists(file.path(out,'PRESSO_COMPLETE.txt')))
dest<-file.path(out,'presso_details');dir.create(dest,showWarnings=FALSE)
for(f in list.files(file.path(out,'presso'),pattern='\\.rds$',full.names=TRUE)){
 key<-sub('\\.rds$','',basename(f));z<-readRDS(f);dat<-readRDS(file.path(out,'pairs',paste0(key,'.rds')))$dat
 t<-z$result[['MR-PRESSO results']][['Outlier Test']]
 if(!is.null(t)){
  # MR-PRESSO removes incomplete values internally. Input data have already
  # passed complete finite beta/SE validation, so row order is unchanged.
  stopifnot(nrow(t)==nrow(dat));t<-as.data.table(t);t[,SNP:=dat$SNP]
  setcolorder(t,c('SNP',setdiff(names(t),'SNP')));fwrite(t,file.path(dest,paste0(key,'_outliers.csv')))
 }
}
h<-as.data.table(readRDS(file.path(out,'cache/harmonised_all.rds')))
h[,F_exposure:=(beta.exposure/se.exposure)^2]
fwrite(h,file.path(out,'harmonised_with_F.csv'))
cat('Exported SNP-level PRESSO results and per-SNP F values\n')
