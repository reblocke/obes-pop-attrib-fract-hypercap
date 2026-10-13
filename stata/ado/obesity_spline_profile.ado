* Fixed-covariate logit profile matching the former xblc, pr eform calls.
* Uses observed basis values directly, without float() equality or numlist rounding.
capture program drop obesity_spline_profile
program define obesity_spline_profile
    version 18.0
    syntax varlist(min=1 numeric), COVname(varname) GENerate(namelist min=4 max=4) [Level(cilevel)]
    confirm numeric variable `covname'
    if "`e(cmd)'" != "logit" {
        di as error "obesity_spline_profile requires the fitted logit model."
        exit 301
    }
    foreach output of local generate {
        confirm new variable `output'
    }
    if "`level'" == "" {
        local level = c(level)
    }
    local expression "_b[_cons]"
    foreach basis of local varlist {
        local expression "`expression' + _b[`basis']*`basis'"
    }
    tempvar unique_value log_odds lower_log_odds upper_log_odds
    quietly egen byte `unique_value' = tag(`covname') if !missing(`covname')
    quietly predictnl double `log_odds' = `expression' if `unique_value' == 1, ///
        ci(`lower_log_odds' `upper_log_odds') level(`level')
    tokenize `generate'
    quietly generate double `1' = `covname' if `unique_value' == 1
    quietly generate double `2' = exp(`log_odds')
    quietly generate double `3' = exp(`lower_log_odds')
    quietly generate double `4' = exp(`upper_log_odds')
end
