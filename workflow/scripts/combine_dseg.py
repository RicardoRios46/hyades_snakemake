# LLM disclosure: Claude Code (Anthropic) assisted with the development of this
# script. The code was reviewed, tested, and adapted by the authors.
import os
import warnings
from typing import Iterable, Mapping, Sequence, Union, Any
import argparse
import json
import ast

import nibabel as nib
import numpy as np


def _parse_groups_arg(arg: str) -> Any:
    # arg can be a path to a file containing JSON or Python literal,
    # or a JSON/Python literal string on the command line.
    if os.path.exists(arg):
        with open(arg, "r") as fh:
            txt = fh.read()
    else:
        txt = arg
    try:
        return json.loads(txt)
    except Exception:
        return ast.literal_eval(txt)


def _dtype_from_str(s: str):
    if s is None:
        return None
    s = s.lower()
    mapping = {"int8": np.int8, "int16": np.int16, "int32": np.int32, "int64": np.int64}
    return mapping.get(s, np.dtype(s))


def _build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Combine labels in a dseg NIfTI")
    p.add_argument("dseg", help="Path to input dseg NIfTI")
    p.add_argument("--groups", "-g", required=True,
                   help="Groups mapping. JSON or Python literal. Examples: "
                        "'[[1,2,3],[4,5]]' (unnamed list), "
                        "'{1:[1,2,3],2:[4,5]}' (int-keyed dict), or "
                        "'{\"Region A\":[1,2,3],\"Region B\":[4,5]}' (named dict). "
                        "Can also be a path to a file containing any of the above.")
    p.add_argument("--output", "-o", help="Output NIfTI path (optional).")
    p.add_argument("--start-label", type=int, default=1, help="Start label when groups is a sequence or named dict.")
    p.add_argument("--preserve-zero", dest="preserve_zero", action="store_true", default=True,
                   help="Preserve original zeros (default).")
    p.add_argument("--no-preserve-zero", dest="preserve_zero", action="store_false",
                   help="Do not preserve original zeros.")
    p.add_argument("--out-dtype", help="Output dtype name, e.g. int8,int16,int32. If omitted inferred automatically.")
    p.add_argument("--legend-out", help="Optional path to save the name->label legend as JSON "
                                         "(only meaningful when groups uses string names). "
                                         "Only written if this argument is provided; --output "
                                         "only saves the NIfTI.")
    return p


def _cli() -> Any:
    parser = _build_arg_parser()
    args = parser.parse_args()

    groups = _parse_groups_arg(args.groups)
    out_dtype = _dtype_from_str(args.out_dtype)

    result, legend = combine_dseg_labels(
        args.dseg,
        groups,
        output_path=args.output,
        start_label=args.start_label,
        preserve_zero=args.preserve_zero,
        out_dtype=out_dtype,
    )

    if args.output:
        print(f"Saved combined dseg to {args.output}")
    else:
        print("Combined labels (no output file).")

    if legend is not None:
        if args.legend_out:
            with open(args.legend_out, "w") as fh:
                json.dump(legend, fh, indent=2)
            print(f"Saved label legend to {args.legend_out}")
        else:
            print(f"Label legend: {legend}")

    return result


