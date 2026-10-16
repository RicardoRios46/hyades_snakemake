#!/usr/bin/env python3
# LLM disclosure: Claude Code (Anthropic) assisted with the development of this
# script. The code was reviewed, tested, and adapted by the authors.
"""
Normalize ROI volumes from a pre-computed CSV against an approximate
total intracranial volume (TIV) estimated from a SynthSeg tissue segmentation.

Inputs:
    - tiv_dseg : SynthSeg discrete segmentation NIfTI (GM/WM/CSF/ventricle
                 labels). TIV = sum of all non-background label volumes.
    - hippunfold_volumes_tsv  : TSV containing per-subfield volume measurements

Output: an additional TSV with an additional normalized_volume values
    (normalized_volume = vol_mm3 / TIV_mm3).
"""

import numpy as np
import nibabel as nib
import pandas as pd


def compute_tiv(tiv_dseg_path, include_labels=None, exclude_labels=(0,)):
    """
    Approximate TIV (mm^3) by summing label volumes from a tissue segmentation.

    If `include_labels` is given, TIV = sum of volumes of exactly those label
    IDs. Otherwise, TIV = sum of every label except `exclude_labels`
    (default: background = 0).
    """
    img = nib.load(str(tiv_dseg_path))
    data = np.rint(img.get_fdata()).astype(np.int64)
    vox_vol = float(np.prod(img.header.get_zooms()[:3]))

    labels, counts = np.unique(data, return_counts=True)
    volumes = {int(lab): float(cnt) * vox_vol for lab, cnt in zip(labels, counts)}

    if include_labels is not None:
        include_set = {int(l) for l in include_labels}
        return sum(v for lab, v in volumes.items() if lab in include_set)
    else:
        exclude_set = {int(l) for l in exclude_labels}
        return sum(v for lab, v in volumes.items() if lab not in exclude_set)


# --- Snakemake entry point ---
tiv_include_labels = getattr(snakemake.params, "tiv_include_labels", None)
tiv_exclude_labels = tuple(getattr(snakemake.params, "tiv_exclude_labels", (0,)))

tiv_mm3 = compute_tiv(
    snakemake.input.tiv_dseg,
    include_labels=tiv_include_labels,
    exclude_labels=tiv_exclude_labels,
)

if tiv_mm3 <= 0:
    raise ValueError(
        "Computed TIV is zero or negative -- check tiv_dseg and your "
        "tiv_include_labels / tiv_exclude_labels selection."
    )

df = pd.read_csv(snakemake.input.hippunfold_volumes_tsv, sep='\t')

df = df.rename(columns={"subject": "participant_id", "hemi": "hemisphere"})
df = df.set_index(["participant_id", "hemisphere"])

df= df / tiv_mm3

df.to_csv(snakemake.output.tsv, sep='\t', index=True)


print(f"TIV (approx.) = {tiv_mm3:.2f} mm^3")
print(f"Wrote {len(df)} structures to {snakemake.output.tsv}")