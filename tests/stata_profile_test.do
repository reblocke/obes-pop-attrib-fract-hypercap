* Synthetic precision and covariance regression tests; no clinical input.
version 18.0
args repo_root
do "`repo_root'/stata/ado/obesity_spline_profile.ado"
clear
set seed 20261012
set obs 600
gen long row_id = _n
gen double bmi = 40 + mod(_n, 21)
gen double age = 20 + mod(_n, 60)
gen byte sex = (runiform() > 0.5)
gen byte y = (runiform() < invlogit(-3 + 0.05*(bmi-40) + 0.01*(age-50)))
mkspline2 s_bmi = bmi, cubic knots(41 50 59)
mkspline2 s_age = age, cubic knots(22 48 77)
quietly logit y s_bmi* s_age* i.sex
matrix original_b = e(b)
matrix original_v = e(V)
quietly _datasignature row_id bmi age sex y s_bmi* s_age*
local signature_before `"`r(datasignature)'"'

levelsof bmi, local(integer_levels)
xblc s_bmi1 s_bmi2, covname(bmi) at(`integer_levels') eform ///
    generate(old_x old_odds old_lb old_ub) pr
obesity_spline_profile s_bmi1 s_bmi2, covname(bmi) ///
    generate(new_x new_odds new_lb new_ub)
assert mreldif(original_b, e(b)) == 0
assert mreldif(original_v, e(V)) == 0
quietly _datasignature row_id bmi age sex y s_bmi* s_age*
assert `"`r(datasignature)'"' == `"`signature_before'"'

tempfile old_profile
preserve
keep old_x old_odds old_lb old_ub
drop if missing(old_x)
rename old_x grid
save `old_profile'
restore
preserve
keep new_x new_odds new_lb new_ub
drop if missing(new_x)
rename new_x grid
merge 1:1 grid using `old_profile'
assert _merge == 3
assert _N == 21
assert reldif(new_odds, old_odds) < 1e-6
assert reldif(new_lb, old_lb) < 1e-6
assert reldif(new_ub, old_ub) < 1e-6
restore

* Decimal and nearly adjacent values retain their actual double-precision grid.
drop s_bmi* s_age* old_* new_*
replace bmi = 40.1 + mod(_n, 21)/10
replace bmi = 40.100000000001 in 1
replace bmi = 40.1 in 2
replace age = 18.1 + mod(_n, 60)/10
mkspline2 s_bmi = bmi, cubic knots(40.2 41.1 42)
mkspline2 s_age = age, cubic knots(18.3 21.1 23.8)
quietly logit y s_bmi* s_age* i.sex
matrix original_b = e(b)
matrix original_v = e(V)
levelsof bmi, local(decimal_levels)
capture noisily xblc s_bmi1 s_bmi2, covname(bmi) at(`decimal_levels') eform ///
    generate(bad_x bad_odds bad_lb bad_ub) pr
assert _rc == 198

obesity_spline_profile s_bmi1 s_bmi2, covname(bmi) ///
    generate(new_x new_odds new_lb new_ub)
obesity_spline_profile s_age1 s_age2, covname(age) ///
    generate(age_x age_odds age_lb age_ub)
assert mreldif(original_b, e(b)) == 0
assert mreldif(original_v, e(V)) == 0
assert row_id == _n
egen byte expected_bmi_grid = tag(bmi)
egen byte expected_age_grid = tag(age)
assert !missing(new_x) == expected_bmi_grid
assert !missing(age_x) == expected_age_grid
assert new_x == bmi if expected_bmi_grid
assert age_x == age if expected_age_grid
assert !missing(new_odds, new_lb, new_ub) if expected_bmi_grid
assert !missing(age_odds, age_lb, age_ub) if expected_age_grid
assert new_lb <= new_odds & new_odds <= new_ub if expected_bmi_grid

* Independent lincom checks use the actual row values, without float matching.
tempname basis1 basis2
forvalues i = 1/`=_N' {
    if expected_bmi_grid[`i'] {
        scalar `basis1' = s_bmi1[`i']
        scalar `basis2' = s_bmi2[`i']
        quietly lincom _b[_cons] + _b[s_bmi1]*scalar(`basis1') + _b[s_bmi2]*scalar(`basis2')
        assert reldif(new_odds[`i'], exp(r(estimate))) < 1e-10
        assert reldif(new_lb[`i'], exp(r(estimate)-invnormal(0.975)*r(se))) < 1e-8
        assert reldif(new_ub[`i'], exp(r(estimate)+invnormal(0.975)*r(se))) < 1e-8
    }
}
di as result "OBESITY_PROFILE_PRECISION_AND_COVARIANCE_OK"
