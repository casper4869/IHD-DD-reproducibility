suppressPackageStartupMessages({library(TwoSampleMR);library(data.table)})
out<-normalizePath(Sys.getenv('MR_SENSITIVITY_DIR','.'),mustWork=TRUE)
pairdir<-file.path(out,'pairs');dir.create(pairdir,showWarnings=FALSE)
stopifnot(file.exists(file.path(out,'FETCH_COMPLETE.txt')))
h<-readRDS(file.path(out,'cache/harmonised_all.rds'));d<-fread(file.path(out,'locked_candidates.csv'))
source(file.path(out,'cache_guards.R'))
lock_signature(file.path(out,'analysis_input_signature.sha256'),list(harmonised=digest::digest(file=file.path(out,'cache/harmonised_all.rds'),algo='sha256'),candidates=d,nboot=1000,seed=20260921,TwoSampleMR=as.character(packageVersion('TwoSampleMR'))))
outcomes<-c(IHD='finn-b-I9_IHD',DD='finn-b-F5_DEPRESSIO')
run<-function(f){tryCatch(f(),error=function(e)list(error=conditionMessage(e)))}
results<-list();strength<-list();flow<-list();comparisons<-list();status<-list();hets<-list();pleios<-list();loos<-list();component_status<-list()
parameters<-TwoSampleMR::default_parameters();parameters$nboot<-1000
for(i in seq_len(nrow(d)))for(dis in names(outcomes)){
 id<-d$id.exposure[i];oid<-outcomes[[dis]];key<-paste(id,dis,sep='__');f<-file.path(pairdir,paste0(key,'.rds'))
 dat<-h[h$id.exposure==id & h$id.outcome==oid,,drop=FALSE]
 valid<-dat$mr_keep %in% TRUE & is.finite(dat$beta.exposure)&is.finite(dat$beta.outcome)&is.finite(dat$se.exposure)&is.finite(dat$se.outcome)&dat$se.exposure>0&dat$se.outcome>0&dat$beta.exposure!=0
 x<-dat[valid,,drop=FALSE];n<-nrow(x);stopifnot(!anyDuplicated(x$SNP))
 flow[[key]]<-data.table(id.exposure=id,outcome=dis,harmonised_rows=nrow(dat),retained=n,excluded=nrow(dat)-n)
 if(!file.exists(f)){
  cat('Analysing',key,'SNPs',n,'\n');flush.console();set.seed(20260921+i*10+match(dis,names(outcomes)))
  methods<-if(n==1)'mr_wald_ratio' else if(n==2)'mr_ivw' else c('mr_ivw','mr_egger_regression','mr_weighted_median','mr_weighted_mode')
  if(n==0){obj<-list(status='NOT_ESTIMABLE_NO_INSTRUMENTS',dat=x)} else {
   methodrows<-lapply(methods,function(method){z<-run(function()TwoSampleMR::mr(x,method_list=method,parameters=parameters));if(is.list(z)&&!is.data.frame(z)&&!is.null(z$error))return(data.frame(method=method,error=z$error));z})
   F<-(x$beta.exposure/x$se.exposure)^2
   obj<-list(status='COMPLETED',dat=x,estimates=rbindlist(methodrows,fill=TRUE),
     heterogeneity=if(n>=3)run(function()mr_heterogeneity(x,method_list=c('mr_ivw','mr_egger_regression'))) else list(note='Fewer than 3 SNPs'),
     pleiotropy=if(n>=3)run(function()mr_pleiotropy_test(x)) else list(note='Fewer than 3 SNPs'),
     single=run(function()mr_singlesnp(x)),
     loo=if(n>=3)run(function()mr_leaveoneout(x)) else list(note='Fewer than 3 SNPs'),
     strength=data.table(nsnp=n,F_min=min(F),F_median=median(F),F_mean=mean(F),F_below10=sum(F<10),I2GX=if(n>=3)Isq(abs(x$beta.exposure),x$se.exposure) else NA_real_))
  }
  saveRDS(obj,f)
 }
 z<-readRDS(f);status[[key]]<-data.table(id.exposure=id,outcome=dis,status=z$status)
 add<-function(a){a<-as.data.table(a);a[,`:=`(id.exposure=id,outcome_code=dis)];a}
 if(is.data.frame(z$estimates)&&nrow(z$estimates)){
  e<-add(z$estimates)
  for(nm in c('b','se','pval','nsnp'))if(!nm %in% names(e))e[,(nm):=NA_real_]
  e[,method_status:=ifelse(is.finite(b)&is.finite(se)&is.finite(pval),'ESTIMATED','FAILED_OR_NOT_ESTIMABLE')]
  e[,ci_critical:=ifelse(method=='MR Egger' & nsnp>2,qt(.975,pmax(1,nsnp-2)),ifelse(method=='Weighted mode' & nsnp>1,qt(.975,pmax(1,nsnp-1)),qnorm(.975)))]
  e[,`:=`(ci_lower=b-ci_critical*se,ci_upper=b+ci_critical*se,OR=exp(b),OR_lower=exp(b-ci_critical*se),OR_upper=exp(b+ci_critical*se))]
  e[,OR_overflow:=is.infinite(OR)|is.infinite(OR_lower)|is.infinite(OR_upper)];results[[key]]<-e
  v<-e[method=='Inverse variance weighted']
  if(nrow(v)){ob<-d[[paste0(dis,'.b')]][i];comparisons[[key]]<-data.table(id.exposure=id,trait=d$trait[i],outcome=dis,old_nsnp=d[[paste0(dis,'.nsnp')]][i],new_nsnp=v$nsnp[1],old_b=ob,new_b=v$b[1],old_se=d[[paste0(dis,'.se')]][i],new_se=v$se[1],old_p=d[[paste0(dis,'.p')]][i],new_p=v$pval[1],delta_b=v$b[1]-ob,same_direction=sign(v$b[1])==sign(ob))}
 }
 if(is.data.frame(z$strength))strength[[key]]<-add(z$strength)
 if(is.data.frame(z$heterogeneity))hets[[key]]<-add(z$heterogeneity)
 if(is.data.frame(z$pleiotropy))pleios[[key]]<-add(z$pleiotropy)
 if(is.data.frame(z$loo)){
  l<-add(z$loo);fwrite(l,file.path(pairdir,paste0(key,'_leave_one_out.csv')))
  ll<-l[SNP!='All'&is.finite(b)&is.finite(se)];iv<-l[SNP=='All'&is.finite(b)];if(nrow(ll)&&nrow(iv))loos[[key]]<-data.table(id.exposure=id,outcome=dis,n_valid=nrow(ll),n_missing=sum(l$SNP!='All')-nrow(ll),min_b=min(ll$b),max_b=max(ll$b),sign_change=any(sign(ll$b)!=sign(iv$b[1])),max_abs_shift=max(abs(ll$b-iv$b[1])),any_ci_crosses_zero=any(ll$b-1.96*ll$se<=0 & ll$b+1.96*ll$se>=0))
 }
 if(is.data.frame(z$single))fwrite(as.data.table(z$single),file.path(pairdir,paste0(key,'_single_snp.csv')))
 for(comp in c('estimates','heterogeneity','pleiotropy','single','loo','strength')){
  value<-z[[comp]];okay<-is.data.frame(value)&&nrow(value)>0
  component_status[[paste(key,comp)]]<-data.table(id.exposure=id,outcome=dis,component=comp,status=if(okay)'RETURNED_CHECK_NUMERIC_FIELDS' else 'FAILED_OR_NOT_ESTIMABLE',detail=if(!okay)paste(unlist(value),collapse='; ') else '')
 }
}
tables<-list(estimates=results,instrument_strength=strength,harmonisation_flow=flow,archived_vs_current_IVW=comparisons,pair_status=status,heterogeneity=hets,egger_intercept=pleios,leave_one_out_summary=loos,component_status=component_status)
for(nm in names(tables)){
 t<-rbindlist(tables[[nm]],fill=TRUE)
 if(nm=='estimates'&&nrow(t))t[,q_sensitivity_58:=p.adjust(pval,method='BH',n=58),by=method]
 if(nm=='heterogeneity'&&nrow(t))t[,q_sensitivity_58:=p.adjust(Q_pval,method='BH',n=58),by=method]
 if(nm=='egger_intercept'&&nrow(t))t[,q_sensitivity_58:=p.adjust(pval,method='BH',n=58)]
 fwrite(t,file.path(out,paste0(nm,'.csv')))
}
writeLines(capture.output(sessionInfo()),file.path(out,'sessionInfo_analysis.txt'))
writeLines('QUEUE_TRAVERSED: inspect method_status and component_status for failures',file.path(out,'CORE_COMPLETE.txt'));cat('Core 58-pair queue traversed; inspect status files\n')
