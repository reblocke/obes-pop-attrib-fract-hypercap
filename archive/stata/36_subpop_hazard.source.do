* Hypercapnia TriNetX Subpopulation hazard of excess BMI over 40
* Updated 12/08/2025 BWL

/* ---------
OVERALL TODO LIST

Centralized outstanding TODOs. Each item includes the local context that
originally sat next to the relevant block.

[ ] Revisit whether the BMI > 40 cohort is the right target population.
    Context: the opening design note restricts to encounters included because
    BMI exceeded 40, but also notes that using all patients with blood gases
    would change the selection mechanism.
[ ] Revisit the outcome definitions against the CHEST-paper framing.
    Context: the current script models hypercapnic respiratory failure within
    the BMI > 40 cohort, but the original note flagged alternate outcomes.
[ ] Review whether additional non-mediated covariates should be controlled.
    Context: the opening design note currently emphasizes age, sex, region, and
    race/ethnicity as the main confounders.
[ ] Investigate the apparent histogram step at BMI 50.
    Context: the OBESITY_rfs histogram drawn with `width(1) start(40)` shows a
    visible break between 49.9 and 50.


-----------*/

capture log close

version 18.0

set more off
if c(mode) == "batch" {
    set graphics off
}

* Data processing
clear

args repo_root_override p3q_s_date_override

if "$S_DATE" == "" {
	global S_DATE "`c(current_date)'"
}
local analysis_s_date "$S_DATE"
if "`p3q_s_date_override'" != "" {
	local analysis_s_date "`p3q_s_date_override'"
}

local repo_root "`repo_root_override'"
if "`repo_root'" == "" {
	foreach candidate in "." ".." "../.." "../../.." "../../../.." "../../../../.." "../../../../../.." {
		capture confirm file "`candidate'/config/paths.do.example"
		if !_rc {
			local repo_root "`candidate'"
			continue, break
		}
	}
}

if "`repo_root'" == "" {
	di as error "Could not locate the repo root from the current working directory."
	di as error "Start Stata in this repository (or one of its subdirectories), or pass the repo root as the first argument."
	exit 601
}

cd "`repo_root'"
local repo_root_abs "`c(pwd)'"

local analysis_slug "subpop-hazard"
local analysis_log_root "`repo_root_abs'/reports/stata-logs/hypercapnia/`analysis_slug'"
local analysis_log_dir "`analysis_log_root'/`analysis_s_date'"
local analysis_figure_root "`repo_root_abs'/reports/figures/hypercapnia/`analysis_slug'"
local analysis_figure_dir "`analysis_figure_root'/`analysis_s_date'"
local analysis_table_root "`repo_root_abs'/reports/tables/hypercapnia/`analysis_slug'"
local analysis_table_dir "`analysis_table_root'/`analysis_s_date'"
local analysis_diag_root "`repo_root_abs'/reports/diagnostics/hypercapnia/`analysis_slug'"
local analysis_diag_dir "`analysis_diag_root'/`analysis_s_date'"
local analysis_codebook_dir "`analysis_diag_dir'/codebooks"
local analysis_source_data_dir "`repo_root_abs'/data/derived/hypercapnia/preprocessing"
local analysis_full_db_input "`analysis_source_data_dir'/full_db.dta"
capture confirm file "`analysis_full_db_input'"
if _rc {
	di as error "Expected preprocessing output not found: `analysis_full_db_input'"
	exit 601
}
local analysis_output_data_root "`repo_root_abs'/data/derived/hypercapnia"
local analysis_output_data_dir "`analysis_output_data_root'/`analysis_slug'"
local do_file_path "`repo_root_abs'/stata/do/36_subpop_hazard.do"

