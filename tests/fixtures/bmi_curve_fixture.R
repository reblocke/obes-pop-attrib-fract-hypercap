# Entirely artificial. Original keys are visibly synthetic and never exported.
make_bmi_curve_fixture <- function(n_patients=6000L,seed=20261016L,with_index_day=TRUE,adverse=TRUE) {
  set.seed(seed);patient<-rep(seq_len(n_patients),each=2);visit<-rep(1:2,n_patients);n<-length(patient)
  bmi<-pmax(20,pmin(100,stats::rgamma(n_patients,shape=9,scale=2.3)+9))
  age<-pmin(90,pmax(18,32+.65*bmi+stats::rnorm(n_patients,0,12)))
  d<-data.frame(patient_id=sprintf("ARTIFICIAL-P%06d",patient),encounter_id=sprintf("ARTIFICIAL-E%06d-%d",patient,visit),
    encounter_date=as.Date("2022-01-01")+rep(sample(0:200,n_patients,replace=TRUE),each=2)+(visit-1)*30,
    age_at_encounter=age[patient],encounter_type=ifelse(rbinom(n,1,plogis(-.4+.08*(bmi[patient]-30))),"IMP","EMER"),bmi=bmi[patient]+(visit-1)*rnorm(n),
    sex=rep(sample(c("0","1","2"),n_patients,TRUE,prob=c(.45,.45,.10)),each=2),
    race_ethnicity=rep(sample(as.character(0:6),n_patients,TRUE,prob=c(.3,.15,.15,.1,.1,.1,.1)),each=2),
    location=rep(sample(as.character(0:3),n_patients,TRUE),each=2),stringsAsFactors=FALSE)
  for(name in bmi_rfs_fields)d[[name]]<-0L
  d$OBESITY_rfs<-as.integer(patient%%3!=0)
  d$ABG_rfs<-as.integer(patient%%3!=1)
  d$bmi_method<-sample(c("current","prior","calculated"),n,TRUE)
  d$reported_bmi<-d$bmi;d$reported_date<-d$encounter_date-ifelse(d$bmi_method=="prior",180,0)
  d$height_date<-d$weight_date<-d$encounter_date
  d$height_inches<-65;d$weight_pounds<-d$bmi*65^2/703
  d$bmi_reason<-"artificial valid source";d$raw_race<-d$race_ethnicity;d$raw_ethnicity<-"0"
  d$obesity_trigger<-"trigger_unresolved"
  inpatient<-as.integer(d$encounter_type=="IMP")
  d$has_abg<-rbinom(n,1,plogis(-.7+.025*(d$bmi-40)+1.2*inpatient));d$has_vbg<-rbinom(n,1,plogis(-.5+.5*inpatient))
  latent<-40+.23*(d$bmi-30)+.025*(d$age_at_encounter-50)+3.5*inpatient+rnorm(n,0,6)
  d$abg_pco2<-ifelse(d$has_abg==1&runif(n)>.09,pmax(12,latent+rnorm(n,0,2)),NA_real_)
  d$vbg_pco2<-ifelse(d$has_vbg==1&runif(n)>.07,pmax(13,latent+5+rnorm(n,0,3)),NA_real_)
  d$icd_hypercapnia<-rbinom(n,1,plogis(-1.6+.04*(d$bmi-35)+.008*(d$age_at_encounter-50)+.7*inpatient))
  d$icd_hypercapnia[runif(n)<.02]<-NA
  d$bmi[runif(n)<.02]<-NA_real_;d$bmi_evidence_state<-ifelse(is.na(d$bmi),"missing","valid")
  d$sex[runif(n)<.01]<-NA_character_
  if(with_index_day)for(gas in c("abg","vbg")) {
    maximum<-d[[paste0(gas,"_pco2")]];value<-ifelse(!is.na(maximum)&runif(n)>.2,pmax(12,maximum-runif(n,0,5)),NA_real_)
    d[[paste0(gas,"_pco2_index_day")]]<-value;d[[paste0(gas,"_index_day_available")]]<-ifelse(is.na(maximum),NA_integer_,as.integer(!is.na(value)))
  }
  if(adverse&&n_patients>=30) {
    d$bmi[1:2]<-c(24,42);d$bmi_evidence_state[1:2]<-"valid"
    d$bmi[17:20]<-c(30,42,30.2,44)
    d$encounter_date[3]<-as.Date("2021-12-31");d$encounter_type[5]<-"OTHER";d$age_at_encounter[7]<-17
    d$bmi[9]<-NA;d$bmi_evidence_state[9]<-"unresolved";d$bmi[10]<-43
    d$bmi[11:12]<-42;d$encounter_date[12]<-d$encounter_date[11]
    d$encounter_date[13]<-NA;d$bmi[13:14]<-40
    d<-rbind(d,d[15,,drop=FALSE]);row.names(d)<-NULL
  }
  d$bmi_evidence_state[!is.na(d$bmi)]<-"valid"
  id<-as.integer(sub("ARTIFICIAL-P","",d$patient_id))
  valid<-!is.na(d$abg_pco2)&id%%4!=0
  for(v in bmi_same_day_fields)d[[v]]<-rep(0L,nrow(d))
  d$same_day_abg_state<-ifelse(valid,"coobserved_day","no_coobserved_day")
  d$same_day_abg_n_days<-as.integer(valid)
  d$hypercapnia_coobserved<-ifelse(valid,as.integer(d$abg_pco2>=45),NA_integer_)
  d$hypercapnia_acidemia_same_day<-ifelse(valid,as.integer(d$abg_pco2>=45 & id%%2!=0),NA_integer_)
  d$same_day_abg_noncoobserved_high<-as.integer(!valid & !is.na(d$abg_pco2) & d$abg_pco2>=45)
  d$same_day_abg_usable_pco2<-as.integer(!is.na(d$abg_pco2))
  d$same_day_abg_coobserved_pco2<-d$same_day_abg_usable_ph<-d$same_day_abg_coobserved_ph<-as.integer(valid)
  d$same_day_abg_co2_only_days<-as.integer(!valid & !is.na(d$abg_pco2))
  d$icd_capture_state<-ifelse(is.na(d$icd_hypercapnia),"incomplete","complete")
  for(v in bmi_icd_flags)d[[v]]<-ifelse(is.na(d$icd_hypercapnia),NA_integer_,0L)
  # Deterministic synthetic patterns, independent of the existing random stream.
  patterns<-rbind(c(1,0,0,0,0),c(0,1,0,0,0),c(0,0,1,0,0),c(0,0,0,1,0),c(0,0,0,0,1),c(1,0,0,0,1),c(0,1,0,0,1))
  positive<-which(d$icd_hypercapnia %in% 1)
  for(j in seq_along(bmi_icd_flags))d[[bmi_icd_flags[j]]][positive]<-patterns[1+(id[positive]%%7),j]
  d
}
