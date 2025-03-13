#' @importFrom utils citation
.onAttach<-function(libname, pkgname){
  cit<-citation(pkgname)
  txt<-paste(c(format(cit,"citation")),collapse="\n\n")
  packageStartupMessage(txt)
}
