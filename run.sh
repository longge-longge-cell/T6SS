#!/usr/bin/env bash
set -euo pipefail
CORES=${CORES:-12}
mkdir -p logs results/final
snakemake --snakefile workflow/Snakefile --cores "$CORES" --printshellcmds --rerun-incomplete "$@"
