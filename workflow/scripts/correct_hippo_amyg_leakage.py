#!/usr/bin/env python3
# LLM disclosure: Claude Code (Anthropic) assisted with the development of this
# script. The code was reviewed, tested, and adapted by the authors.
"""
correct_hippo_amyg_leakage.py

Corrects CSF leakage into the Hippocampus / Amygdala labels of a SIAM
segmentation, using the subject's own CSFv/CSF and GM labels as an
intensity reference. Runs on a single subject per invocation.

LOGIC:
  1. Build LOCAL intensity references:
       - CSF reference = CSFv (+ CSF) label voxels near the Hippo/Amyg ROI
       - GM reference  = an auxiliary parahippocampal/entorhinal mask if
                          supplied (see AUXILIARY GM REFERENCE below),
                          otherwise GM-label voxels near the Hippo/Amyg ROI
  2. Compute a CSF/GM decision threshold from those references (Gaussian
     decision boundary by default, with Otsu / midpoint fallbacks).
  3. DETECTION GATE: if too few Hippo/Amyg voxels look CSF-like, do
     nothing (protects subjects where SIAM already worked well).
  4. CONNECTIVITY-GATED CORRECTION: among CSF-like candidate voxels,
     keep only those that are spatially CONNECTED to real, pre-existing
     CSF/CSFv voxels (morphological reconstruction). This corrects gross,
     contiguous leakage without requiring sub-voxel boundary precision,
     and without touching low-intensity voxels that are not connected to
     a real CSF compartment.
  5. SAFETY CAP: if the connected correction would relabel an unusually
     large fraction of the Hippo/Amyg volume, it is NOT auto-applied --
     the subject is flagged for manual review instead, unless
     --force-apply is given (see FORCING below).
  6. Relabel corrected voxels as CSF (3) or CSFv (4) depending on which
     compartment they are connected to.

AUXILIARY GM REFERENCE (--aux-labels):
  This file can be EITHER of two things, auto-detected by default:
    - A SIAM-style label volume (same LUT as --labels): label 1 (GM) is
      used as the GM reference.
    - A SynthSeg "robust + parcellation" (Desikan-Killiany) dseg volume:
      the entorhinal/parahippocampal cortical labels are used as the GM
      reference (default IDs 1006/1016/2006/2016, override with
      --synthseg-gm-labels).
  Detection heuristic: SIAM labels only go up to 17, so any aux volume
  with values above --aux-detect-threshold (default 100) is treated as
  a SynthSeg/Desikan parcellation. Override with --aux-labels-type if
  the heuristic ever picks the wrong one.

FORCING (--force-apply):
  Applies the connectivity-gated correction even when it exceeds the
  safety cap (e.g. after you've manually reviewed a case and confirmed
  the large correction is genuine). The result is still logged with a
  distinct status ("corrected_over_cap") so these cases remain easy to
  find and QC later, rather than being indistinguishable from ordinary
  corrections.

No bias-field correction is performed by this script. If you want N4 (or
similar) applied, run it on the T1 beforehand and pass the corrected
image as --t1.

Every run writes:
  - a corrected label NIfTI (unchanged copy if no correction was made
    or applied)
  - a mask NIfTI of the identified leak/candidate voxels (for visual QC,
    written even when the correction was not auto-applied)
  - a row appended to a CSV log with all the diagnostic numbers needed
    to tune parameters (threshold used, candidate fraction, corrected
    fraction, status, reference voxel counts, fallbacks triggered, etc.)

LABELS (per the provided SIAM/FreeSurfer-style LUT):
  1=GM 2=WM 3=CSF 4=CSFv 5=cerGM 6=Thal 7=Pal 8=Put 9=Caud 10=Accu
  11=Amyg 12=Hippo 13=Dura 14=vascular 15=Skull 16=Head 17=Anomalies

CLI FLAGS

  Required:
    --t1 PATH                  T1w NIfTI for this subject.
    --labels PATH               SIAM label NIfTI for this subject.
    --out-labels PATH           Output path for the corrected label NIfTI
                                 (always written, even if unchanged).

  Optional:
    --out-mask PATH              Output path for the leak/candidate mask
                                  NIfTI. Default: <out-labels>_leakmask.nii.gz
    --aux-labels PATH             Auxiliary label volume for the local GM
                                  reference (SIAM-style or SynthSeg/Desikan
                                  dseg -- see AUXILIARY GM REFERENCE above).
                                  Default: none (falls back to a dilation-
                                  based local search in the main --labels GM).
    --aux-labels-type {auto,siam,synthseg}
                                  Force how --aux-labels is interpreted.
                                  Default: auto
    --synthseg-gm-labels LIST     Comma-separated label IDs used as the GM
                                  reference when --aux-labels is SynthSeg/
                                  Desikan. Default: 1006,1016,2006,2016
                                  (entorhinal + parahippocampal, both
                                  hemispheres).
    --aux-detect-threshold FLOAT   Max label value above which --aux-labels
                                  is auto-detected as SynthSeg/Desikan rather
                                  than SIAM. Default: 100
    --csf-search-radius-mm FLOAT   Radius used to restrict the CSF reference
                                  to CSFv/CSF voxels near the Hippo/Amyg ROI.
                                  Default: 15.0
    --gm-search-radius-mm FLOAT    Same, for the GM reference (only used when
                                  --aux-labels is not supplied, or as a
                                  fallback). Default: 15.0
    --min-ref-voxels INT           Minimum reference voxels before falling
                                  back to a wider/global search. Default: 30
    --epsilon-detect FLOAT         Minimum CSF-like fraction of the Hippo+
                                  Amyg volume needed to trigger any
                                  correction attempt at all (the gate that
                                  protects already-good segmentations).
                                  Default: 0.02
    --safety-cap-fraction FLOAT    Maximum fraction of the Hippo+Amyg volume
                                  allowed to be auto-corrected before the
                                  subject is flagged for manual review
                                  instead. Default: 0.25
    --connectivity {6,18,26}      3D connectivity used for the region-
                                  growing/connected-component step.
                                  Default: 26
    --threshold-method {auto,gaussian,otsu,midpoint}
                                  How the CSF/GM decision threshold is
                                  computed. Default: auto (Gaussian, falling
                                  back to Otsu, falling back to midpoint).
    --csf-margin-sigma FLOAT      Shift the candidate threshold toward the
                                  CSF mean by this many sigma_csf units
                                  (clamped between mu_csf and mu_gm). Use a
                                  positive value (e.g. 0.5-1.0) to be
                                  stricter -- only voxels that look more
                                  unambiguously like pure CSF are flagged,
                                  protecting dim-but-real (e.g. atrophic)
                                  tissue near the old boundary. Negative
                                  values relax it instead. Default: 0.0
                                  (identical to the original boundary).
    --force-apply                 Flag (no value). Apply the correction even
                                  if it exceeds --safety-cap-fraction; status
                                  is still logged as "corrected_over_cap" so
                                  these stay easy to find for QC. Default:
                                  off.
    --log-csv PATH                 Path to append this subject's result row.
                                  Default: <out-labels>_log.csv

EXAMPLE USAGE

  Minimal (no auxiliary GM mask, all other parameters at default):

    python3 correct_hippo_amyg_leakage.py \\
      --t1 subjectX_T1.nii.gz \\
      --labels subjectX_SIAM_labels.nii.gz \\
      --out-labels subjectX_labels_corrected.nii.gz

  With a SynthSeg robust+parc dseg file as the local GM reference, a looser
  safety cap, and forcing the correction through after manual review:

    python3 correct_hippo_amyg_leakage.py \\
      --t1 subjectX_T1.nii.gz \\
      --labels subjectX_SIAM_labels.nii.gz \\
      --out-labels subjectX_labels_corrected.nii.gz \\
      --aux-labels subjectX_synthseg_dseg.nii.gz \\
      --safety-cap-fraction 0.35 \\
      --force-apply

Requires: numpy, scipy, nibabel.
"""

