# Current curve/audit workflow; run from the repository root.
PREP_PYTHON ?= python3
CONFIG ?= config/bmi_hypercapnia_analysis.json
.PHONY: test source-test fixture preflight cohort-audit analyze render render-html render-pdf render-reports prepare map qualify enrich-rfs

test:
	Rscript --vanilla tests/run_e2e.R

source-test:
	"$(PREP_PYTHON)" tests/run_source_checks.py

fixture:
	Rscript --vanilla scripts/run_bmi_hypercapnia.R fixture "$(CONFIG)"

preflight cohort-audit analyze:
	@test -n "$(INPUT)" -a -n "$(MANIFEST)" || (echo 'Set explicit INPUT and MANIFEST paths.'; exit 1)
	Rscript --vanilla scripts/run_bmi_hypercapnia.R "$@" "$(INPUT)" "$(MANIFEST)" "$(CONFIG)"

render:
	@test -n "$(RUN)" || (echo 'Set RUN to an explicit saved version-10 aggregate run.'; exit 1)
	Rscript --vanilla scripts/render_bmi_hypercapnia.R "$(RUN)" all

render-html:
	@test -n "$(RUN)" || (echo 'Set RUN to an explicit saved version-10 aggregate run.'; exit 1)
	Rscript --vanilla scripts/render_bmi_hypercapnia.R "$(RUN)" html

render-pdf:
	@test -n "$(RUN)" || (echo 'Set RUN to an explicit saved version-10 aggregate run.'; exit 1)
	Rscript --vanilla scripts/render_bmi_hypercapnia.R "$(RUN)" pdf

# Rebuild prose/tables using source-matched figures from the same saved run.
render-reports:
	@test -n "$(RUN)" -a -n "$(FIGURES_FROM)" || (echo 'Set RUN and FIGURES_FROM to the same saved-run review.'; exit 1)
	BMI_FIGURES_FROM="$(FIGURES_FROM)" Rscript --vanilla scripts/render_bmi_hypercapnia.R "$(RUN)" all

map prepare:
	@test -n "$(SOURCE_CONFIG)" -a -n "$(OUTPUT)" || (echo 'Set reviewed SOURCE_CONFIG and fresh private OUTPUT.'; exit 1)
	"$(PREP_PYTHON)" scripts/$(if $(filter map,$@),map_common_index_covariates,prepare_common_index_input).py --config "$(SOURCE_CONFIG)" --output "$(OUTPUT)"

qualify:
	@test -n "$(SOURCE_CONFIG)" -a -n "$(PREPARED)" -a -n "$(OUTPUT)" || (echo 'Set SOURCE_CONFIG, PREPARED and fresh OUTPUT.'; exit 1)
	"$(PREP_PYTHON)" scripts/qualify_common_index_source.py --config "$(SOURCE_CONFIG)" --prepared "$(PREPARED)" --output "$(OUTPUT)"

# Accepted metadata only; no new clinical outcome extraction.
enrich-rfs:
	@test -n "$(SOURCE_CONFIG)" -a -n "$(INPUT)" -a -n "$(MANIFEST)" -a -n "$(RFS_EVIDENCE)" -a -n "$(OUTPUT)" -a -n "$(PRIOR_RUN)" || (echo 'Set SOURCE_CONFIG INPUT MANIFEST RFS_EVIDENCE OUTPUT PRIOR_RUN.'; exit 1)
	"$(PREP_PYTHON)" scripts/enrich_rfs_input.py --source-config "$(SOURCE_CONFIG)" --input "$(INPUT)" --manifest "$(MANIFEST)" --rfs-evidence "$(RFS_EVIDENCE)" --output "$(OUTPUT)" --prior-run "$(PRIOR_RUN)"

# Recorded-day co-occurrence audit/enrichment; never fits clinical models.
.PHONY: enrich-same-day-abg
enrich-same-day-abg:
	@test -n "$(SOURCE_CONFIG)" -a -n "$(INPUT)" -a -n "$(MANIFEST)" -a -n "$(OUTPUT)" || (echo 'Set SOURCE_CONFIG INPUT MANIFEST and fresh OUTPUT.'; exit 1)
	"$(PREP_PYTHON)" scripts/enrich_same_day_abg.py --source-config "$(SOURCE_CONFIG)" --input "$(INPUT)" --manifest "$(MANIFEST)" --output "$(OUTPUT)"
