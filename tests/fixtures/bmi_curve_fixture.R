# Entirely artificial. Original keys are visibly synthetic and never exported.
make_bmi_curve_fixture <- function(n_patients=1200L,seed=20261016L,with_index_day=TRUE,adverse=TRUE) {
  set.seed(seed);patient<-rep(seq_len(n_patients),each=2);visit<-rep(1:2,n_patients);n<-length(patient)
  bmi<-pmax(20,pmin(100,stats::rgamma(n_patients,shape=9,scale=2.3)+18))
  age<-pmin(90,pmax(18,32+.65*bmi+stats::rnorm(n_patients,0,12)))
  d<-data.frame(patient_id=sprintf("ARTIFICIAL-P%06d",patient),encounter_id=sprintf("ARTIFICIAL-E%06d-%d",patient,visit),
    encounter_date=as.Date("2022-01-01")+rep(sample(0:200,n_patients,replace=TRUE),each=2)+(visit-1)*30,
    age_at_encounter=age[patient],encounter_type=sample(c("EMER","IMP"),n,TRUE),bmi=bmi[patient]+(visit-1)*rnorm(n),
    sex=rep(sample(c("0","1","2"),n_patients,TRUE,prob=c(.5,.47,.03)),each=2),
    race_ethnicity=rep(sample(as.character(0:6),n_patients,TRUE,prob=c(.5,.18,.14,.07,.04,.03,.04)),each=2),
    location=rep(sample(as.character(0:3),n_patients,TRUE),each=2),stringsAsFactors=FALSE)
  d$has_abg<-rbinom(n,1,plogis(-.1+.025*(d$bmi-40)));d$has_vbg<-rbinom(n,1,.45)
  latent<-38+.23*(d$bmi-30)+.025*(d$age_at_encounter-50)+rnorm(n,0,6)
  d$abg_pco2<-ifelse(d$has_abg==1&runif(n)>.09,pmax(12,latent+rnorm(n,0,2)),NA_real_)
  d$vbg_pco2<-ifelse(d$has_vbg==1&runif(n)>.07,pmax(13,latent+5+rnorm(n,0,3)),NA_real_)
  d$icd_hypercapnia<-rbinom(n,1,plogis(-1.3+.04*(d$bmi-35)+.008*(d$age_at_encounter-50)))
  d$icd_hypercapnia[runif(n)<.02]<-NA
  d$bmi[runif(n)<.02]<-NA_real_;d$bmi_evidence_state<-ifelse(is.na(d$bmi),"missing","valid")
  d$sex[runif(n)<.01]<-NA_character_
  if(with_index_day)for(gas in c("abg","vbg")) {
    maximum<-d[[paste0(gas,"_pco2")]];value<-ifelse(!is.na(maximum)&runif(n)>.2,pmax(12,maximum-runif(n,0,5)),NA_real_)
    d[[paste0(gas,"_pco2_index_day")]]<-value;d[[paste0(gas,"_index_day_available")]]<-ifelse(is.na(maximum),NA_integer_,as.integer(!is.na(value)))
  }
  if(adverse&&n_patients>=30) {
    d$bmi[1:2]<-c(30,42);d$bmi_evidence_state[1:2]<-"valid"
    d$encounter_date[3]<-as.Date("2021-12-31");d$encounter_type[5]<-"OTHER";d$age_at_encounter[7]<-17
    d$bmi[9]<-NA;d$bmi_evidence_state[9]<-"unresolved";d$bmi[10]<-43
    d$bmi[11:12]<-42;d$encounter_date[12]<-d$encounter_date[11]
    d$encounter_date[13]<-NA;d$bmi[13:14]<-40
    d<-rbind(d,d[15,,drop=FALSE]);row.names(d)<-NULL
  }
  d
}