import argparse
import csv
import os

import numpy as np
import nibabel as nib
from scipy.ndimage import (
    binary_dilation,
    generate_binary_structure,
    label as ndimage_label,
)

LABEL_GM = 1
LABEL_CSF = 3
LABEL_CSFV = 4
LABEL_AMYG = 11
LABEL_HIPPO = 12

# Default SynthSeg "robust + parcellation" (Desikan-Killiany) label IDs for
# entorhinal and parahippocampal cortex, left + right hemisphere. These match
# the standard FreeSurferColorLUT numbering used by SynthSeg's --parc output.
DEFAULT_SYNTHSEG_GM_LABELS = (1006, 1016, 2006, 2016)

# SIAM LUT only goes up to 17; anything above this in an auxiliary label
# volume is assumed to be a SynthSeg/Desikan parcellation rather than a
# SIAM-style label volume.
DEFAULT_AUX_DETECT_THRESHOLD = 100


# --------------------------------------------------------------------------
# Geometry helpers
# --------------------------------------------------------------------------

def make_structure(connectivity):
    if connectivity == 6:
        return generate_binary_structure(3, 1)
    elif connectivity == 18:
        return generate_binary_structure(3, 2)
    elif connectivity == 26:
        return generate_binary_structure(3, 3)
    else:
        raise ValueError(f"connectivity must be 6, 18, or 26 (got {connectivity})")


