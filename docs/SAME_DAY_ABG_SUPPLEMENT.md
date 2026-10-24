# Same-day physiological components

This formerly separate supplement is now an integrated endpoint family in the
[scientific specification](BMI_HYPERCAPNIA_TRIANGULATION_PLAN.md). It repeats in
the all-valid-BMI primary and nested BMI≥30 secondary, using each population's
fixed spline basis. The scientific PDF defines its methods before presenting any
results. S1 retains the stacked joint-probability layout and component intervals.

One unpenalized three-category multinomial model describes no documented
hypercapnia, hypercapnia without documented same-day acidemia, and hypercapnia
with same-day acidemia. Any co-observed day with ordinary arterial PCO₂≥45 and
arterial pH<7.35 takes priority. Validity is 5<PCO₂<200 and 6.5<pH<7.8; values are
classified before rounding. Elevated PCO₂ and low pH on different dates do not
qualify. The full specification and source contract are authoritative.

This is **same recorded-day co-occurrence; not verified same-sample pairing**.
Different samples or treatment periods can contribute. “Without documented same-day
acidemia” is not proof of compensation or of no acidemia at another time.
No component-specific PIF, observation regression or timing duplicate is added.

`make prepare` assembles the evidence with other endpoint families. Missing policy
or capture retains unavailable states; a corrupt supplied record fails. There is
no separate enrichment launcher or requirement for an identical prior run.
`R/same_day_multinomial.R` supplies joint fitting, paired covariance and supported
contrasts; `R/same_day_abg.R` supplies this family's ledger and evidence checks.

## Historical evidence

- [Pairing feasibility](../results/2026-10-20-paired-abg/README.md): same-sample identifiers unsupported.
- [Earlier binary recorded-day endpoints](../results/2026-10-20-same-day-abg/README.md).
- [Earlier joint BMI-restricted results](../results/2026-10-20-same-day-components/README.md).

These snapshots remain immutable and do not establish new all-BMI results or new
investigator approval. Runtime schema13 rejects historical bundles rather than
changing their labels. Source, numerical, visual and scientific review are separate.
