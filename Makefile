# Current curve-first, audit-first workflow. Run from repository root.
PREP_PYTHON ?= python3
CONFIG ?= config/bmi_hypercapnia_analysis.json
.PHONY: test fixture preflight cohort-audit analyze render render-html render-pdf prepare map qualify preparation-test source-qualification-test

test:
	Rscript --vanilla tests/run_bmi_curve_tests.R
	"$(PREP_PYTHON)" -m unittest discover -s tests -p 'test_preparation*.py'
	"$(PREP_PYTHON)" -m unittest discover -s tests -p 'test_original_population.py'
	"$(PREP_PYTHON)" -m unittest discover -s tests -p 'test_source_qualification.py'

fixture:
	Rscript --vanilla scripts/run_bmi_hypercapnia.R fixture "$(CONFIG)"

preflight cohort-audit analyze:
	@test -n "$(INPUT)" -a -n "$(MANIFEST)" || (echo 'Set explicit INPUT and MANIFEST paths.'; exit 1)
	Rscript --vanilla scripts/run_bmi_hypercapnia.R "$@" "$(INPUT)" "$(MANIFEST)" "$(CONFIG)"

render:
	@test -n "$(RUN)" || (echo 'Set RUN to an explicit saved version-5 aggregate run.'; exit 1)
	Rscript --vanilla scripts/render_bmi_hypercapnia.R "$(RUN)" all

render-html:
	@test -n "$(RUN)" || (echo 'Set RUN to an explicit saved version-5 aggregate run.'; exit 1)
	Rscript --vanilla scripts/render_bmi_hypercapnia.R "$(RUN)" html

render-pdf:
	@test -n "$(RUN)" || (echo 'Set RUN to an explicit saved version-5 aggregate run.'; exit 1)
	Rscript --vanilla scripts/render_bmi_hypercapnia.R "$(RUN)" pdf

prepare:
	@test -n "$(SOURCE_CONFIG)" -a -n "$(OUTPUT)" || (echo 'Set reviewed SOURCE_CONFIG and fresh private OUTPUT.'; exit 1)
	"$(PREP_PYTHON)" scripts/prepare_common_index_input.py --config "$(SOURCE_CONFIG)" --output "$(OUTPUT)"

map:
	@test -n "$(SOURCE_CONFIG)" -a -n "$(OUTPUT)" || (echo 'Set SOURCE_CONFIG and fresh external OUTPUT.'; exit 1)
	"$(PREP_PYTHON)" scripts/map_common_index_covariates.py --config "$(SOURCE_CONFIG)" --output "$(OUTPUT)"

qualify:
	@test -n "$(SOURCE_CONFIG)" -a -n "$(PREPARED)" -a -n "$(OUTPUT)" || (echo 'Set SOURCE_CONFIG, PREPARED and fresh OUTPUT.'; exit 1)
	"$(PREP_PYTHON)" scripts/qualify_common_index_source.py --config "$(SOURCE_CONFIG)" --prepared "$(PREPARED)" --output "$(OUTPUT)"

preparation-test:
	"$(PREP_PYTHON)" -m unittest discover -s tests -p 'test_preparation*.py'
	"$(PREP_PYTHON)" -m unittest discover -s tests -p 'test_original_population.py'

source-qualification-test:
	"$(PREP_PYTHON)" -m unittest discover -s tests -p 'test_source_qualification.py'
