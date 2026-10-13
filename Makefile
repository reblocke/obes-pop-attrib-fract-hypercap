.PHONY: render render-html render-pdf render-archival test renv-init stata-check stata stata-test
.PHONY: triangulation-test triangulation-fixture triangulation-render triangulation-preflight triangulation-review

render:
	quarto render reports/obesity_hrf_paf_analysis.qmd

render-html:
	quarto render reports/obesity_hrf_paf_analysis.qmd --to html

render-pdf:
	quarto render reports/obesity_hrf_paf_analysis.qmd --to pdf

render-archival:
	quarto render reports/reconstructed_obesity_hrf_from_pdf.qmd --to html

test:
	@if [ -d tests/testthat ]; then \
		Rscript -e 'testthat::test_dir("tests/testthat")'; \
	else \
		echo "No tests/testthat directory yet."; \
	fi

renv-init:
	@echo "Initializing/snapshotting renv should be done only after maintainer approval."
	Rscript -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv"); renv::init(); renv::snapshot()'

stata-check:
	python3 scripts/run_stata.py check

stata:
	python3 scripts/run_stata.py run

stata-test:
	python3 -m unittest discover -s tests -p 'test_stata*.py'

triangulation-test:
	Rscript --vanilla tests/run_triangulation_tests.R

triangulation-fixture:
	Rscript --vanilla scripts/render_triangulation.R fixture

triangulation-render:
	@test -n "$(INPUT)" -a -n "$(MANIFEST)" || (echo 'Set explicit INPUT and MANIFEST paths.'; exit 1)
	Rscript --vanilla scripts/render_triangulation.R clinical "$(INPUT)" "$(MANIFEST)"

triangulation-preflight:
	@test -n "$(INPUT)" || (echo 'Set an explicit INPUT path.'; exit 1)
	Rscript --vanilla scripts/preflight_triangulation.R "$(INPUT)"

triangulation-review:
	@test -n "$(RUN)" || (echo 'Set an explicit saved RUN directory.'; exit 1)
	Rscript --vanilla scripts/render_triangulation.R review "$(RUN)"
