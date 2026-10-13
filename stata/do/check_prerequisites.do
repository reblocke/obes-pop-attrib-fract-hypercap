* No clinical input is opened by this check.
if c(stata_version) < 18 {
    di as error "Stata 18 or newer is required."
    exit 9
}
version 18.0
set more off
local missing_package = 0
foreach command in table1_mc mkspline2 {
    capture which `command'
    if _rc {
        di as error "Missing `command'. Review and install its package manually before running."
        local missing_package = 1
    }
}
capture findfile scheme-cleanplots.scheme
if _rc {
    di as error "Missing cleanplots scheme. Review and install cleanplots manually."
    local missing_package = 1
}
if `missing_package' {
    exit 499
}
di as result "OBESITY_STATA_PREREQUISITES_OK"
