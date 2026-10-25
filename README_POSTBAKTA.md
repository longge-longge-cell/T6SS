# PmT6SS post-Bakta pipeline

This version STARTS FROM EXISTING BAKTA RESULTS. It does not run Bakta or assembly QC.

## Expected Bakta layout
Recommended:

bakta_results/
  F1_89/F1_89.tsv
  F1_89/F1_89.faa
  F1_89/F1_89.gff3
  T35/T35.tsv
  T35/T35.faa
  T35/T35.gff3

Flat directories also work as long as .tsv and .faa share the same basename.

## 1. Environment
```bash
./setup.sh pmt6ss_postbakta
conda activate pmt6ss_postbakta
macsyfinder --list-models | grep -i T6SS
```

## 2. Build input manifest
```bash
python scripts/make_bakta_manifest.py /ABS/PATH/TO/bakta_results config/bakta_samples.tsv
cat config/bakta_samples.tsv
```
Required columns are `sample`, `tsv`, `faa`. `gff3` is recorded but not required by the current discovery steps.

## 3. Validate only
```bash
python scripts/validate_bakta_inputs.py --manifest config/bakta_samples.tsv --out results/final/input_validation.tsv
```

## 4. Dry run
```bash
CORES=12 ./run.sh -n
```

## 5. Full run
```bash
CORES=12 ./run.sh
```

## Main outputs
- results/discovery/<sample>/anchors.tsv : Hcp/VgrG/PAAR/Rhs/adaptor/core anchors
- results/discovery/<sample>/neighborhoods.tsv : ORF neighborhoods
- results/discovery/<sample>/candidates.tsv : Routes A-D candidates
- results/discovery/<sample>/rhs_manual_review.tsv : Rhs not safely auto-cut
- results/discovery/<sample>/candidate_immunity.tsv : downstream candidate immunity proteins
- results/discovery/<sample>/modules_routeE.tsv : operon-level modules
- results/final/all_candidates.tsv/.faa
- results/final/families.tsv
- results/final/presence_absence.tsv
- results/final/scored_families.tsv
- results/final/Tier_I_families.tsv
- results/hmms/PmTox_all.hmm

## Important note
Automatic Rhs CT extraction only occurs when a plausible C-terminal `DPxGL` junction is detected and leaves a 50-450 aa tail. Rhs proteins failing this rule are intentionally sent to `rhs_manual_review.tsv` rather than force-cut.
