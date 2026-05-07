.PHONY: render render-pdf render-archival test renv-init

render:
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
