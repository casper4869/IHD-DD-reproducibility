suppressPackageStartupMessages({library(data.table); library(lmtest)})
i <- fread("immutable_part4_source/IHD_1992_2021_matrix.csv")
d <- fread("immutable_part4_source/DD_1992_2021_matrix.csv")
s <- fread("immutable_part4_source/SDI_1992_2021_matrix.csv")
setkey(i, location_name); setkey(d, location_name); setkey(s, location_name)
vc <- paste0("val_", 1992:2021)
one <- function(target,cause,dsdi,p,trend_degree=0L,covid=FALSE){
 idx <- (p+1L):length(target); dat<-data.frame(y=target[idx],s=dsdi[idx])
 for(j in seq_len(p)){dat[[paste0("y",j)]]<-target[idx-j];dat[[paste0("x",j)]]<-cause[idx-j]}
 if(trend_degree>0L){tt<-seq_along(target)[idx];for(j in seq_len(trend_degree))dat[[paste0("t",j)]]<-tt^j}
 if(covid){yr<-1993:2021;dat$c2020<-as.integer(yr[idx]==2020);dat$c2021<-as.integer(yr[idx]==2021)}
 f<-try(lm(y~.,dat),silent=TRUE);if(inherits(f,"try-error")||qr(model.matrix(f))$rank<ncol(model.matrix(f)))return(c(bg=NA,df=NA))
 c(bg=tryCatch(bgtest(f,order=2,type="Chisq")$p.value,error=function(e)NA),df=df.residual(f))
}
specs<-rbindlist(lapply(1:4,function(p)data.table(p=p,trend=0L,covid=FALSE)))
specs<-rbind(specs,data.table(p=c(1L,2L),trend=c(2L,2L),covid=FALSE),data.table(p=c(1L,2L),trend=0L,covid=TRUE))
out<-list()
for(k in seq_len(nrow(specs))){sp<-specs[k];b1<-b2<-rep(NA_real_,nrow(i));dfs<-rep(NA_real_,nrow(i));for(r in seq_len(nrow(i))){I<-as.numeric(i[r,..vc]);D<-as.numeric(d[J(i$location_name[r]),..vc]);S<-as.numeric(s[J(i$location_name[r]),..vc]);a<-one(diff(log(D)),diff(log(I)),diff(S),sp$p,sp$trend,sp$covid);b<-one(diff(log(I)),diff(log(D)),diff(S),sp$p,sp$trend,sp$covid);b1[r]<-a["bg"];b2[r]<-b["bg"];dfs[r]<-a["df"]};out[[k]]<-data.table(p=sp$p,trend=sp$trend,covid=sp$covid,bg_any=sum(b1<.05|b2<.05,na.rm=TRUE),bg_dd=sum(b1<.05,na.rm=TRUE),bg_ihd=sum(b2<.05,na.rm=TRUE),median_df=median(dfs,na.rm=TRUE))}
print(rbindlist(out))