capture mkdir "`repo_root_abs'/reports/stata-logs/hypercapnia"
capture mkdir "`analysis_log_root'"
capture mkdir "`analysis_log_dir'"
capture mkdir "`repo_root_abs'/reports/figures/hypercapnia"
capture mkdir "`analysis_figure_root'"
capture mkdir "`analysis_figure_dir'"
capture mkdir "`repo_root_abs'/reports/tables/hypercapnia"
capture mkdir "`analysis_table_root'"
capture mkdir "`analysis_table_dir'"
capture mkdir "`repo_root_abs'/reports/diagnostics/hypercapnia"
capture mkdir "`analysis_diag_root'"
capture mkdir "`analysis_diag_dir'"
capture mkdir "`analysis_codebook_dir'"
capture mkdir "`repo_root_abs'/data/derived/hypercapnia"
capture mkdir "`analysis_output_data_dir'"

local a1=substr(c(current_time),1,2)
local a2=substr(c(current_time),4,2)
local a3=substr(c(current_time),7,2)
local do_snapshot_name "(`a1'_`a2'_`a3')Hypercapnia subpop hazard.do"

capture confirm file "`do_file_path'"
if _rc {
	di as error "Live do-file not found: `do_file_path'"
	exit 601
}
copy "`do_file_path'" "`analysis_log_dir'/`do_snapshot_name'", replace

set scheme cleanplots
graph set window fontface "Helvetica"
log using "`analysis_log_dir'/temp.log", replace

/* -------------------
 ---- START DATA ANALYSIS --------
 ----------------------*/ 
 
clear

use "`analysis_full_db_input'", clear
cd "`analysis_output_data_dir'"
//use "`analysis_source_data_dir'/subsample_db_5_perc", clear

*-------------------------------------------
* Min setup
*-------------------------------------------
* Keep OBESITY RFS group
keep if OBESITY_rfs == 1
keep if bmi >= 40 //THis is actually 40 - so we should change to that. 


* Ensure essentials are present
drop if missing(bmi, age_at_encounter, sex, race_ethnicity, location)

/* -----------------------------------------
visualize/show the baseline data
------------------------------------------*/

* Table 1 for analysis sample (all vars used in regressions)
table1_mc,  ///
    vars( ///
        bmi               conts %4.1f \ ///
        age_at_encounter  contn %4.1f \ ///
        sex               cat   %4.1f \ ///
        race_ethnicity    cat   %4.1f \ ///
        location          cat   %4.1f \ ///
        hypercap_resp_failure bin %4.1f \ ///
        has_abg              bin %4.1f \ ///
        hypercap_on_abg      bin %4.1f \ ///
    ) ///
    percent_n percsign("%") iqrmiddle(",") ///
    sdleft(" (±") sdright(")") ///
    missing onecol ///
    saving("`analysis_table_dir'/Overall Cohort chars.xlsx", replace)

* -----------------------------------------
* Histograms: age and BMI
* -----------------------------------------

* Age distribution (18–90)
histogram age_at_encounter if inrange(age_at_encounter,18,90), ///
    width(2) start(18) density ///
    fcolor(gs8) lcolor(black) ///
    xlabel(20(10)90) xmtick(20(10)90) ///
    xtitle("Age (years)") ///
    ytitle("Density") ///
    title("Age distribution, OBESITY_rfs cohort") ///
    name(age_hist, replace)

* BMI distribution (>=40 by design) – trim to 40–80, fix empty right tail
histogram bmi if inrange(bmi,40,80), ///
    width(1) start(40) density ///
    fcolor(gs8) lcolor(black) ///
    xlabel(40(5)80) xmtick(40(5)80) ///
    xtitle("BMI (kg/m^2)") ///
    ytitle("Density") ///
    title("BMI distribution, OBESITY_rfs cohort") ///
    name(bmi_hist, replace)

* -----------------------------------------
* Stacked-style bar charts for sex, race_ethnicity, and location
* -----------------------------------------

capture drop one
gen byte one = 1

graph bar (percent) one, over(sex) ///
    bar(1, fcolor(gs8) lcolor(black)) ///
    ylabel(0(10)100, format(%2.0f)) ///
    ytitle("Percent of encounters") ///
    title("Sex distribution") ///
    legend(off) ///
    name(baseline_sex, replace)

