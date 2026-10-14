.PHONY: render render-html render-pdf render-archival legacy-r legacy-r-html legacy-r-pdf historical-test test renv-init stata-check stata stata-test
.PHONY: triangulation-test triangulation-fixture triangulation-render triangulation-preflight triangulation-review

render:
	@test -n "$(RUN)" || (echo 'Set RUN to an explicit saved aggregate run.'; exit 1)
	Rscript --vanilla scripts/render_triangulation.R review "$(RUN)" all

render-html:
	@test -n "$(RUN)" || (echo 'Set RUN to an explicit saved aggregate run.'; exit 1)
	Rscript --vanilla scripts/render_triangulation.R review "$(RUN)" html

render-pdf:
	@test -n "$(RUN)" || (echo 'Set RUN to an explicit saved aggregate run.'; exit 1)
	Rscript --vanilla scripts/render_triangulation.R review "$(RUN)" pdf

render-archival:
	quarto render archive/r/reconstructed_obesity_hrf_from_pdf.qmd --to html

legacy-r:
	@test -n "$(INPUT)" || (echo 'Set an explicit historical INPUT.'; exit 1)
	Rscript --vanilla scripts/render_historical.R "$(INPUT)" all

legacy-r-html:
	@test -n "$(INPUT)" || (echo 'Set an explicit historical INPUT.'; exit 1)
	Rscript --vanilla scripts/render_historical.R "$(INPUT)" html

legacy-r-pdf:
	@test -n "$(INPUT)" || (echo 'Set an explicit historical INPUT.'; exit 1)
	Rscript --vanilla scripts/render_historical.R "$(INPUT)" pdf

historical-test:
	Rscript --vanilla tests/run_historical_tests.R

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
	Rscript --vanilla scripts/preflight_triangulation.R "$(INPUT)" $(if $(MANIFEST),"$(MANIFEST)")

triangulation-review:
	@test -n "$(RUN)" || (echo 'Set an explicit saved RUN directory.'; exit 1)
	Rscript --vanilla scripts/render_triangulation.R review "$(RUN)"
