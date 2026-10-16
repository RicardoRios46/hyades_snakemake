# LLM disclosure: Claude Code (Anthropic) assisted with the development of this
# script. The code was reviewed, tested, and adapted by the authors.
"""
External Snakemake script: parcellate SIAM structures using SynthSeg+ labels.

Expected snakemake object
--------------------------
snakemake.input.synthseg   : str  — SynthSeg+ parcellation NIfTI (with --parc)
snakemake.input.siam       : str  — SIAM segmentation NIfTI
snakemake.output[0]        : str  — Output parcellated NIfTI

snakemake.params.structures : list[str] | str
    One or more SIAM structure names to process, e.g. ["GM", "Hippo", "Amyg"]
    OR the string "ALL" to process every entry in the mapping table.
    Defaults to ["GM"] if not specified.

snakemake.params.siam_structure_map : dict | None  (optional)
    Override the built-in SIAM→SynthSeg+ mapping table.
    Format: {"StructureName": (siam_value, [ss_label1, ss_label2, ...]), ...}
    If not provided, the built-in table is used.

SIAM → SynthSeg+ label mapping (built-in)
------------------------------------------
  Structure | SIAM value | SynthSeg+ labels
  ----------|------------|--------------------------------------------------
  GM        |     1      | 1000-1035 (lh cortical), 2000-2035 (rh cortical)
  cerGM     |     5      | 8, 47
  Thal      |     6      | 10, 49
  Pal       |     7      | 13, 52
  Put       |     8      | 12, 51
  Caud      |     9      | 11, 50
  Accu      |    10      | 26, 58
  Amyg      |    11      | 18, 54
  Hippo     |    12      | 17, 53
"""

import numpy as np
import nibabel as nib
from scipy.ndimage import distance_transform_edt


# ---------------------------------------------------------------------------
# Built-in SIAM → SynthSeg+ label mapping
# ---------------------------------------------------------------------------

_LH_CORTICAL = list(range(1000, 1036))   # lh parcels (incl. 1000 = unknown)
_RH_CORTICAL = list(range(2000, 2036))   # rh parcels (incl. 2000 = unknown)

DEFAULT_SIAM_STRUCTURE_MAP = {
    "GM"    : (1,  _LH_CORTICAL + _RH_CORTICAL),
    "cerGM" : (5,  [8, 47]),
    "Thal"  : (6,  [10, 49]),
    "Pal"   : (7,  [13, 52]),
    "Put"   : (8,  [12, 51]),
    "Caud"  : (9,  [11, 50]),
    "Accu"  : (10, [26, 58]),
    "Amyg"  : (11, [18, 54]),
    "Hippo" : (12, [17, 53]),
}


# ---------------------------------------------------------------------------
# Core functions
# ---------------------------------------------------------------------------

def nearest_label_propagation(trusted_labels, target_mask, structure_name=""):
    """
    Fill every target_mask voxel that has no trusted label with the label
    of its nearest trusted neighbour in 3D Euclidean space.
    """
    prefix = f"  [{structure_name}] " if structure_name else "  "

    needs_label = target_mask & (trusted_labels == 0)

    if not np.any(needs_label):
        print(f"{prefix}All voxels already have a SynthSeg+ label — "
              "no propagation needed.")
        return trusted_labels.copy()

    n_fill  = int(needs_label.sum())
    n_total = int(target_mask.sum())
    print(f"{prefix}Total voxels in SIAM mask : {n_total:,}")
    print(f"{prefix}Already labelled (trusted): {n_total - n_fill:,}")
    print(f"{prefix}Needs propagation         : {n_fill:,}  "
          f"({100 * n_fill / n_total:.1f} %)")

    _, nearest_idx = distance_transform_edt(
        trusted_labels == 0,
        return_indices=True,
    )

    result = trusted_labels.copy()
    iz, iy, ix = np.where(needs_label)
    result[iz, iy, ix] = trusted_labels[
        nearest_idx[0][iz, iy, ix],
        nearest_idx[1][iz, iy, ix],
        nearest_idx[2][iz, iy, ix],
    ]
    return result