graph bar (percent) one, over(race_ethnicity) ///
    bar(1, fcolor(gs8) lcolor(black)) ///
    ylabel(0(10)100, format(%2.0f)) ///
    ytitle("Percent of encounters") ///
    title("Race/ethnicity distribution") ///
    legend(off) ///
    name(baseline_race, replace)

graph bar (percent) one, over(location) ///
    bar(1, fcolor(gs8) lcolor(black)) ///
    ylabel(0(10)100, format(%2.0f)) ///
    ytitle("Percent of encounters") ///
    title("Location of encounter") ///
    legend(off) ///
    name(baseline_location, replace)

drop one

/* -----------------------------------------

APPROACH 1: LINEAR (log-odds) REGRESSIONS

----------------------------------------- */ 

*-------------------------------------------
* Outcome A: Hypercapnia diagnosis flag
*-------------------------------------------

logit hypercap_resp_failure c.bmi c.age_at_encounter i.sex i.race_ethnicity i.location

* Get two margins in ONE call: 1) as observed, 2) as observed with BMI fixed at 40
margins, at((asobserved) _all) at(bmi=40) post

* PIF = 1 - (risk with BMI=40) / (risk at observed BMI)
nlcom (PIF: 1 - _b[2._at] / _b[1._at])

* display the two risks
display as text "Observed risk (mean pred): " %6.4f _b[1._at]
display as text "Counterfactual risk at BMI=40: " %6.4f _b[2._at]
display as text "PIF (risk reduction proportion): " %6.4f (1 - _b[2._at]/_b[1._at])

*-------------------------------------------
* Outcome B: Hypercapnia by ABG 
*-------------------------------------------
preserve
keep if has_abg == 1
drop if missing(hypercap_on_abg, bmi, age_at_encounter, sex, location, race_ethnicity)

logit hypercap_on_abg c.bmi c.age_at_encounter i.sex i.race_ethnicity i.location

margins, at((asobserved) _all) at(bmi=40) post
nlcom (PIF: 1 - _b[2._at]/_b[1._at])

* display the two risks
display as text "Observed risk (mean pred): " %6.4f _b[1._at]
display as text "Counterfactual risk at BMI=40: " %6.4f _b[2._at]
display as text "PIF (risk reduction proportion): " %6.4f (1 - _b[2._at]/_b[1._at])

restore


/* -----------------------------------------

APPROACH 2: RESTRICTED CUBIC SPLINE (3-knot) REGRESSIONS

----------------------------------------- */ 

*-------------------------------------------
* Sample restriction, ensure essential vars
*-------------------------------------------

drop if missing(hypercap_resp_failure, bmi, age_at_encounter, sex, location, race_ethnicity)

*-------------------------------------------
* Choose knots: 3-knot RCS at p5, p50, p95
*-------------------------------------------
quietly centile bmi, centile(5 50 95)
local kb1 = r(c_1)
local kb2 = r(c_2)
local kb3 = r(c_3)

quietly centile age_at_encounter, centile(5 50 95)
local ka1 = r(c_1)
local ka2 = r(c_2)
local ka3 = r(c_3)

*-------------------------------------------
* Build RCS bases with mkspline2 (stub names)
*-------------------------------------------
* BMI spline basis
mkspline2 s_bmi = bmi, cubic knots(`kb1' `kb2' `kb3')
* Age spline basis
mkspline2 s_age = age_at_encounter, cubic knots(`ka1' `ka2' `ka3')

* Sanity check: list the generated basis variables
ds s_bmi*
local vlist_bmi `r(varlist)'
ds s_age*
local vlist_age `r(varlist)'

*-------------------------------------------
* Logistic model with RCS(BMI) + RCS(Age) + sex
*-------------------------------------------
logit hypercap_resp_failure `vlist_bmi' `vlist_age' i.sex i.location i.race_ethnicity

*-------------------------------------------
* Build the "BMI=40" counterfactual basis constants with mkspline2
*-------------------------------------------
tempvar bmi_cf
gen double `bmi_cf' = 40
mkspline2 s_bmi40 = `bmi_cf', cubic knots(`kb1' `kb2' `kb3')

