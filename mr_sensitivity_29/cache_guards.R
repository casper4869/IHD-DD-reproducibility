lock_signature<-function(path,object){
 sig<-digest::digest(object,algo='sha256')
 if(file.exists(path)){
  old<-readLines(path,warn=FALSE)[1]
  if(!identical(sig,old))stop('Cache input/parameter signature changed; use a new run directory')
 } else writeLines(sig,path)
 invisible(sig)
}