def process_structure(ss_data, siam_data, siam_value, ss_labels,
                      structure_name, result_volume):
    """
    Trusted-seed + nearest-neighbour propagation for one SIAM structure.
    Writes results into result_volume in place.
    """
    siam_mask = siam_data == siam_value
    n_siam = int(siam_mask.sum())

    if n_siam == 0:
        print(f"  [{structure_name}] WARNING: no voxels with SIAM value "
              f"{siam_value} — skipping.")
        return

    # Trusted seeds: SynthSeg+ label is in ss_labels AND inside SIAM mask
    ss_filtered = ss_data.copy()
    ss_filtered[~np.isin(ss_data, ss_labels)] = 0

    trusted = ss_filtered.copy()
    trusted[~siam_mask] = 0

    n_trusted = int((trusted != 0).sum())
    print(f"  [{structure_name}] Trusted seeds "
          f"(SynthSeg ∩ SIAM): {n_trusted:,} / {n_siam:,} voxels")

    if n_trusted == 0:
        print(f"  [{structure_name}] WARNING: no overlap between SIAM mask "
              f"and SynthSeg+ labels {ss_labels}. "
              "Check label IDs or image alignment — skipping.")
        return

    filled = nearest_label_propagation(trusted, siam_mask, structure_name)
    result_volume[siam_mask] = filled[siam_mask]


# ---------------------------------------------------------------------------
# Main — reads configuration from the snakemake object
# ---------------------------------------------------------------------------

# --- inputs & output -------------------------------------------------------
synthseg_path = snakemake.input.synthseg
siam_path     = snakemake.input.siam
out_path      = snakemake.output[0]

# --- params ----------------------------------------------------------------
# structures: single name, list of names, or "ALL"
structures_param = getattr(snakemake.params, "structures", ["GM"])
if isinstance(structures_param, str):
    structures_param = [structures_param]   # normalise to list

# optional override of the full mapping table
custom_map = getattr(snakemake.params, "siam_structure_map", None)
structure_map = custom_map if custom_map is not None else DEFAULT_SIAM_STRUCTURE_MAP

# resolve "ALL"
if structures_param == ["ALL"]:
    structures_to_run = list(structure_map.keys())
else:
    unknown = [s for s in structures_param if s not in structure_map]
    if unknown:
        raise ValueError(
            f"Unknown structure(s): {unknown}. "
            f"Valid choices: {list(structure_map.keys())}"
        )
    structures_to_run = structures_param

# --- load ------------------------------------------------------------------
print("Loading SynthSeg+ parcellation ...")
ss_img  = nib.load(synthseg_path)
ss_data = np.asarray(ss_img.dataobj, dtype=np.int32)

print("Loading SIAM segmentation ...")
siam_data = np.asarray(nib.load(siam_path).dataobj, dtype=np.int32)

if ss_data.shape != siam_data.shape:
    raise ValueError(
        f"Shape mismatch: SynthSeg+ {ss_data.shape} vs "
        f"SIAM {siam_data.shape}. "
        "Resample to the same space first "
        "(e.g. mri_convert, flirt, or antsApplyTransforms)."
    )

# --- process ---------------------------------------------------------------
result = np.zeros_like(ss_data)

print(f"\nProcessing {len(structures_to_run)} structure(s): "
      f"{structures_to_run}\n")

for name in structures_to_run:
    siam_val, ss_lbls = structure_map[name]
    print(f"--- {name} (SIAM value {siam_val}) ---")
    process_structure(ss_data, siam_data,
                      siam_value=siam_val,
                      ss_labels=ss_lbls,
                      structure_name=name,
                      result_volume=result)
    print()

# --- save ------------------------------------------------------------------
print(f"Saving result to {out_path} ...")
out_img = nib.Nifti1Image(result, ss_img.affine, ss_img.header)
nib.save(out_img, out_path)

unique_labels = np.unique(result[result != 0])
print(f"Done. Output contains {len(unique_labels)} unique parcel labels.")