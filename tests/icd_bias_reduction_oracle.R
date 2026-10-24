# Independent numerical objective and a closed-form intercept check. Written
# before the direct fitter: this catches score/covariance errors a render misses.
e2e_icd_information <- function(x,pr) {
  k<-ncol(pr);p<-ncol(x);h<-matrix(0,p*(k-1),p*(k-1))
  for(a in 2:k)for(b in 2:k) {
    aa<-(a-2)*p+seq_len(p);bb<-(b-2)*p+seq_len(p)
    h[aa,bb]<-crossprod(x,x*(pr[,a]*((a==b)-pr[,b])))
  }
  h
}
e2e_icd_softmax <- function(beta,x,k) {
  eta<-cbind(0,x%*%matrix(beta,ncol=k-1));eta<-eta-apply(eta,1,max)
  pr<-exp(eta);pr/rowSums(pr)
}
e2e_icd_penalty <- function(beta,x,y,k) {
  pr<-e2e_icd_softmax(beta,x,k)
  h<-e2e_icd_information(x,pr);det<-determinant(h,logarithm=TRUE)
  if(det$sign<=0)return(Inf)
  -sum(log(pr[cbind(seq_along(y),y)]))-.5*as.numeric(det$modulus)
}
e2e_icd_bias_reduction <- function() {
  x<-cbind(1,seq(-1,1,length.out=45),rep(0:2,15)==2)
  y<-rep(1:3,15);y[x[,3]==1 & y==3]<-1L # category-specific separation
  k<-3L;theta<-seq(-.25,.25,length.out=ncol(x)*(k-1))
  numeric_score<-vapply(seq_along(theta),function(j) {
    hi<-lo<-theta;hi[j]<-hi[j]+1e-5;lo[j]<-lo[j]-1e-5
    -(e2e_icd_penalty(hi,x,y,k)-e2e_icd_penalty(lo,x,y,k))/2e-5
  },numeric(1))
  state<-bmi_firth_state(theta,x,y,k,TRUE)
  e2e_near(state$score,numeric_score,tolerance=1e-6)
  oracle<-optim(rep(0,length(theta)),e2e_icd_penalty,x=x,y=y,k=k,
    method="BFGS",control=list(maxit=2000,reltol=1e-12))
  fitted<-bmi_firth_multinomial(x,y,k,200)
  stopifnot(oracle$convergence==0,fitted$convergence==0)
  e2e_near(fitted$par,oracle$par,tolerance=2e-4)
  e2e_near(fitted$information,e2e_icd_information(x,e2e_icd_softmax(fitted$par,x,k)),tolerance=1e-9)
  intercept<-bmi_firth_multinomial(matrix(1,22,1),rep(1:3,c(17,4,1)),3,200)
  e2e_near(as.vector(intercept$probability[1,]),(c(17,4,1)+.5)/(22+1.5),tolerance=1e-7)
  # Published AS_mean five-category reference; no new package installation.
  # https://stat.ethz.ch/CRAN/web/packages/brglm2/vignettes/multinomial.html
  d<-read.csv("tests/fixtures/icd_firth_reference.csv",stringsAsFactors=FALSE)
  d<-d[rep(seq_len(nrow(d)),d$freq),]
  d$lake<-factor(d$lake,levels=c("Hancock","Oklawaha","Trafford","George"))
  d$size<-factor(d$size,levels=c("<=2.3",">2.3"))
  xx<-model.matrix(~size+lake,d,contrasts.arg=list(lake=contr.treatment(levels(d$lake),base=4),size=contr.treatment(levels(d$size),base=2)))
  yy<-match(d$foodchoice,c("Fish","Invertebrate","Reptile","Bird","Other"))
  reference<-bmi_firth_multinomial(xx,yy,5,200)
  published_beta<-c(-1.490818,1.4019624,-1.5600445,.90109748,1.081322,
    -2.908819,-.3209487,.9800182,2.10269205,2.559008,
    -1.940190,-.5828768,.6213169,-.41459453,1.026221,
    -1.815225,.3147753,.7792789,.06001729,1.450717)
  published_se<-c(.4250711,.3962267,.6003569,.4742043,.4924905,
    .8864071,.5565974,1.0218118,.9619417,.9604963,
    .6276892,.6084642,.7436454,1.0458118,.8031649,
    .5177641,.4443760,.5521476,.7489610,.6154619)
  stopifnot(reference$convergence==0,max(abs(reference$par-published_beta))<5e-6,
    max(abs(sqrt(diag(solve(reference$information)))-published_se))<5e-6)
  data.frame(check=c("numeric score and likelihood with separation","published brglm2 five-category coefficients and SEs","intercept analytic solution"),status="passed")
}