# Note: do not call _cli() here directly; the code above will trigger it when executing the script.
def combine_dseg_labels(
    dseg_input: Union[str, nib.Nifti1Image],
    groups: Union[Sequence[Iterable[int]], Mapping[Any, Iterable[int]]],
    output_path: str = None,
    start_label: int = 1,
    preserve_zero: bool = True,
    out_dtype: np.dtype = None,
):
    """
    Combine label values in a dseg (label) NIfTI into fewer ROI labels.

    Parameters
    - dseg_input: path to dseg NIfTI file or a nibabel Nifti1Image.
    - groups: one of
        * a sequence (list/tuple) of iterables of integers, e.g. [[1,2,3],[4,5]]
          Each inner group becomes a single ROI with label start_label + index.
        * a mapping with integer (or integer-like) keys, e.g. {1: [1,2,3], 2: [4,5]}
          Keys are used directly as the new labels.
        * a mapping with string keys (names), e.g. {"Frontal": [1,2,3], "Parietal": [4,5]}
          New integer labels are auto-assigned in order starting at start_label,
          and a name->label legend is returned/saved.
    - output_path: optional path to save the resulting NIfTI. If None the file is not saved.
    - start_label: used when `groups` is a sequence or a named (string-keyed) mapping.
    - preserve_zero: if True, voxels with original label 0 remain 0 in output.
    - out_dtype: numpy dtype for output volume. If None, chosen based on max label.

    Returns
    - (nib.Nifti1Image, legend_or_None)
      legend_or_None is a dict {name: new_label} when groups had string keys, else None.
    """
    # Load image
    if isinstance(dseg_input, str):
        img = nib.load(dseg_input)
    elif isinstance(dseg_input, nib.Nifti1Image):
        img = dseg_input
    else:
        raise TypeError("dseg_input must be a file path or a nibabel Nifti1Image")

    data = img.get_fdata(dtype=np.float32).astype(np.int32)

    # Build mapping: original_label -> new_label
    mapping = {}
    legend = None  # name -> new_label, only populated for named (string-keyed) input

    def _is_intlike(x):
        try:
            int(x)
            return True
        except (TypeError, ValueError):
            return False

    if isinstance(groups, Mapping):
        keys = list(groups.keys())
        named = len(keys) > 0 and not all(_is_intlike(k) for k in keys)

        if named:
            # String-keyed dict: auto-assign integer labels, build legend
            legend = {}
            for idx, (name, originals) in enumerate(groups.items()):
                new_label = int(start_label + idx)
                legend[name] = new_label
                for lab in originals:
                    lab = int(lab)
                    if lab in mapping:
                        warnings.warn(f"Original label {lab} already mapped to {mapping[lab]}; keeping first mapping.")
                        continue
                    mapping[lab] = new_label
        else:
            # Int-keyed dict: keys are the new labels directly (original behavior)
            for new_label, originals in groups.items():
                for lab in originals:
                    lab = int(lab)
                    if lab in mapping:
                        warnings.warn(f"Original label {lab} already mapped to {mapping[lab]}; keeping first mapping.")
                        continue
                    mapping[lab] = int(new_label)
    else:
        # sequence of groups (original behavior)
        for idx, grp in enumerate(groups):
            new_label = int(start_label + idx)
            for lab in grp:
                lab = int(lab)
                if lab in mapping:
                    warnings.warn(f"Original label {lab} already mapped to {mapping[lab]}; keeping first mapping.")
                    continue
                mapping[lab] = new_label

    # Determine output dtype
    max_new = max(mapping.values()) if mapping else 0
    reserve = 1 if preserve_zero else 0
    needed_max = max(max_new, reserve)
    if out_dtype is None:
        if needed_max <= np.iinfo(np.uint8).max:
            out_dtype = np.uint8
        elif needed_max <= np.iinfo(np.uint16).max:
            out_dtype = np.uint16
        else:
            out_dtype = np.int32

    out = np.zeros(data.shape, dtype=out_dtype)

    # Optionally preserve zeros (already zero)
    # Apply mappings
    for orig_label, new_label in mapping.items():
        if orig_label == 0 and preserve_zero:
            continue
        out[data == orig_label] = new_label

    # Create new image preserving affine and (most of) header info
    new_header = img.header.copy()
    new_img = nib.Nifti1Image(out, img.affine, header=new_header)
    # Update dtype on the header itself (not just the image wrapper)
    new_img.header.set_data_dtype(out_dtype)
    # Reset scaling/calibration fields inherited from the source header.
    # Leftover scl_slope/scl_inter (e.g. from a float source image) combined
    # with an integer datatype can make strict readers like freeview refuse
    # to open the file (e.g. "unsupported datatype ... with scl_slope = 0").
    new_img.header['scl_slope'] = 1.0
    new_img.header['scl_inter'] = 0.0
    new_img.header['cal_min'] = 0
    new_img.header['cal_max'] = 0
    new_img.update_header()

    if output_path:
        out_dir = os.path.dirname(output_path)
        if out_dir and not os.path.exists(out_dir):
            os.makedirs(out_dir, exist_ok=True)
        nib.save(new_img, output_path)

    return new_img, legend


if __name__ == "__main__":
    _cli()


# Example usage:
# if __name__ == "__main__":
#     # Unnamed list -> labels 1, 2 in order
#     img, legend = combine_dseg_labels("dseg.nii.gz", [[1, 2, 3], [4, 5]], output_path="combined.nii.gz")
#
#     # Named dict -> auto-assigned labels + legend dict returned
#     groups = {"Frontal": [1, 2, 3], "Parietal": [4, 5]}
#     img, legend = combine_dseg_labels("dseg.nii.gz", groups, output_path="combined.nii.gz")
#     print(legend)  # {"Frontal": 1, "Parietal": 2}

# From terminal: (check README.md)
# python3 combine_dseg.py \
#  /pathToFile/dseg.nii.gz \
#  -g '{"Hippocampus": [17, 53]}' \
#  -o /pathToOut/ROI.nii.gz
#  # only ROI.nii.gz is saved; legend is printed to console
#
# Add --legend-out to also save the name->label legend as JSON:
# python3 combine_dseg.py \
#  /pathToFile/dseg.nii.gz \
#  -g '{"Hippocampus": [17, 53]}' \
#  -o /pathToOut/ROI.nii.gz \
#  --legend-out /pathToOut/ROI_legend.json