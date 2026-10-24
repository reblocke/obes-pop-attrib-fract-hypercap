# Firth mean bias reduction for baseline-category logits. Maximizes the
# multinomial log likelihood + 0.5 log|I|, without Poisson nuisance columns.
# Kosmidis & Firth (2011), doi:10.1093/biomet/asr026. Category-major parameters.
# Only the ICD full model selects this estimator. S1/primary fits are unchanged.
bmi_firth_state <- function(beta,x,y,k,adjustment=TRUE) {
  p<-ncol(x);c<-k-1L;n<-nrow(x)
  eta<-cbind(0,x%*%matrix(beta,ncol=c));eta<-eta-apply(eta,1,max)
  pr<-exp(eta);pr<-pr/rowSums(pr);q<-pr[,-1,drop=FALSE]
  info<-matrix(0,p*c,p*c)
  blocks<-lapply(seq_len(c),function(j)(j-1)*p+seq_len(p))
  for(j in seq_len(c))for(l in j:c) {
    block<-crossprod(x,x*(q[,j]*((j==l)-q[,l])))
    info[blocks[[j]],blocks[[l]]]<-block
    info[blocks[[l]],blocks[[j]]]<-t(block)
  }
  chol_info<-tryCatch(chol(info),error=function(e)NULL)
  if(is.null(chol_info))return(list(objective=-Inf))
  ll<-sum(log(pr[cbind(seq_len(n),y)]))
  state<-list(objective=ll+sum(log(diag(chol_info))),log_likelihood=ll,
    information=info,probability=pr)
  if(!adjustment)return(state)
  inverse<-chol2inv(chol_info);diagonal<-bp<-matrix(0,n,c)
  # B_i[j,l] = x_i' I^{-1}_{jl} x_i. Only retain its diagonal and B_i p_i.
  for(j in seq_len(c))for(l in j:c) {
    v<-rowSums((x%*%inverse[blocks[[j]],blocks[[l]],drop=FALSE])*x)
    bp[,j]<-bp[,j]+v*q[,l]
    if(j==l)diagonal[,j]<-v else bp[,l]<-bp[,l]+v*q[,j]
  }
  d<-rowSums(diagonal*q);quad<-rowSums(bp*q)
  adjusted<-.5*q*(diagonal-d-2*bp+2*quad)
  truth<-matrix(0,n,c);positive<-which(y>1);truth[cbind(positive,y[positive]-1L)]<-1
  state$score<-as.vector(crossprod(x,truth-q+adjusted))
  state$inverse<-inverse
  state
}

bmi_firth_multinomial <- function(x,y,k,maxit) {
  beta<-rep(0,ncol(x)*(k-1L));state<-bmi_firth_state(beta,x,y,k)
  status<-1L
  for(iter in seq_len(maxit)) {
    if(!is.finite(state$objective)||any(!is.finite(state$score)))break
    step<-as.vector(state$inverse%*%state$score)
    if(max(abs(state$score))<1e-6 && max(abs(step))<1e-7) {status<-0L;break}
    accepted<-FALSE
    for(half in 0:30) {
      candidate<-beta+step/(2^half)
      next_state<-bmi_firth_state(candidate,x,y,k,FALSE)
      if(is.finite(next_state$objective) && next_state$objective>=state$objective-1e-10) {
        accepted<-TRUE;break
      }
    }
    if(!accepted)break
    beta<-candidate;state<-bmi_firth_state(beta,x,y,k)
  }
  list(par=beta,information=state$information,probability=state$probability,
    log_likelihood=state$log_likelihood,penalized_log_likelihood=state$objective,
    score=state$score,convergence=status,iterations=iter)
}