def radius_mm_to_iterations(radius_mm, voxel_size_mm):
    return max(1, int(round(radius_mm / max(voxel_size_mm, 1e-6))))


# --------------------------------------------------------------------------
# Intensity statistics / thresholding
# --------------------------------------------------------------------------

def robust_stats(values):
    """Median and a robust (MAD-scaled) standard-deviation estimate."""
    values = np.asarray(values, dtype=np.float64)
    med = float(np.median(values))
    mad = float(np.median(np.abs(values - med)))
    sigma = mad * 1.4826
    if sigma < 1e-6:
        std = float(np.std(values))
        sigma = std if std > 1e-6 else 1.0
    return med, sigma


def gaussian_decision_boundary(mu_csf, sigma_csf, mu_gm, sigma_gm):
    """Equal-posterior threshold between N(mu_csf, sigma_csf) and
    N(mu_gm, sigma_gm), equal priors. Returns None if no valid root
    lies between the two means."""
    lo, hi = sorted([mu_csf, mu_gm])
    if sigma_csf < 1e-6 or sigma_gm < 1e-6:
        return None

    A = 1.0 / (sigma_gm ** 2) - 1.0 / (sigma_csf ** 2)
    B = 2.0 * (mu_csf / (sigma_csf ** 2) - mu_gm / (sigma_gm ** 2))
    C = (mu_gm ** 2) / (sigma_gm ** 2) - (mu_csf ** 2) / (sigma_csf ** 2) \
        - 2.0 * np.log(sigma_gm / sigma_csf)

    if abs(A) < 1e-9:
        if abs(B) < 1e-12:
            return None
        x = -C / B
        return x if lo <= x <= hi else None

    disc = B ** 2 - 4 * A * C
    if disc < 0:
        return None
    sqrt_disc = np.sqrt(disc)
    roots = [(-B + sqrt_disc) / (2 * A), (-B - sqrt_disc) / (2 * A)]
    candidates = [r for r in roots if lo <= r <= hi]
    if not candidates:
        return None
    mid = (mu_csf + mu_gm) / 2.0
    candidates.sort(key=lambda r: abs(r - mid))
    return float(candidates[0])


def otsu_threshold(values, nbins=256):
    values = np.asarray(values, dtype=np.float64)
    hist, edges = np.histogram(values, bins=nbins)
    hist = hist.astype(np.float64)
    centers = (edges[:-1] + edges[1:]) / 2.0
    w1 = np.cumsum(hist)
    w2 = np.cumsum(hist[::-1])[::-1]
    with np.errstate(divide="ignore", invalid="ignore"):
        m1 = np.cumsum(hist * centers) / w1
        m2 = (np.cumsum((hist * centers)[::-1])[::-1]) / w2
    var_between = w1[:-1] * w2[1:] * (m1[:-1] - m2[1:]) ** 2
    if var_between.size == 0 or np.all(np.isnan(var_between)):
        return float(np.median(values))
    idx = int(np.nanargmax(var_between))
    return float(centers[idx])