* Construct an at()-list mapping s_bmi* vars to their cf-constants
ds s_bmi40*
local vlist_cf `r(varlist)'

local at_cf
local i = 0
foreach v of local vlist_cf {
    local ++i
    quietly summarize `v', meanonly
    local val = r(mean)
    local basevar : word `i' of `vlist_bmi'
    local at_cf `at_cf' `basevar'=`val'
}

*-------------------------------------------
* Margins and PIF
*-------------------------------------------
* Two sets: 1) as observed, 2) BMI set to 40 via spline-basis constants
margins, at((asobserved) _all) at(`at_cf') post

* PIF = 1 - (risk under BMI=40) / (risk at observed BMI)
nlcom (PIF: 1 - _b[2._at] / _b[1._at])

* Optional: print the two risks and the PIF
display as text "Observed risk (mean pred): " %6.4f _b[1._at]
display as text "Counterfactual risk at BMI=40: " %6.4f _b[2._at]
display as text "PIF (risk reduction proportion): " %6.4f (1 - _b[2._at]/_b[1._at])


/* Visualize the age and bmi splines */ 

* ---------- ICD hypercapnia: visualize BMI and age splines ----------

* Make sure we have the spline basis varlists
ds s_bmi*
local vlist_bmi `r(varlist)'

ds s_age*
local vlist_age `r(varlist)'

* Refit the spline model so e(b) corresponds to the RCS logistic
quietly logit hypercap_resp_failure `vlist_bmi' `vlist_age' ///
    i.sex i.location i.race_ethnicity

* ---------------- BMI spline ----------------

* Use all observed BMI values (restrict here if you want a narrower range)
levelsof bmi, local(bmi_levels)

xblc `vlist_bmi', ///
    covname(bmi) at(`bmi_levels') reference(40) eform ///
    generate(bmi_x bmi_or bmi_lb bmi_ub) pr

* Convert odds ratios (relative to BMI 40) to "probabilities" as in the PACO2 example
gen double bmi_prob    = bmi_or/(1 + bmi_or)
gen double bmi_prob_lb = bmi_lb/(1 + bmi_lb)
gen double bmi_prob_ub = bmi_ub/(1 + bmi_ub)

* ICD Hypercapnia; BMI spline (log-scale y, BMI 40–75 only)
twoway ///
    (line bmi_prob_lb bmi_prob_ub bmi_x, ///
        sort lc(black black) lp(longdash longdash)) ///
    (line bmi_prob bmi_x, ///
        sort lc(black) lp(l)) ///
    if inrange(bmi_x, 40, 75), ///
    ///
    xscale(range(40 75)) ///
    yscale(log range(0.001 0.05)) ///
    scheme(cleanplots) legend(off) ///
    xlabel(40(5)75) xmtick(40(5)75) ///
    ylabel(0.0001 0.0002 0.0005 0.001 0.002 0.005 0.01 0.02 0.05, format(%4.3f)) ///
    ytitle("Proportion: encounters w Hypercap RF ICD") xtitle("BMI (kg/m^2)") ///
    title("ICD Hypercapnia; BMI spline") ///
    yline(0.001, lp("shortdash") lc(gs10)) ///
    xline(40,    lp("shortdash_dot") lc(gs10)) ///
    note(" ") ///
    name(ICD_BMI_spline, replace)
	
* ---------------- Age spline ----------------

levelsof age_at_encounter, local(age_levels)

xblc `vlist_age', ///
    covname(age_at_encounter) at(`age_levels') reference(60) eform ///
    generate(age_x age_or age_lb age_ub) pr

gen double age_prob    = age_or/(1 + age_or)
gen double age_prob_lb = age_lb/(1 + age_lb)
gen double age_prob_ub = age_ub/(1 + age_ub)

* ICD Hypercapnia; age spline (log-scale y, age 18–90)
twoway ///
    (line age_prob_lb age_prob_ub age_x, ///
        sort lc(black black) lp(longdash longdash)) ///
    (line age_prob age_x, ///
        sort lc(black) lp(l)) ///
    if inrange(age_x, 18, 90), ///
    ///
    xscale(range(18 90)) ///
    yscale(log range(0.001 0.4)) ///
    scheme(cleanplots) legend(off) ///
    xlabel(20(10)90) xmtick(20(10)90) ///
    ylabel(0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.4, format(%4.3f)) ///
    ytitle("Proportion: encounters w Hypercap RF ICD") ///
    xtitle("Age at encounter (years)") ///
    title("ICD Hypercapnia; age spline") ///
    yline(0.001, lp("shortdash") lc(gs10)) ///
    xline(60,    lp("shortdash_dot") lc(gs10)) ///
    note(" ") ///
    name(ICD_age_spline, replace)


* -----------------------------------------
* Outcome B: Hypercapnia by ABG — RCS PIF
* -----------------------------------------
preserve
keep if has_abg == 1
drop if missing(hypercap_on_abg, bmi, age_at_encounter, sex, location, race_ethnicity)

* Recompute knots WITHIN the ABG subset
quietly centile bmi, centile(5 50 95)
local kb1 = r(c_1)
local kb2 = r(c_2)
local kb3 = r(c_3)

quietly centile age_at_encounter, centile(5 50 95)
local ka1 = r(c_1)
local ka2 = r(c_2)
local ka3 = r(c_3)

* RCS bases via mkspline2
capture drop s_bmi*
capture drop s_age*
mkspline2 s_bmi = bmi,              cubic knots(`kb1' `kb2' `kb3')
mkspline2 s_age = age_at_encounter, cubic knots(`ka1' `ka2' `ka3')

ds s_bmi*
local vlist_bmi `r(varlist)'
ds s_age*
local vlist_age `r(varlist)'

* RCS model for ABG hypercapnia
quietly logit hypercap_on_abg `vlist_bmi' `vlist_age' ///
    i.sex i.race_ethnicity i.location

* Basis constants for BMI = 40
tempvar bmi_cf
gen double `bmi_cf' = 40
mkspline2 s_bmi40 = `bmi_cf', cubic knots(`kb1' `kb2' `kb3')

ds s_bmi40*
local vlist_cf `r(varlist)'

local at_cf
local i = 0
foreach v of local vlist_cf {
    local ++i
    quietly summarize `v', meanonly
    local val = r(mean)
    local basevar : word `i' of `vlist_bmi'
    local at_cf `at_cf' `basevar'=`val'
}

