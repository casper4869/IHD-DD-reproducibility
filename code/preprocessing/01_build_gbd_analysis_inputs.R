#!/usr/bin/env Rscript

# Minimal raw-to-analysis preprocessing for the IHD/DD GBD inputs.
# It writes to a new output directory and never alters source or historical files.
suppressPackageStartupMessages({library(data.table); library(digest)})

source_dir <- Sys.getenv("GBD_SOURCE_DIR", "")
country_file <- Sys.getenv("GBD_LOCATION_CROSSWALK", "derived_data/figure2/derived_inputs/GBD_country_location_crosswalk.csv")
sdi_file <- Sys.getenv("GBD_SDI_204_FILE", "")
output_dir <- Sys.getenv("GBD_PREPROCESS_OUTPUT", "derived_data/preprocessing_generated")
if (!nzchar(source_dir) || !nzchar(sdi_file)) stop("Set GBD_SOURCE_DIR and GBD_SDI_204_FILE; see README.md")
dir.create(output_dir, recursive=TRUE, showWarnings=FALSE)

years <- 1992:2021
ages <- c("<5 years","5-9 years","10-14 years","15-19 years","20-24 years",
          "25-29 years","30-34 years","35-39 years","40-44 years","45-49 years",
          "50-54 years","55-59 years","60-64 years","65-69 years","70-74 years",
          "75-79 years","80-84 years","85-89 years","90-94 years","95+ years")
sexes <- c("Male","Female","Both")
raw_files <- c(IHD=file.path(source_dir,"IHD_country.csv"), DD=file.path(source_dir,"DD_country.csv"))
inputs <- c(raw_files, location_crosswalk=country_file, sdi_204=sdi_file)
stopifnot(all(file.exists(inputs)))

inventory <- data.table(
  input=names(inputs), path=normalizePath(inputs,winslash="/",mustWork=TRUE),
  bytes=file.info(inputs)$size,
  sha256=vapply(inputs, digest::digest, character(1), file=TRUE, algo="sha256", serialize=FALSE)
)
fwrite(inventory,file.path(output_dir,"input_inventory_sha256.csv"))

target <- fread(country_file)
stopifnot(all(c("location_id","location_name") %in% names(target)),
          nrow(target)==204L,uniqueN(target$location_id)==204L,uniqueN(target$location_name)==204L)

read_one <- function(path,disease){
  message("Reading ",disease," raw GBD file")
  x <- fread(path,select=c("measure_id","measure_name","location_id","location_name",
                          "sex_id","sex_name","age_id","age_name","metric_id","metric_name",
                          "year","val"),showProgress=TRUE)
  x <- x[measure_name=="Incidence" & metric_name=="Rate" & year %in% years & location_id %in% target$location_id]
  x[,location_name:=NULL]
  x <- merge(x,target,by="location_id",all.x=TRUE,sort=FALSE)
  stopifnot(uniqueN(x$location_id)==204L,!anyNA(x$location_name))
  x[,disease:=disease]
  x
}

all <- rbindlist(Map(read_one,raw_files,names(raw_files)),use.names=TRUE)
fwrite(target[order(location_id)],file.path(output_dir,"location_crosswalk_204.csv"))

# Age-standardised country series used by Figures 1/3, temporal analyses, forecasts and GWR.
asir <- all[age_name=="Age-standardized" & sex_name %in% sexes,
            .(disease,location_id,location_name,sex_id,sex_name,year,val)]
stopifnot(nrow(asir)==2L*204L*3L*30L,
          !anyDuplicated(asir[,.(disease,location_id,sex_id,year)]),
          !anyNA(asir$val))
setorder(asir,disease,sex_id,location_id,year)
fwrite(asir,file.path(output_dir,"country_ASIR_1992_2021_long.csv"))

for(dis in c("IHD","DD")){
  z <- asir[disease==dis & sex_name=="Both",.(location_name,year,val)]
  wide <- dcast(z,location_name~year,value.var="val")
  setnames(wide,as.character(years),paste0("val_",years))
  fwrite(wide,file.path(output_dir,paste0(dis,"_1992_2021_matrix_full_precision.csv")))
  rounded <- copy(wide); cols <- setdiff(names(rounded),"location_name")
  rounded[,(cols):=lapply(.SD,round,2),.SDcols=cols]
  fwrite(rounded,file.path(output_dir,paste0(dis,"_1992_2021_matrix_2dp.csv")))
}

# Sex- and age-specific series used by Figure 2 and Supplementary Table S1.
age_specific <- all[sex_name %in% c("Male","Female") & age_name %in% ages,
                    .(disease,location_id,location_name,sex_id,sex_name,age_id,age_name,year,val)]
stopifnot(nrow(age_specific)==2L*204L*2L*20L*30L,
          !anyDuplicated(age_specific[,.(disease,location_id,sex_id,age_id,year)]),
          !anyNA(age_specific$val))
setorder(age_specific,sex_id,location_id,age_id,year,disease)
paired <- dcast(age_specific,location_id+location_name+sex_id+sex_name+age_id+age_name+year~disease,value.var="val")
stopifnot(!anyNA(paired$IHD),!anyNA(paired$DD))
fwrite(paired,file.path(output_dir,"IHD_DD_age_sex_1992_2021_long.csv"))

# Normalise the already curated 204-location SDI input without reproducing the historical row-number deletion.
sdi <- fread(sdi_file)
stopifnot(nrow(sdi)==204L,uniqueN(sdi$location_name)==204L,setequal(sdi$location_name,target$location_name))
sdi_cols <- grep("^(X)?(199[2-9]|20[0-1][0-9]|202[0-1])$",names(sdi),value=TRUE)
stopifnot(length(sdi_cols)==30L)
setnames(sdi,sdi_cols,paste0("val_",years))
fwrite(sdi[,c("location_name",paste0("val_",years)),with=FALSE],file.path(output_dir,"SDI_1992_2021_matrix.csv"))

flow <- data.table(
  stage=c("Target locations","ASIR long rows","Age-specific paired rows","SDI locations"),
  n=c(204L,nrow(asir),nrow(paired),nrow(sdi)),
  rule=c("Country.csv fixed study cohort",
         "Incidence; Rate; Age-standardized; Male/Female/Both; 1992-2021",
         "Incidence; Rate; 20 age groups; Male/Female; 1992-2021",
         "Existing curated 204-location SDI matrix, years 1992-2021")
)
fwrite(flow,file.path(output_dir,"preprocessing_flow.csv"))

outputs <- list.files(output_dir,full.names=TRUE)
outputs <- outputs[basename(outputs)!="output_manifest_sha256.csv"]
manifest <- data.table(file=basename(outputs),bytes=file.info(outputs)$size,
                       sha256=vapply(outputs,digest::digest,character(1),file=TRUE,algo="sha256",serialize=FALSE))
fwrite(manifest,file.path(output_dir,"output_manifest_sha256.csv"))
writeLines(capture.output(sessionInfo()),file.path(output_dir,"sessionInfo.txt"))
writeLines("COMPLETE: raw GBD disease files were filtered into fixed 204-location analysis inputs without modifying historical files.",file.path(output_dir,"PREPROCESSING_COMPLETE.txt"))
message("Complete: ",normalizePath(output_dir,winslash="/"))
