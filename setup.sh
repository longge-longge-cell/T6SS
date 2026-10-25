#!/usr/bin/env bash
set -euo pipefail

ENV_NAME=${1:-pmt6ss_postbakta}

# Make conda shell functions available.
source "$(conda info --base)/etc/profile.d/conda.sh"

# Create the environment on the first run; update it on later runs.
if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo "[INFO] Conda environment '$ENV_NAME' already exists; updating packages..."
    conda env update -n "$ENV_NAME" -f environment.yml --prune
else
    echo "[INFO] Creating conda environment '$ENV_NAME'..."
    conda env create -n "$ENV_NAME" -f environment.yml
fi

conda activate "$ENV_NAME"

echo "[INFO] Checking TXSScan models..."
INSTALLED_MODELS="$(macsyfinder --list-models 2>/dev/null || true)"

if printf '%s\n' "$INSTALLED_MODELS" | grep -qi 'T6SS'; then
    echo "[INFO] TXSScan/T6SS models are already available; skipping model installation."
else
    echo "[INFO] Installing TXSScan models in the per-user MacSyFinder model directory..."
    # Current msf_data versions require an explicit writable destination when
    # no canonical system model directory exists. --user installs under HOME.
    msf_data install --user TXSScan
fi

echo
printf '%s\n' "[INFO] Environment ready."
printf '%s\n' "Activate it with: conda activate $ENV_NAME"
printf '%s\n' "Verify TXSScan/T6SS models with:"
printf '%s\n' "  macsyfinder --list-models | grep -i T6SS"