* Margins + PIF on the probability scale
margins, at((asobserved) _all) at(`at_cf') post

nlcom (PIF: 1 - _b[2._at]/_b[1._at])

display as text "Observed risk (mean pred): " %6.4f _b[1._at]
display as text "Counterfactual risk at BMI=40: " %6.4f _b[2._at]
display as text "PIF (risk reduction proportion): " ///
    %6.4f (1 - _b[2._at]/_b[1._at])

restore

* ---------- ABG hypercapnia: visualize BMI and age splines ----------

preserve
keep if has_abg == 1
drop if missing(hypercap_on_abg, bmi, age_at_encounter, sex, location, race_ethnicity)

* Drop any spline output vars from earlier sections to avoid name collisions
capture drop bmi_x bmi_or bmi_lb bmi_ub bmi_prob bmi_prob_lb bmi_prob_ub
capture drop age_x age_or age_lb age_ub age_prob age_prob_lb age_prob_ub

* Choose knots within the ABG subset (3-knot RCS at p5, p50, p95)
quietly centile bmi, centile(5 50 95)
local kb1 = r(c_1)
local kb2 = r(c_2)
local kb3 = r(c_3)

quietly centile age_at_encounter, centile(5 50 95)
local ka1 = r(c_1)
local ka2 = r(c_2)
local ka3 = r(c_3)

* RCS bases via mkspline2
capture drop s_bmi*
capture drop s_age*
mkspline2 s_bmi = bmi,              cubic knots(`kb1' `kb2' `kb3')
mkspline2 s_age = age_at_encounter, cubic knots(`ka1' `ka2' `ka3')

ds s_bmi*
local vlist_bmi `r(varlist)'
ds s_age*
local vlist_age `r(varlist)'

* RCS model for ABG hypercapnia **(now consistent with other models)**
quietly logit hypercap_on_abg `vlist_bmi' `vlist_age' ///
    i.sex i.race_ethnicity i.location

* ... [rest of your BMI and age spline plotting code unchanged] ...

* ---------------- BMI spline ----------------

levelsof bmi, local(bmi_levels)

xblc `vlist_bmi', ///
    covname(bmi) at(`bmi_levels') reference(40) eform ///
    generate(bmi_x bmi_or bmi_lb bmi_ub) pr

gen double bmi_prob    = bmi_or/(1 + bmi_or)
gen double bmi_prob_lb = bmi_lb/(1 + bmi_lb)
gen double bmi_prob_ub = bmi_ub/(1 + bmi_ub)

* ABG hypercapnia; BMI spline (log-scale y, BMI 40–75)
twoway ///
    (line bmi_prob_lb bmi_prob_ub bmi_x, ///
        sort lc(black black) lp(longdash longdash)) ///
    (line bmi_prob bmi_x, ///
        sort lc(black) lp(l)) ///
    if inrange(bmi_x, 40, 75), ///
    ///
    xscale(range(40 75)) ///
    yscale(log range(0.001 0.6)) ///
    scheme(cleanplots) legend(off) ///
    xlabel(40(5)75) xmtick(40(5)75) ///
    ylabel(0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.4 0.6, format(%4.3f)) ///
    ytitle("Proportion: encounters w hypercapnia on ABG") ///
    xtitle("BMI (kg/m^2)") ///
    title("ABG hypercapnia; BMI spline") ///
    yline(0.001, lp("shortdash") lc(gs10)) ///
    xline(40,    lp("shortdash_dot") lc(gs10)) ///
    note(" ") ///
    name(ABG_BMI_spline, replace)

graph export "`analysis_figure_dir'/ABG_BMI_spline.tif", ///
    as(tif) name("ABG_BMI_spline") replace
graph save ABG_BMI_spline "`analysis_figure_dir'/ABG_BMI_spline.gph", replace

* ---------------- Age spline ----------------

levelsof age_at_encounter, local(age_levels)

xblc `vlist_age', ///
    covname(age_at_encounter) at(`age_levels') reference(60) eform ///
    generate(age_x age_or age_lb age_ub) pr

gen double age_prob    = age_or/(1 + age_or)
gen double age_prob_lb = age_lb/(1 + age_lb)
gen double age_prob_ub = age_ub/(1 + age_ub)

* ABG hypercapnia; age spline (log-scale y, age 18–90)
twoway ///
    (line age_prob_lb age_prob_ub age_x, ///
        sort lc(black black) lp(longdash longdash)) ///
    (line age_prob age_x, ///
        sort lc(black) lp(l)) ///
    if inrange(age_x, 18, 90), ///
    ///
    xscale(range(18 90)) ///
    yscale(log range(0.001 0.6)) ///
    scheme(cleanplots) legend(off) ///
    xlabel(20(10)90) xmtick(20(10)90) ///
    ylabel(0.001 0.002 0.005 0.01 0.02 0.05 0.1 0.2 0.4 0.6, format(%4.3f)) ///
    ytitle("Proportion: encounters w hypercapnia on ABG") ///
    xtitle("Age at encounter (years)") ///
    title("ABG hypercapnia; age spline") ///
    yline(0.001, lp("shortdash") lc(gs10)) ///
    xline(60,    lp("shortdash_dot") lc(gs10)) ///
    note(" ") ///
    name(ABG_Age_spline, replace)

graph export "`analysis_figure_dir'/ABG_Age_spline.tif", ///
    as(tif) name("ABG_Age_spline") replace
graph save ABG_Age_spline "`analysis_figure_dir'/ABG_Age_spline.gph", replace

restore

clear