def compute_threshold(csf_vals, gm_vals, method="auto"):
    mu_csf, sigma_csf = robust_stats(csf_vals)
    mu_gm, sigma_gm = robust_stats(gm_vals)
    lower_is_csf = mu_csf < mu_gm

    threshold = None
    method_used = method

    if method in ("gaussian", "auto"):
        threshold = gaussian_decision_boundary(mu_csf, sigma_csf, mu_gm, sigma_gm)
        if threshold is not None:
            method_used = "gaussian"
        elif method == "auto":
            method_used = "otsu"

    if threshold is None and method in ("otsu", "auto"):
        combined = np.concatenate([csf_vals, gm_vals])
        candidate = otsu_threshold(combined)
        lo, hi = sorted([mu_csf, mu_gm])
        if lo <= candidate <= hi:
            threshold = candidate
            method_used = "otsu"
        elif method == "otsu":
            threshold = candidate
            method_used = "otsu"

    if threshold is None:
        threshold = (mu_csf + mu_gm) / 2.0
        method_used = "midpoint"

    stats = dict(mu_csf=mu_csf, sigma_csf=sigma_csf, mu_gm=mu_gm, sigma_gm=sigma_gm)
    return threshold, lower_is_csf, method_used, stats


# --------------------------------------------------------------------------
# Auxiliary GM reference (SIAM vs SynthSeg/Desikan auto-detection)
# --------------------------------------------------------------------------

def detect_aux_label_type(aux_data, detect_threshold=DEFAULT_AUX_DETECT_THRESHOLD):
    """Heuristic: SIAM labels max out at 17; Desikan-Killiany cortical
    parcellation labels (as produced by SynthSeg --parc) are >= 1000."""
    return "synthseg" if float(np.max(aux_data)) > detect_threshold else "siam"


def build_local_gm_voxel_mask(aux_path, aux_labels_type, synthseg_gm_labels,
                               detect_threshold=DEFAULT_AUX_DETECT_THRESHOLD):
    aux_data = nib.load(aux_path).get_fdata().astype(np.int32)
    if aux_labels_type == "auto":
        detected_type = detect_aux_label_type(aux_data, detect_threshold)
    else:
        detected_type = aux_labels_type

    if detected_type == "siam":
        mask = aux_data == LABEL_GM
    else:
        mask = np.isin(aux_data, list(synthseg_gm_labels))

    return mask, detected_type


# --------------------------------------------------------------------------
# Reference-mask construction
# --------------------------------------------------------------------------

def build_reference_masks(
    label_data,
    hippo_amyg_mask,
    csf_search_radius_mm,
    gm_search_radius_mm,
    voxel_size_mm,
    structure,
    local_gm_mask=None,
    min_ref_voxels=30,
):
    csfv_mask = label_data == LABEL_CSFV
    csf_mask = label_data == LABEL_CSF
    gm_mask = label_data == LABEL_GM
    seed_csf_mask = csfv_mask | csf_mask

    csf_iters = radius_mm_to_iterations(csf_search_radius_mm, voxel_size_mm)
    dilated = binary_dilation(hippo_amyg_mask, structure=structure, iterations=csf_iters)
    csf_ref_mask = dilated & seed_csf_mask
    csf_fallback_used = False
    if csf_ref_mask.sum() < min_ref_voxels:
        csf_ref_mask = seed_csf_mask.copy()
        csf_fallback_used = True

    gm_fallback_used = False
    if local_gm_mask is not None:
        # The auxiliary mask (SIAM GM label, or SynthSeg parahippocampal/
        # entorhinal labels) is used directly -- it already designates
        # exactly the local GM reference voxels we want, no need to
        # intersect it with the main label volume's own GM label.
        gm_ref_mask = local_gm_mask.copy()
        if gm_ref_mask.sum() < min_ref_voxels:
            gm_iters = radius_mm_to_iterations(gm_search_radius_mm, voxel_size_mm)
            dilated_gm = binary_dilation(hippo_amyg_mask, structure=structure, iterations=gm_iters)
            gm_ref_mask = dilated_gm & gm_mask & (~hippo_amyg_mask)
            gm_fallback_used = True
            if gm_ref_mask.sum() < min_ref_voxels:
                gm_ref_mask = gm_mask.copy()
    else:
        gm_iters = radius_mm_to_iterations(gm_search_radius_mm, voxel_size_mm)
        dilated_gm = binary_dilation(hippo_amyg_mask, structure=structure, iterations=gm_iters)
        gm_ref_mask = dilated_gm & gm_mask & (~hippo_amyg_mask)
        if gm_ref_mask.sum() < min_ref_voxels:
            gm_ref_mask = gm_mask.copy()
            gm_fallback_used = True

    return csf_ref_mask, gm_ref_mask, csf_fallback_used, gm_fallback_used, seed_csf_mask


