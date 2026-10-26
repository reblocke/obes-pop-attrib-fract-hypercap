# Independent numerical oracle, specified before the post-estimation implementation.
verify_gradient <- function(beta,fun,gradient,label,tolerance=5e-6) {
  finite<-vapply(seq_along(beta),function(j) {
    hi<-lo<-beta;hi[j]<-hi[j]+1e-6;lo[j]<-lo[j]-1e-6
    (fun(hi)-fun(lo))/2e-6
  },numeric(1))
  error<-max(abs(finite-gradient))
  if(!is.finite(error)||error>tolerance)stop("Finite-difference gradient mismatch: ",label)
  data.frame(check=label,maximum_absolute_gradient_error=error,tolerance=tolerance,passed=TRUE)
}
