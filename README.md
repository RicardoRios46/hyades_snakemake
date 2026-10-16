# HYADES MRI Study Neuroimaging Reproducible Processing Pipeline

This repository contains a **Snakemake-based reproducible workflow** for processing the neuroimaging MRI data for the HYADES study, reported in [*"Probing gray matter microstructure differences in neurodegenerative dementia using b-tensor encoding diffusion MRI"*](https://github.com/RicardoRios46/hyades_neurolibre) (preprint on NeuroLibre; DOI to be added). The pipeline automates the processing of BIDS-compliant neuroimaging datasets and generates the data derivatives used for downstream analysis.

## Table of Contents

- [Overview](#overview)
- [Related Repositories](#related-repositories)
- [Pipeline Overview](#pipeline-overview)
- [Repository Structure](#repository-structure)
- [Installation/Requirements](#installationrequirements)
  - [Clone the Repository](#clone-the-repository)
  - [Snakemake Python Environment](#snakemake-python-environment)
    - [Pixi](#pixi)
    - [Conda/Mamba Environment](#condamamba-environment)
  - [Dependencies](#dependencies)
    - [Software Dependencies](#software-dependencies)
    - [MatMRI Submodule](#matmri-submodule)
    - [Containers](#containers)
- [Data Availability and Privacy](#data-availability-and-privacy)
- [Input Raw Data](#input-raw-data)
- [Metadata and Configuration Files](#metadata-and-configuration-files)
  - [Configuration File (`config/config.yml`)](#configuration-file-configconfigyml)
  - [Subjects File](#subjects-file)
  - [Supplemental Metadata](#supplemental-metadata)
- [Running the Pipeline](#running-the-pipeline)
  - [Quick Start](#quick-start)
  - [Snakemake Profile](#snakemake-profile)
  - [Running Individual Stages](#running-individual-stages)
  - [Reusing the Pipeline](#reusing-the-pipeline)
- [Pipeline Outputs](#pipeline-outputs)
- [Reproducibility](#reproducibility)
- [LLM Disclosure](#llm-disclosure)
- [License](#license)
- [Citation](#citation)
- [Contact](#contact)

## Overview

The workflow is implemented in [Snakemake](https://snakemake.readthedocs.io/) and provides a reproducible, automated framework for processing the neuroimaging data collected as part of the HYADES study.

The pipeline takes **BIDS-compliant raw data** as input and produces intermediate and final derivatives, including the tabular data used for downstream statistical analysis and visualization. The workflow is configured through `config/config.yml` and is intended to be run locally.

## Related Repositories

This workflow is part of a set of four linked repositories:

| Repository | Contents | Hosted on |
|---|---|---|
| [HYADES preprint](https://github.com/RicardoRios46/hyades_neurolibre) | Manuscript source, reproducible analysis notebooks, MyST build | GitHub |
| [HYADES tabular data](https://doi.org/10.5281/zenodo.23212234) | CSV/TSV data files with the data required to reproduce the paper | Zenodo |
| HYADES imaging preprocessed data (released on FRDR at journal publication) | Preprocessed, de-identified NIfTI imaging derivatives (brain-extracted anatomicals, preprocessed dMRI, MTS source volumes, segmentations, masks) | FRDR |
| **HYADES processing pipeline** (this repository) | Snakemake workflow that generates the data from raw BIDS MRI data | GitHub |

## Pipeline Overview

### Input Data

The pipeline requires the following BIDS-compliant input data:

- T1-weighted anatomical MRI
- T2-weighted anatomical MRI
- Diffusion MRI with b-tensor encoding, including linear and spherical tensor-encoding images
- MTsat acquisition data
- Reverse phase-encoded (PA) b0 field map (`fmap/`), used by DESIGNER for distortion correction with eddy

FLAIR images may be present in the BIDS dataset but are not used by the pipeline.

> **Note:** Linear and spherical tensor-encoding images are expected to be stored within the same DWI volume. The `volumes_bool.ste` file in `supplemental_metadata/` identifies the different encoding volumes.

### Preprocessing

Diffusion MRI data are preprocessed using the **DESIGNER** pipeline (MP-PCA denoising, Rician bias correction, Gibbs artifact removal, and motion/distortion correction via eddy using the reverse phase-encoded b0 field map).

### Model Fitting

The pipeline generates the following quantitative maps. Metric names below match the final column names documented in the [HYADES tabular data repository](https://doi.org/10.5281/zenodo.23212234):

- **b-tensor encoding metrics:** `uFA`, `D_uFA` (mean diffusivity), `Ka` (anisotropic kurtosis), `Ki` (isotropic kurtosis)
- **Axisymmetric DKI metrics:** `D_dki` (mean diffusivity), `Dpar` (axial diffusivity), `Dperp` (radial diffusivity), `FA`, `Wmean` (mean kurtosis), `Kpar` (axial kurtosis), `Kperp` (radial kurtosis)
- **Orientation coherence:** `Cc`, calculated as (FA)²/(uFA)²
- **MTsat metrics:** `MTsat`, `M0map`, `R1map`

### Registration

All fitted metric maps are registered to the T1-weighted anatomical image, using the T2-weighted image as an intermediate registration space to improve alignment between the diffusion-derived maps and the T1w image.

### Segmentation

The pipeline generates several anatomical segmentations:

- **SynthSeg**
- **SIAM**
- **SIAM–SynthSeg:** a combination of SynthSeg and SIAM segmentations that improves ROI delineation, developed because SynthSeg's cortical parcellation labels showed degraded performance in some regions. The SIAM gray matter is parcellated with the SynthSeg labels, and ROI volumes are normalized by the total intracranial volume (TIV) from SynthSeg, so this segmentation depends on the SynthSeg outputs.

The pipeline also uses **HippUnfold v2.2.0** (`ADNI_T1w_v1` model) to segment and unfold the hippocampus. HippUnfold-derived surface-space representations and metrics are included as outputs.

### Dataframe Creation

Derived metrics are averaged at the ROI level and organized into analysis-ready CSV dataframes based on the **SIAM/SynthSeg**, and **HippUnfold** segmentations.

## Repository Structure

```text
.
├── config/
│   ├── config.yml
│   └── subjects_example.yml
├── data/
├── derivatives/
├── resources/
│   ├── containers/
│   └── matmri/
├── supplemental_metadata/
├── workflow/
│   ├── envs/
│   ├── profiles/
│   │   └── default/
│   │       └── config.yaml
│   ├── rules/
│   └── scripts/
├── pixi.toml
├── environment.yml
└── README.md
```

---

## Installation/Requirements

### Clone the Repository

```bash
git clone https://github.com/RicardoRios46/hyades_snakemake.git
cd hyades_snakemake
```

### Snakemake Python Environment

The workflow was tested with Python 3.13.15 and Snakemake 9.21.1 (the versions in `pixi.lock`). You can set up a matching environment using either Pixi or Conda/Mamba.

#### Pixi

[Pixi](https://pixi.sh/) is the recommended way to install the pipeline environment. The repository's `pixi.toml` file specifies the required Python environment, Snakemake, and script dependencies.

Initialize the environment:

```bash
pixi install
```

Enter the environment:

```bash
pixi shell
```

Alternatively, run commands directly through Pixi without entering a shell:

```bash
pixi run snakemake --help
```

#### Conda/Mamba Environment

If Pixi is unavailable, use the `environment.yml` file to create a Conda or Mamba environment:

```bash
conda env create -f environment.yml
conda activate hyades_mri
```

If Mamba is available (e.g., via a Miniforge installation), replace `conda` with `mamba` above. The environment name `hyades_mri` is the one defined in `environment.yml`.

### Dependencies

#### Software Dependencies

The following dependencies are required. The versions listed are those used for the analysis associated with this repository.

| Software | Version |
|---|---:|
| ANTs | 2.6.5 |
| MRtrix3 | 3.0.8 |
| ITK-SNAP | 4.4.0 |
| QUIT | 3.4 |
| FreeSurfer | 8.1.0 |
| MATLAB | R2026a |
| Connectome Workbench | 2.1.0 |
| Apptainer | 1.5.3 |

DESIGNER, SIAM and HippUnfold run in containers with their own software (see [Containers](#containers)).

**ITK-SNAP note:** ITK-SNAP provides the `c3d` and `greedy` binaries required by parts of the workflow.

The installation method for these dependencies may vary by workstation or computing environment.

##### Software Modules

The pipeline also supports environments that provide software via **environment modules** (e.g., Lmod). If your system uses modules, list the appropriate module names in the Snakemake configuration file, for example:

```yaml
ants: "ants/2.6.5"
mrtrix: "mrtrix/3.0.8"
freesurfer: "freesurfer/8.1.0"
itksnap: "itksnap/4.4.0"
matlab: "matlab/R2026a"
quit: "quit/3.4"
connectome-workbench: "connectome-workbench/v2.1.0"
```

> **Important:** Module names are system-dependent — update these entries to match the modules available on your system.

> **Note:** Changing a module version after a run makes Snakemake rerun the rules that load it ("software environment changed"). If you know the existing outputs are still valid, `snakemake --configfile config/subjects.yml --touch` records the new versions without recomputing them.

Environment modules are enabled by default in the [Snakemake profile](#snakemake-profile) (`env-modules` under `software-deployment-method`).

If your system does not provide environment modules, remove `env-modules` from the profile and make sure the required binaries are available on your `PATH`. You can check this with, for example:

```bash
which antsRegistration
which mrconvert
which mri_synthseg 
which matlab
which apptainer
```

#### MatMRI Submodule

**MatMRI v0.1.17** is included as a Git submodule. After cloning the repository, initialize it with:

```bash
git submodule update --init --recursive
```

Verify that MatMRI is available:

```bash
ls resources/matmri/
```

If submodules cannot be used in your environment, download MatMRI manually and place it in `resources/matmri/`.

#### Containers

The pipeline uses the following containers, expected by default in `resources/containers/`:

```text
resources/
└── containers/
    ├── designer2_v2.0.04.sif
    ├── hippunfold-v2.2.0.sif
    └── siam_v0.32.sif
```

| Config key | Local file (default) | Container image |
|---|---|---|
| `designer_container` | `resources/containers/designer2_v2.0.04.sif` | `docker://nyudiffusionmri/designer2:v2.0.4` |
| `hippunfoldV2_container` | `resources/containers/hippunfold-v2.2.0.sif` | `docker://khanlab/hippunfold:2.2.0` |
| `SIAM_container` | `resources/containers/siam_v0.32.sif` | `docker://romainvalabregue/siam:v0.32` |

To create the local `.sif` files, pull each image with Apptainer, for example:

```bash
apptainer pull resources/containers/siam_v0.32.sif docker://romainvalabregue/siam:v0.32
```

Snakemake can also manage these containers directly. To do so, uncomment the relevant `docker://` container definitions and comment out the local paths in the configuration file, for example:

```text
SIAM_container: 'resources/containers/siam_v0.32.sif'
#SIAM_container: "docker://romainvalabregue/siam:v0.32"
```

---

## Data Availability and Privacy

Due to the ethical agreements governing the HYADES study, identifiable raw neuroimaging data (`data/`) are not openly available.

De-identified derivatives that can be shared at earlier pipeline stages, such as brain-masked and preprocessed images, will be published in the HYADES imaging preprocessed data repository (released on FRDR at journal publication). The final, analysis-ready CSV/TSV dataframes produced by this pipeline (see [Pipeline Outputs](#pipeline-outputs)) are published separately in the [HYADES tabular data repository](https://doi.org/10.5281/zenodo.23212234).

## Input Raw Data

Raw neuroimaging data should be placed in `data/`, following the **BIDS specification**:

```text
data/
├── dataset_description.json
├── participants.tsv
├── sub-001/
│   ├── anat
│   │   ├── sub-001_run-01_FLAIR.json
│   │   ├── sub-001_run-01_FLAIR.nii.gz
│   │   ├── sub-001_run-01_T1w.json
│   │   ├── sub-001_run-01_T1w.nii.gz
│   │   ├── sub-001_run-01_T2w.json
│   │   ├── sub-001_run-01_T2w.nii.gz
│   │   ├── sub-001_run-01_flip-1_mt-off_MTS.json
│   │   ├── sub-001_run-01_flip-1_mt-off_MTS.nii.gz
│   │   ├── sub-001_run-01_flip-1_mt-on_MTS.json
│   │   ├── sub-001_run-01_flip-1_mt-on_MTS.nii.gz
│   │   ├── sub-001_run-01_flip-2_mt-off_MTS.json
│   │   └── sub-001_run-01_flip-2_mt-off_MTS.nii.gz
│   ├── dwi
│   │   ├── sub-001_acq-mde_dir-AP_run-01_dwi.bval
│   │   ├── sub-001_acq-mde_dir-AP_run-01_dwi.bvec
│   │   ├── sub-001_acq-mde_dir-AP_run-01_dwi.json
│   │   └── sub-001_acq-mde_dir-AP_run-01_dwi.nii.gz
│   ├── fmap
│   │   ├── sub-001_dir-PA_run-01_epi.json
│   │   └── sub-001_dir-PA_run-01_epi.nii.gz
│   └── sub-001_scans.tsv
├── sub-002/
│   ├── anat/
│   ├── dwi/
│   ├── fmap/
│   └── sub-002_scans.tsv
└── ...
```

---

## Metadata and Configuration Files

### Configuration File (`config/config.yml`)

This file contains the main pipeline configuration: software modules, container paths, the tensor-encoding volume indices (`lte_index`, `ste_index`, `lte_index_postDesigner`), and other dataset-specific settings. It also contains example `subjects` and `subjects_onlyDWI` lists; list your own subjects in a separate subjects file instead (see [Subjects File](#subjects-file)).

**Acquisition parameters:** the DESIGNER preprocessing settings are dataset-specific and must match your acquisition (HYADES values shown):

| Key | Meaning | HYADES value |
|---|---|---|
| `designer_pf` | Partial Fourier factor of the DWI (DESIGNER `-pf`, used for Gibbs removal) | `0.75` |
| `designer_echo_time` | DWI echo time in ms, same for linear and spherical encoding (`-echo_time`) | `90` |
| `designer_echo_time_rpe` | Echo time of the reverse phase-encoded b0 in ms (`-rpe_te`) | `90` |
| `designer_pe_dir` | Phase-encoding direction of the DWI (`-pe_dir`) | `'AP'` |

The MTsat sequence parameters are set in `supplemental_metadata/MTsat_metadata.json`, and the linear/spherical tensor-encoding volumes in `supplemental_metadata/volumes_bool*.ste` and the index keys above (see [Supplemental Metadata](#supplemental-metadata)).

**Software:** make sure all dependencies listed under [Software Dependencies](#software-dependencies) are available, and that the correct module versions are specified in the config file if environment modules are used.

### Subjects File

The subjects to process are listed in a small YAML file passed on the command line. Its lists replace the example lists in `config/config.yml`, so `config.yml` never needs to contain participant IDs. Start from the example file:

```bash
cp config/subjects_example.yml config/subjects.yml
```

```yaml
subjects:          # full protocol (dMRI, MTS, T1w, T2w)
  - '001'
  - '002'
  - '003'
subjects_onlyDWI:  # no MTS data (MTsat outputs are skipped)
  - '004'
```

- Use the BIDS subject labels **without** the `sub-` prefix (`'001'` for `data/sub-001/`), in quotes so YAML keeps them as text.
- `subjects`: subjects with the full protocol. `subjects_onlyDWI`: subjects without MTS data; they are processed the same way, but the MTsat outputs are skipped. Use an empty list (`subjects_onlyDWI: []`) if none apply.
- Every listed subject must have its BIDS data under `data/` (see [Input Raw Data](#input-raw-data)).

Pass the file with `--configfile` every time you run the pipeline (see [Quick Start](#quick-start)):

```bash
snakemake --configfile config/subjects.yml
```

### Supplemental Metadata

The following files, stored in `supplemental_metadata/`, are required by different stages of the workflow and should be treated as part of the pipeline configuration:

| File | Purpose |
|---|---|
| `brain_parcellation_labels.csv` | Label mapping for SynthSeg processing steps |
| `brain_parcellation_SIAM_labels.csv` | Label mapping for SIAM-related processing steps |
| `dseg2rois_config.json` | Defines how SynthSeg labels are converted into pipeline ROIs (see default below) |
| `brain_parcellation_ROIs_labels.csv` | Label mapping for the ROIs created by `dseg2rois.py`, used in downstream analysis |
| `MTsat_metadata.json` | Metadata and parameters for MTsat processing with QUIT (see default below) |
| `volumes_bool.ste` | Identifies spherical tensor volumes in the dMRI dataset |
| `volumes_bool_postDesigner.ste` | Identifies spherical tensor volumes after the Designer processing stage |

Default `dseg2rois_config.json`:

```json
{
  "Parietal": [1008, 1025, 1029, 1031, 2008, 2025, 2029, 2031],
  "Frontal": [1003, 1012, 1014, 1018, 1019, 1020, 1027, 1028, 1032, 2003, 2012, 2014, 2018, 2019, 2020, 2027, 2028, 2032],
  "Temporal": [1001, 1007, 1009, 1015, 1030, 1033, 1034, 2001, 2007, 2009, 2015, 2030, 2033, 2034],
  "Occipital": [1005, 1011, 1013, 1021, 2005, 2011, 2013, 2021],
  "Cingulate": [1002, 1010, 1023, 1026, 2002, 2010, 2023, 2026],
  "Insula": [1035, 2035],
  "Hippocampus": [17, 53],
  "Amygdala": [18, 54]
}
```

Default `MTsat_metadata.json` (HYADES dataset):

```json
{
  "MTSat": {
    "TR_PDw": 0.036,
    "TR_T1w": 0.012,
    "TR_MTw": 0.036,
    "FA_PDw": 10,
    "FA_T1w": 20,
    "FA_MTw": 10
  }
}
```

> **Known limitation:** The linear and spherical tensor-encoding volume indices are set manually in `config/config.yml` (`lte_index`, `ste_index`, `lte_index_postDesigner`) and must be updated for a different dataset. A future version will compute them from `volumes_bool.ste`.

---

## Running the Pipeline

### Quick Start

After installing the environment and preparing the input data, enter the Pixi environment:

```bash
pixi shell
```

Run the complete pipeline with your [subjects file](#subjects-file). The default [Snakemake profile](#snakemake-profile) is loaded automatically:

```bash
snakemake --configfile config/subjects.yml
```

Before a full run, you can do a dry run to see which jobs would be executed:

```bash
snakemake --configfile config/subjects.yml --dry-run
```

> **Important:** Make sure the subjects file matches the BIDS data available under `data/`. Without `--configfile`, the pipeline uses the example subjects in `config/config.yml`.

### Snakemake Profile

The repository includes a default Snakemake profile at `workflow/profiles/default/config.yaml`. Snakemake (v8+) loads it automatically, so the options below apply to every `snakemake` call without having to type them:

```yaml
cores: all
software-deployment-method:
  - apptainer
  - conda
  - env-modules
apptainer-args: "--nv --bind $PWD:$PWD"
conda-prefix: "$HOME/hyades_workdir/hyades_envs"
apptainer-prefix: "$HOME/hyades_workdir/apptainer_images"
shadow-prefix: /tmp
retries: 3
```

| Option | What it does |
|---|---|
| `cores: all` | Uses all available CPU cores |
| `software-deployment-method` | Enables containerized steps (`apptainer`), rule-specific Conda environments from `workflow/envs/` (`conda`), and environment modules (`env-modules`) |
| `apptainer-args` | Extra arguments passed to Apptainer: `--nv` enables NVIDIA GPU access, and `--bind $PWD:$PWD` makes the working directory visible inside the containers |
| `conda-prefix` | Where Snakemake creates and reuses the Conda environments, so they are built only once |
| `apptainer-prefix` | Where Snakemake stores the container images it pulls (e.g. `docker://` containers) |
| `shadow-prefix` | Directory used for the temporary "shadow" working directories of rules that use `shadow:` |
| `retries` | Number of times a failed job is retried before the workflow stops |

#### Adapting the profile

You can edit `workflow/profiles/default/config.yaml` directly, or override any of its options on the command line. Command-line options take precedence over the profile. To keep your own settings separate, copy the profile to a new directory and select it explicitly, e.g. `snakemake --profile profiles/my_system`. Some common changes:

- **Limit the number of cores** (e.g. on a shared workstation):

  ```bash
  snakemake --cores 8
  ```

  or set `cores: 8` in the profile.

- **No GPU available:** remove `--nv` from `apptainer-args`:

  ```yaml
  apptainer-args: "--bind $PWD:$PWD"
  ```

- **No environment modules on your system:** remove `env-modules` from `software-deployment-method` and make sure the required binaries are on your `PATH` (see [Software Modules](#software-modules)):

  ```yaml
  software-deployment-method:
    - apptainer
    - conda
  ```

- **Store environments and containers elsewhere** (e.g. a larger disk or a shared lab directory):

  ```yaml
  conda-prefix: "/data/shared/hyades_envs"
  apptainer-prefix: "/data/shared/apptainer_images"
  ```

- **Debugging a failing rule:** disable retries so the error appears immediately:

  ```bash
  snakemake --retries 0
  ```

> **Note:** If `/tmp` is small on your system, point `shadow-prefix` to a directory with more free space.

### Running Individual Stages

The default target (`all`) runs every stage except `data_repository`. Each stage can also be run on its own by naming it as the target; a stage also builds whatever outputs of earlier stages it needs. For example:

```bash
snakemake --configfile config/subjects.yml fitting
```

| Stage | What it produces |
|---|---|
| `preproc` | DESIGNER preprocessing |
| `fitting` | uFA, DKI, Cc and MTsat fits |
| `registration` | Fitted maps registered to the T1w image |
| `hippunfold` | HippUnfold segmentation, metric projections to the hippocampal surface, and the HippUnfold dataframes |
| `segmentation_synthseg` | Whole-brain SynthSeg segmentation and dataframes |
| `segmentation_ROIs` | Hybrid SIAM–SynthSeg ROI segmentation and dataframes (needs the SynthSeg outputs) |
| `data_repository` | Public imaging derivatives in `derivatives/data_repository/` (**not** part of `all`) |

### Reusing the Pipeline

To reuse this pipeline with another dataset, make sure that:

1. Subjects are listed in a [subjects file](#subjects-file) passed with `--configfile`.
2. Corresponding BIDS-compliant data are present under `data/`.
3. Required metadata and configuration files are available.
4. Required software dependencies are accessible.
5. Apptainer/Singularity is installed and available.
6. Required containers are available in `resources/containers/`, or Snakemake container management is enabled.
7. The dataset-specific acquisition settings are updated for your data: the DESIGNER keys (`designer_pf`, `designer_echo_time`, `designer_echo_time_rpe`, `designer_pe_dir`; see [Configuration File](#configuration-file-configconfigyml)), the MTsat parameters in `supplemental_metadata/MTsat_metadata.json`, and the linear/spherical tensor-encoding volumes (`volumes_bool*.ste` and the `lte_index`, `ste_index`, `lte_index_postDesigner` keys; see the known limitation under [Supplemental Metadata](#supplemental-metadata)).
8. The [Snakemake profile](#snakemake-profile) is adapted to your system (cores, GPU, environment modules, storage paths).

---

## Pipeline Outputs

The pipeline produces several intermediate and final derivatives:

```text
derivatives/
├── Cc-fit
├── DKI-fit
├── MTsat-fit
├── SIAM
├── data_repository        # only with the data_repository target
├── dataframes
├── designer-v2-preproc
├── designer-v2-preproc-lte
├── hippunfold_AD
├── hippunfold_AD_metrics
├── registration
├── synthseg
└── uFA-fit
```

The primary outputs used for the reproducible analyses in this project are the **CSV dataframes** in `derivatives/dataframes/`, which contain ROI-level subject data for downstream analysis and visualization:

```text
derivatives/dataframes/
├── brain_segmentation
│   ├── hyades_wholeBrain.csv
│   ├── sub-...
│   └── synthseg_qc.csv
├── brain_segmentation_ROIs
│   ├── hyades_wholeBrain_ROIs.csv
│   └── sub-...
└── hippunfoldAD_segmentation
    ├── hyades_hippunfoldAD_surfmetrics.csv
    ├── hyades_hippunfoldAD_surfmetrics_vertex.csv
    ├── hyades_hippunfoldAD_volumes.tsv
    ├── hyades_hippunfoldAD_volumes_normalized.tsv
    └── sub-...
```

Of these, the dataframes actually used in the reproducible analysis accompanying the publication — and published in the [HYADES tabular data repository](https://doi.org/10.5281/zenodo.23212234) — are:

| File | Description |
|---|---|
| `hyades_wholeBrain_ROIs.csv` | ROIs segmentation data for all qMRI metrics |
| `hyades_hippunfoldAD_surfmetrics.csv` | HippUnfold surface metrics for all qMRI metrics, averaged per participant, hemisphere and subfield (`n_vertices` = number of surface vertices averaged); computed from the per-vertex `hyades_hippunfoldAD_surfmetrics_vertex.csv` |
| `hyades_hippunfoldAD_volumes_normalized.tsv` | HippUnfold subfield normalized volume data |

The remaining intermediate dataframes shown above (including the per-vertex `hyades_hippunfoldAD_surfmetrics_vertex.csv`) are not used in the final analysis and are not published. `exclusion_list.csv`, distributed alongside the published files, is curated manually and is not a pipeline output.

Besides these CSV/TSV dataframes, this pipeline also produces the underlying imaging-level derivatives (brain-extracted volumes, preprocessed dMRI, segmentations, masks), which will be published separately in the HYADES imaging preprocessed data repository (released on FRDR at journal publication).

---

## Reproducibility

Reproducibility is supported through:

- Version-controlled Snakemake workflow definitions and configuration files
- Explicit software versions
- Pixi (`pixi.toml`) and Conda/Mamba (`environment.yml`) environment definitions
- Containerized processing steps
- A Snakemake profile with the run options used for the analysis
- The MatMRI Git submodule
- BIDS-compliant input data
- Explicit subject lists and metadata files
- Machine-readable final outputs in `derivatives/dataframes/`

When reproducing the analysis, use the software versions specified in this README and pinned in the corresponding environment and configuration files.

---

## LLM Disclosure

Large language models (LLMs) were used to assist with the development, refactoring, documentation, and/or debugging of selected scripts and functions within the pipeline. All generated or suggested code was reviewed, tested, and adapted by the authors before being incorporated into the workflow. Scripts where LLMs were used are flagged accordingly.

---

## License

This project is released under the MIT License. See [`LICENSE`](LICENSE) for the complete license text.

---

## Citation

If you use this workflow, please cite:

```bibtex
@misc{rioscarrillo_hyades_2026,
  title  = {Probing gray matter microstructure differences in neurodegenerative dementia using b-tensor encoding diffusion {MRI}},
  author = {Rios-Carrillo, Ricardo and Malik, Rubina and So, Isis and Moon, Kyeongrim and Khan, Ali R. and Finger, Elizabeth and Baron, Corey A.},
  year   = {2026},
  note   = {Preprint on NeuroLibre; DOI to be added},
  url    = {https://github.com/RicardoRios46/hyades_neurolibre},
}
```

---

## Contact

For questions, issues, or suggestions, please open an issue or contact:

**Ricardo Rios-Carrillo**
Western University
rrioscar@uwo.ca