# --------------------------------------------------------------------------
# Core pipeline
# --------------------------------------------------------------------------

def save_mask_like(mask_array, reference_nii, out_path):
    img = nib.Nifti1Image(mask_array.astype(np.uint8), reference_nii.affine, reference_nii.header)
    img.header.set_data_dtype(np.uint8)
    nib.save(img, out_path)


def correct_subject(
    t1_path,
    label_path,
    out_label_path,
    out_mask_path,
    aux_labels_path=None,
    aux_labels_type="auto",
    synthseg_gm_labels=DEFAULT_SYNTHSEG_GM_LABELS,
    aux_detect_threshold=DEFAULT_AUX_DETECT_THRESHOLD,
    csf_search_radius_mm=15.0,
    gm_search_radius_mm=15.0,
    min_ref_voxels=30,
    epsilon_detect=0.02,
    safety_cap_fraction=0.25,
    connectivity=26,
    threshold_method="auto",
    csf_margin_sigma=0.0,
    force_apply=False,
):
    t1_img = nib.load(t1_path)
    label_nii = nib.load(label_path)
    t1_data = t1_img.get_fdata().astype(np.float32)
    label_data = label_nii.get_fdata().astype(np.int16)
    affine = label_nii.affine
    voxel_size_mm = float(np.mean(nib.affines.voxel_sizes(affine)))

    hippo_amyg_mask = (label_data == LABEL_AMYG) | (label_data == LABEL_HIPPO)
    n_total = int(hippo_amyg_mask.sum())

    if n_total == 0:
        nib.save(label_nii, out_label_path)
        save_mask_like(np.zeros_like(label_data, dtype=np.uint8), label_nii, out_mask_path)
        return dict(status="skipped_no_hippo_amyg_voxels", n_total_hippo_amyg=0)

    structure = make_structure(connectivity)

    local_gm_mask = None
    aux_detected_type = None
    if aux_labels_path:
        local_gm_mask, aux_detected_type = build_local_gm_voxel_mask(
            aux_labels_path, aux_labels_type, synthseg_gm_labels, aux_detect_threshold
        )

    csf_ref_mask, gm_ref_mask, csf_fb, gm_fb, seed_csf_mask = build_reference_masks(
        label_data,
        hippo_amyg_mask,
        csf_search_radius_mm,
        gm_search_radius_mm,
        voxel_size_mm,
        structure,
        local_gm_mask=local_gm_mask,
        min_ref_voxels=min_ref_voxels,
    )

    csf_vals = t1_data[csf_ref_mask]
    gm_vals = t1_data[gm_ref_mask]
    raw_threshold, lower_is_csf, method_used, stats = compute_threshold(
        csf_vals, gm_vals, threshold_method
    )

    # Optional stringency margin: pull the cutoff toward the CSF mean by
    # csf_margin_sigma * sigma_csf, so only voxels that look more
    # unambiguously like pure CSF qualify as candidates -- this protects
    # dim-but-real (e.g. atrophic/degenerated) tissue sitting near the
    # original boundary. Clamped so it can never cross past mu_gm.
    if lower_is_csf:
        threshold = raw_threshold - csf_margin_sigma * stats["sigma_csf"]
        threshold = max(threshold, stats["mu_csf"])
        threshold = min(threshold, stats["mu_gm"])
    else:
        threshold = raw_threshold + csf_margin_sigma * stats["sigma_csf"]
        threshold = min(threshold, stats["mu_csf"])
        threshold = max(threshold, stats["mu_gm"])

    if lower_is_csf:
        candidate_mask = hippo_amyg_mask & (t1_data <= threshold)
    else:
        candidate_mask = hippo_amyg_mask & (t1_data >= threshold)

    n_candidate = int(candidate_mask.sum())
    candidate_fraction = n_candidate / n_total

    result = dict(
        threshold=float(threshold),
        raw_threshold=float(raw_threshold),
        csf_margin_sigma_used=float(csf_margin_sigma),
        threshold_method_used=method_used,
        lower_is_csf=bool(lower_is_csf),
        mu_csf=stats["mu_csf"],
        sigma_csf=stats["sigma_csf"],
        mu_gm=stats["mu_gm"],
        sigma_gm=stats["sigma_gm"],
        n_csf_ref_voxels=int(csf_ref_mask.sum()),
        n_gm_ref_voxels=int(gm_ref_mask.sum()),
        csf_fallback_used=bool(csf_fb),
        gm_fallback_used=bool(gm_fb),
        aux_labels_type_used=aux_detected_type,
        n_total_hippo_amyg=n_total,
        n_candidate=n_candidate,
        candidate_fraction=candidate_fraction,
    )

    if candidate_fraction < epsilon_detect:
        result["status"] = "no_leakage_detected"
        result["n_corrected"] = 0
        result["corrected_fraction"] = 0.0
        result["over_safety_cap"] = False
        nib.save(label_nii, out_label_path)
        save_mask_like(candidate_mask.astype(np.uint8), label_nii, out_mask_path)
        return result

    combined_mask = candidate_mask | seed_csf_mask
    components, n_components = ndimage_label(combined_mask, structure=structure)

    seed_component_ids = set(np.unique(components[seed_csf_mask]).tolist())
    seed_component_ids.discard(0)

    correction_mask = np.zeros_like(candidate_mask)
    if seed_component_ids:
        in_seed_component = np.isin(components, list(seed_component_ids))
        correction_mask = candidate_mask & in_seed_component

    n_corrected = int(correction_mask.sum())
    corrected_fraction = n_corrected / n_total
    over_safety_cap = corrected_fraction > safety_cap_fraction
    result["n_corrected"] = n_corrected
    result["corrected_fraction"] = corrected_fraction
    result["over_safety_cap"] = bool(over_safety_cap)

    save_mask_like(correction_mask.astype(np.uint8), label_nii, out_mask_path)

    if over_safety_cap and not force_apply:
        result["status"] = "flagged_for_review"
        nib.save(label_nii, out_label_path)
        return result

    if n_corrected == 0:
        result["status"] = "no_connected_leak_found"
        nib.save(label_nii, out_label_path)
        return result

    new_label_data = label_data.copy()
    csfv_mask = label_data == LABEL_CSFV
    touches_csfv = np.zeros(n_components + 1, dtype=bool)
    csfv_component_ids = np.unique(components[csfv_mask])
    csfv_component_ids = csfv_component_ids[csfv_component_ids > 0]
    touches_csfv[csfv_component_ids] = True

    correction_component_ids = np.unique(components[correction_mask])
    for cid in correction_component_ids:
        if cid == 0:
            continue
        voxels_in_comp = correction_mask & (components == cid)
        new_label_data[voxels_in_comp] = LABEL_CSFV if touches_csfv[cid] else LABEL_CSF

    result["status"] = "corrected_over_cap" if over_safety_cap else "corrected"
    out_nii = nib.Nifti1Image(new_label_data.astype(np.int16), affine, label_nii.header)
    out_nii.header.set_data_dtype(np.int16)
    nib.save(out_nii, out_label_path)
    return result


