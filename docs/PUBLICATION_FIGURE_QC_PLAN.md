# Publication figure refinement — 2026-10-17

## Brief and scope

Refine every current scientific figure and its alternatives, and propagate the
same readable plotting conventions to the complete audit atlas. The audience is
ATS/manuscript investigators and reviewers. Use the existing 190-mm width; no
unverified journal-specific compliance claim is intended. The source is the
qualified schema-7 aggregate run, not clinical records. Preserve all original
estimates, confidence limits, denominators, binning, support states and prior
exports. No estimation, new clinical data access or scientific recoding.

## Reader's comparisons

- F1 A–C: compare BMI–hypercapnia relationships across the three outcomes while
  retaining usable-evidence probabilities and the full BMI frequency distribution.
  Short outcome labels and one combined model/reference N free space for curves.
  Keep pointwise bands, sparse/extrapolated line styles and the ICD capture note.
- F2: compare observed and shifted standardized probabilities using direct labels
  and saved model-based 95% intervals, next to signed original-BMI-band contributions. Keep
  the band-specific paired means in a separate audit figure, with no invented
  uncertainty where the saved bundle contains none.
- F5: compare timing windows or matched definitions on common BMI and probability
  scales. Replace internal identifiers with named outcomes/windows.
- RFS evidence/flow and F0: show the denominator, source partition and exact
  interval endpoints clearly. Obesity-only remains flow/audit material.
- F3/F4: retain all stages, categories, tails, failures and diagnostics. Improve
  shared typography and labels without altering aggregation or model diagnostics.

## Source changes and verification

Edit `R/reporting.R`, `R/report_views.R`, `R/rfs_reporting.R` and the audit report's
figure list. Keep captions and alt text synchronized. Export SVG/PDF masters and
300-dpi PNG/JPG candidates into a fresh review. All data labels must remain at
least 9 points after embedding; use a concise hierarchy rather than smaller text.

Check exact plotted coordinates, confidence limits and sample sizes against the
same bundle, including unavailable, negative and zero states. Run focused
artificial output checks through `make test`, including actual HTML/PDF integration.
Run `scripts/check_report_exports.py` for full export bounds/symbol/collision
coverage. Inspect every proposed scientific export and assembled scientific
page, plus the complete atlas contact sheets and native examples of each audit
template. Record the actual inspection scope and unresolved limitations in the
skill's QC manifest/review receipt. Successful export is not visual or scientific
approval.

## Silent-failure risks

Repeated titles can compress data panels; PDF height limits can shrink otherwise
readable text; automatic scales can obscure comparisons or clip intervals;
shortened labels can lose outcome/denominator meaning. Preserve full-range views,
explicit inset labels, exact uncertainty and self-contained captions. Keep
aggregate integrity and render-source hashes separate from visual judgments.

## Completed review

The final review is `20261017T205353-20587` under the unchanged clinical run
`curve-analyze-20261017T175520-51541`. The scientific report has 34 pages and the
complete audit has 2,970 pages. All 1,242 figure sets retain vector masters and
300-dpi PNG reviews; all 39 key layouts additionally have JPG candidates. Eight
unassessed supporting layouts remain explicitly outside the submission candidates.
F1-A is preferred, with B/C preserved for comparison.

The historical 74-check acceptance run and 27 focused RFS checks passed for this
dated review; current verification uses the E2E workflow in `tests/README.md`. Twenty-nine
saved-aggregate coordinate checks and 47 printed-annotation checks pass; all
native figure fonts are at least 9 points. Both HTML/PDF reports pass integration
and complete table/coefficient/covariance coverage. No clinical input was read
and no model was refitted. Render-source and bundle hashes were verified.

A real report-font defect was reproduced on 16 pages and repaired without
installing packages. Both the failed review and its corrected successor remain
preserved. The final geometry/symbol check covers every report page and figure;
all 3,765 reused figure export files match their already inspected hashes.

Actual pixel inspection covers all 39 key layouts at native size in grayscale,
all 34 atlas overview sheets, seven native audit-template examples, all scientific
page overviews, 11 native scientific pages, and 25 audit overviews/10 native audit
pages. It does not assert native inspection of every audit figure or manual
reading of every audit page. Investigator approval and final venue-size/portal
checks remain separate. `PUBLICATION_QC_REVIEW.md`, the unified manifest and the
visual receipt in the private review record the exact scope and evidence.

The private `CURRENT_REVIEW.md` links the reports, comparison gallery, QC findings
and acceptance evidence. Subsequent release verification is recorded in `WORKLOG.md`;
generated outputs remain ignored. Original inputs, models, historical exports and scientific definitions
remain unchanged.
