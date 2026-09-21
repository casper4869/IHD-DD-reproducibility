suppressPackageStartupMessages(library(data.table))
out<-normalizePath(Sys.getenv('MR_SENSITIVITY_DIR','.'),mustWork=TRUE)
stopifnot(file.exists(file.path(out,'CORE_COMPLETE.txt')))
e<-fread(file.path(out,'estimates.csv'));d<-fread(file.path(out,'locked_candidates.csv'))
meta<-d[,.(id.exposure,trait,short_label,trait_group)]
e<-merge(e,meta,by='id.exposure',all.x=TRUE,sort=FALSE)
fwrite(e,file.path(out,'all_method_estimates_with_traits.csv'))
summary<-dcast(e,id.exposure+outcome_code~method,value.var=c('b','se','pval','ci_lower','ci_upper','method_status'))
summary<-merge(summary,meta,by='id.exposure',all.x=TRUE,sort=FALSE)
for(file in c('instrument_strength','egger_intercept')){
 z<-fread(file.path(out,paste0(file,'.csv')))
 keep<-setdiff(names(z),c('exposure','outcome','id.outcome'))
 summary<-merge(summary,z[,..keep],by=c('id.exposure','outcome_code'),all.x=TRUE,sort=FALSE)
}
q<-fread(file.path(out,'heterogeneity.csv'))[method=='Inverse variance weighted',.(id.exposure,outcome_code,Q,Q_df,Q_pval,Q_q_sensitivity_58=q_sensitivity_58)]
summary<-merge(summary,q,by=c('id.exposure','outcome_code'),all.x=TRUE)
for(m in c('Weighted median','MR Egger','Weighted mode'))summary[,(paste0(m,'_direction_matches_current_IVW')):=sign(get(paste0('b_',m)))==sign(get('b_Inverse variance weighted'))]
summary[,Steiger_status:='Not estimated: validated population prevalence and binary-effect-scale metadata not established; continuous-trait fallback deliberately disabled']
if(file.exists(file.path(out,'PRESSO_COMPLETE.txt'))){
 ps<-lapply(list.files(file.path(out,'presso'),pattern='\\.rds$',full.names=TRUE),function(f){
  key<-strsplit(sub('\\.rds$','',basename(f)),'__',fixed=TRUE)[[1]];z<-readRDS(f)
  p<-z$result[['MR-PRESSO results']];rawp<-if(is.null(p[['Global Test']]$Pvalue))NA_character_ else as.character(p[['Global Test']]$Pvalue)
  row<-data.table(id.exposure=key[1],outcome_code=key[2],PRESSO_status=z$status,PRESSO_global_P=rawp,PRESSO_global_P_upper_bound=as.numeric(sub('^<','',rawp)),PRESSO_draws=if(is.null(z$NbDistribution))NA_real_ else z$NbDistribution)
  ol<-p[['Outlier Test']]
  row[,PRESSO_outlier_n:=if(z$status!='COMPLETED')NA_integer_ else if(is.null(ol))0L else sum(as.numeric(sub('^<','',ol$Pvalue))<=.05,na.rm=TRUE)]
  row[,PRESSO_outlier_test_status:=if(z$status!='COMPLETED')'Not available' else if(is.null(ol))'Not triggered by global test' else 'Performed']
  dt<-p[['Distortion Test']]
  row[,PRESSO_distortion_P:=if(is.null(dt$Pvalue))NA_character_ else as.character(dt$Pvalue)]
  row[,PRESSO_distortion_coefficient:=if(is.null(dt[['Distortion Coefficient']]))NA_real_ else as.numeric(dt[['Distortion Coefficient']])]
  row[,PRESSO_distortion_status:=if(z$status!='COMPLETED')'Not available' else if(is.null(dt))'Not triggered' else if(is.na(dt$Pvalue))paste(dt[['Outliers Indices']],collapse=';') else 'Estimated']
  main<-z$result[['Main MR results']]
  if(!is.null(main)){
   adj<-main[main[['MR Analysis']]=='Outlier-corrected',,drop=FALSE]
   if(nrow(adj)){
    row[,`:=`(PRESSO_corrected_b=adj[['Causal Estimate']][1],PRESSO_corrected_se=adj[['Sd']][1],PRESSO_corrected_P=adj[['P-value']][1])]
    row[,PRESSO_corrected_nsnp:=if(is.finite(PRESSO_corrected_b))z$nsnp-PRESSO_outlier_n else NA_integer_]
    row[,PRESSO_corrected_lower:=PRESSO_corrected_b-qt(.975,PRESSO_corrected_nsnp-1)*PRESSO_corrected_se]
    row[,PRESSO_corrected_upper:=PRESSO_corrected_b+qt(.975,PRESSO_corrected_nsnp-1)*PRESSO_corrected_se]
    row[,`:=`(PRESSO_corrected_OR=exp(PRESSO_corrected_b),PRESSO_corrected_OR_lower=exp(PRESSO_corrected_lower),PRESSO_corrected_OR_upper=exp(PRESSO_corrected_upper))]
   }
  }
  row
 })
 ps<-rbindlist(ps,fill=TRUE);ps[,PRESSO_global_q_sensitivity_58_upper_bound:=p.adjust(PRESSO_global_P_upper_bound,'BH',n=58)]
 fwrite(ps,file.path(out,'presso_summary.csv'));summary<-merge(summary,ps,by=c('id.exposure','outcome_code'),all.x=TRUE)
}
fwrite(summary,file.path(out,'sensitivity_summary_58.csv'))
counts<-e[,.(n_pairs=.N,n_finite=sum(is.finite(b)&is.finite(se)&is.finite(pval)),nominal_P_below_05=sum(pval<.05,na.rm=TRUE)),by=.(outcome_code,method)]
fwrite(counts,file.path(out,'method_coverage_counts.csv'));print(counts)
