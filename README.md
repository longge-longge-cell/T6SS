# PmT6SS-discovery

A reproducible pilot-to-scale pipeline for systematic discovery of *Proteus mirabilis* T6SS effector families.

The workflow is inspired by the 2026 Salmonella systematic T6SS-effector study, but is adapted for *P. mirabilis* by explicitly adding:

1. Hcp/VgrG/PAAR genomic-neighborhood candidates
2. Hcp/VgrG/PAAR fusion candidates (flagged only; exact domain boundaries are not guessed)
3. Full-length Rhs C-terminal toxin (CT) extraction
4. Orphan Rhs-fragment -> CT -> immunity cassettes
5. Proteus-like multigene Hcp/VgrG effector modules

## Important design principle

This pipeline is intentionally conservative about mechanistic annotation.
It generates **candidate families**, not experimentally proven effectors.
A DPxGL-derived Rhs CT is automatically cut only when the last plausible motif yields a 50-450 aa tail. Other Rhs proteins are exported to `rhs_manual_review.tsv`.
HHpred/Foldseek/Pfam results should be used to prioritize families, not to declare biochemical activity.

---

## 1. Installation

Requires Linux/Ubuntu and conda/mamba.

```bash
cd PmT6SS_discovery
./setup.sh pmt6ss
conda activate pmt6ss
```

Install a Bakta database (light is adequate for the pilot; full is preferable for final analysis):

```bash
mkdir -p databases
bakta_db download --output databases --type light
find databases -maxdepth 2 -type f -name 'version.json' -printf '%h\n'
```

Edit:

```yaml
# config/config.yaml
bakta_db: /absolute/path/to/the/bakta/db
```

Check TXSScan models:

```bash
macsyfinder --list-models | grep -i T6SS
```

If needed:

```bash
msf_data install --user TXSScan
```

---

## 2. Input genomes

Put nucleotide genome assemblies in `genomes/`:

```text
genomes/
  F1_89.fna
  T35.fna
  HI4320.fna
  BB2000.fna
```

If you only have GenBank/GBFF:

```bash
python scripts/gbff_to_fna.py T35.gbff genomes/T35.fna
```

Generate sample manifest:

```bash
python scripts/make_manifest.py genomes config/samples.tsv
cat config/samples.tsv
```

For NCBI assembly accessions, put one accession per line in `accessions.txt`, then:

```bash
./download_accessions.sh accessions.txt
```

---

## 3. Run the complete pilot

```bash
CORES=12 ./run.sh
```

Dry run first if desired:

```bash
CORES=12 ./run.sh -n
```

Resume after interruption:

```bash
CORES=12 ./run.sh
```

Snakemake will only rerun incomplete/outdated steps.

---

## 4. Main output files

### QC

`results/final/qc_summary.tsv`

Columns include genome size, number of contigs, N50 and a soft `pass_basic_qc` flag.
The pipeline does **not** delete failed assemblies automatically.

### Candidate proteins

`results/final/all_candidates.tsv`
`results/final/all_candidates.faa`

Important `route` values:

- `A_neighborhood`: non-core gene close to Hcp/VgrG/PAAR
- `B_fusion_flag`: unusually long Hcp/VgrG/PAAR; exact fusion boundary requires domain inspection
- `C_Rhs_CT`: automatically extracted CT after a plausible C-terminal DPxGL motif
- `D_orphan_Rhs_downstream`: first downstream ORF after a short Rhs fragment; candidate orphan CT

### Rhs requiring manual review

`results/discovery/<sample>/rhs_manual_review.tsv`

Do not discard these. They include Rhs proteins without a DPxGL configuration that met the automatic CT rule.

### Candidate toxin-immunity pairs

`results/final/candidate_immunity.tsv`

The default definition is a 40-350 aa non-core ORF within the next 2 transcriptionally downstream genes. This is contextual evidence, not proof of immunity.

### Proteus multigene modules

`results/final/modules_routeE.tsv`

This retains Hcp/VgrG-associated multigene operons that do not fit a simple one-toxin/one-immunity architecture.

### Candidate family clustering

`results/final/families.tsv`
`results/final/family_members.tsv`
`results/final/presence_absence.tsv`

Default MMseqs2 family discovery parameters:

- minimum sequence identity: 0.70
- coverage: 0.80
- E-value: 1e-3

These mirror the near-homology grouping logic used in the Salmonella study and are configurable in `config/config.yaml`.

### Profile HMMs

`results/hmms/families/`
`results/hmms/PmTox_all.hmm`
`results/hmms/PmTox_vs_allproteins.tbl`

Families with >=3 members receive MAFFT alignments and HMMER profile models.

### Prioritized families

`results/final/scored_families.tsv`
`results/final/Tier_I_families.tsv`

Scoring is transparent and editable in `config/config.yaml`.
Tier-I means high priority for manual sequence/structure interpretation, **not proven T6SS effector**.

---

## 5. Recommended 50-genome pilot acceptance criteria

Before scaling to 1000-2000 genomes, require all three:

1. Known *P. mirabilis* T6SS loci/modules are recovered in controls such as HI4320/BB2000.
2. Rhs CTs already recognized manually in F1_89/T35 are recovered by Route C/D, or are explicitly sent to `rhs_manual_review.tsv`.
3. Tier-I output is small enough for human review (ideally tens, not thousands, of families).

If criterion 3 fails, tighten candidate selection or adjust family/score thresholds before scaling.

---

## 6. Manual/structural annotation of Tier-I families

Export representatives:

```bash
python scripts/export_tier_reps.py \
  --scored results/final/scored_families.tsv \
  --members results/final/family_members.tsv \
  --faa results/final/all_candidates.faa \
  --tier Tier_I \
  --out results/final/Tier_I_representatives.faa
```

Then annotate Tier-I representatives with:

- HMMER/Pfam/InterPro
- HHpred
- AlphaFold
- Foldseek
- known T6SS toxin databases/models (SecReT6/BastionHub where appropriate)

Fill the blank columns in `scored_families.tsv`:

- `manual_sequence_annotation`
- `manual_structure_annotation`
- `manual_final_status`

Recommended final statuses:

- `KNOWN_TOXIN`
- `DIVERGENT_KNOWN_FAMILY`
- `NOVEL_CANDIDATE_FAMILY`
- `LIKELY_NON_EFFECTOR`
- `NEEDS_REVIEW`

---

## 7. Scaling to 1000-2000 genomes

Use the same workflow. For large datasets:

1. Prefer the Bakta light DB during discovery, then re-check Tier-I representatives with richer databases.
2. Run on a workstation/HPC with Snakemake profiles or a job scheduler.
3. Consider replacing `mmseqs easy-cluster` with `easy-linclust` if candidate sequence count becomes very large.
4. Preserve a full, non-redundant discovery set separately from a prevalence set so clonal over-representation does not define families.

---

## 8. Caveats that must remain in the manuscript/grant

- Genomic proximity is evidence of association, not secretion.
- A downstream small ORF is only a candidate immunity protein.
- DPxGL is a strong Rhs boundary cue but is not universal.
- Structural similarity is not proof of substrate or catalytic activity.
- Draft genome fragmentation can split Hcp/VgrG/Rhs modules.
- TXSScan is used as an independent T6SS-system detector; candidate discovery also uses standardized Bakta annotation so isolated/orphan loci are not lost.