# --------------------------------------------------------------------------
# CLI (single subject)
# --------------------------------------------------------------------------

def write_log_csv(rows, path):
    if not rows:
        return
    fieldnames = sorted(set().union(*[set(r.keys()) for r in rows]))
    file_exists = os.path.exists(path)
    with open(path, "a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if not file_exists:
            writer.writeheader()
        for r in rows:
            writer.writerow(r)


def default_mask_path(out_label_path):
    base, ext = os.path.splitext(out_label_path)
    if base.endswith(".nii"):
        base = base[: -len(".nii")]
        ext = ".nii" + ext
    return base + "_leakmask" + ext


def parse_int_list(s):
    return [int(x.strip()) for x in s.split(",") if x.strip()]


def main():
    parser = argparse.ArgumentParser(
        description="Correct CSF leakage in SIAM hippocampus/amygdala labels (single subject)."
    )
    parser.add_argument("--t1", required=True, help="Path to T1w NIfTI")
    parser.add_argument("--labels", required=True, help="Path to SIAM label NIfTI")
    parser.add_argument("--out-labels", required=True, help="Output corrected label NIfTI")
    parser.add_argument("--out-mask", default=None, help="Output candidate/leak mask NIfTI (default derived from --out-labels)")

    parser.add_argument("--aux-labels", default=None,
                         help="Optional auxiliary label volume for the local GM reference: either a "
                              "SIAM-style label volume (uses GM=1), or a SynthSeg robust+parc "
                              "Desikan-Killiany dseg volume (uses entorhinal/parahippocampal labels). "
                              "Type is auto-detected unless --aux-labels-type is set.")
    parser.add_argument("--aux-labels-type", choices=["auto", "siam", "synthseg"], default="auto",
                         help="Force how --aux-labels is interpreted instead of auto-detecting.")
    parser.add_argument("--synthseg-gm-labels", type=parse_int_list, default="1006,1016,2006,2016",
                         help="Comma-separated label IDs to use as the local GM reference when "
                              "--aux-labels is a SynthSeg/Desikan parcellation "
                              "(default: entorhinal + parahippocampal, both hemispheres).")
    parser.add_argument("--aux-detect-threshold", type=float, default=DEFAULT_AUX_DETECT_THRESHOLD,
                         help="Auto-detection cutoff: aux label volumes with max value above this "
                              "are treated as SynthSeg/Desikan rather than SIAM (default: 100).")

    parser.add_argument("--csf-search-radius-mm", type=float, default=15.0)
    parser.add_argument("--gm-search-radius-mm", type=float, default=15.0)
    parser.add_argument("--min-ref-voxels", type=int, default=30)
    parser.add_argument("--epsilon-detect", type=float, default=0.02,
                         help="Min. candidate-CSF fraction of Hippo+Amyg volume needed to trigger correction")
    parser.add_argument("--safety-cap-fraction", type=float, default=0.25,
                         help="Max. fraction of Hippo+Amyg volume allowed to auto-correct before flagging for review")
    parser.add_argument("--connectivity", type=int, choices=[6, 18, 26], default=26)
    parser.add_argument("--threshold-method", choices=["auto", "gaussian", "otsu", "midpoint"], default="auto")
    parser.add_argument("--csf-margin-sigma", type=float, default=0.0,
                         help="Shift the candidate threshold toward the CSF mean by this many "
                              "sigma_csf units (clamped between mu_csf and mu_gm). Use a positive "
                              "value (e.g. 0.5-1.0) to be stricter -- only voxels that look more "
                              "unambiguously like pure CSF are flagged, protecting dim-but-real "
                              "(e.g. atrophic) tissue near the old boundary. Negative values relax "
                              "it instead. Default: 0.0 (no change from the original boundary).")
    parser.add_argument("--force-apply", action="store_true",
                         help="Apply the correction even if it exceeds --safety-cap-fraction "
                              "(e.g. on a case you've already reviewed). Still logged distinctly "
                              "as status=corrected_over_cap so it stays easy to find for QC.")
    parser.add_argument("--log-csv", default=None, help="Path to append this subject's result as a CSV row "
                                                          "(default derived from --out-labels)")

    args = parser.parse_args()

    out_mask_path = args.out_mask or default_mask_path(args.out_labels)
    result = correct_subject(
        args.t1,
        args.labels,
        args.out_labels,
        out_mask_path,
        aux_labels_path=args.aux_labels,
        aux_labels_type=args.aux_labels_type,
        synthseg_gm_labels=args.synthseg_gm_labels,
        aux_detect_threshold=args.aux_detect_threshold,
        csf_search_radius_mm=args.csf_search_radius_mm,
        gm_search_radius_mm=args.gm_search_radius_mm,
        min_ref_voxels=args.min_ref_voxels,
        epsilon_detect=args.epsilon_detect,
        safety_cap_fraction=args.safety_cap_fraction,
        connectivity=args.connectivity,
        threshold_method=args.threshold_method,
        csf_margin_sigma=args.csf_margin_sigma,
        force_apply=args.force_apply,
    )
    result["subject_id"] = os.path.basename(args.labels)

    print(
        f"status={result['status']} "
        f"candidate_fraction={result.get('candidate_fraction', 0):.3f} "
        f"corrected_fraction={result.get('corrected_fraction', 0):.3f} "
        f"over_safety_cap={result.get('over_safety_cap', False)} "
        f"threshold={result.get('threshold')} "
        f"aux_labels_type_used={result.get('aux_labels_type_used')}"
    )

    log_csv = args.log_csv or (os.path.splitext(args.out_labels)[0] + "_log.csv")
    write_log_csv([result], log_csv)
    print(f"Log written to {log_csv}")


if __name__ == "__main__":
    main()
