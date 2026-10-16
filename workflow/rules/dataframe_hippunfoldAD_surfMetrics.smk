rule subject_hippunfoldAD_surfMetrics_dataframe:
    input:
        # uFA inputs
        uFA = "derivatives/hippunfold_AD_metrics/uFA/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_uFA.shape.gii",
        D = "derivatives/hippunfold_AD_metrics/uFA/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_D.shape.gii",
        Kiso = "derivatives/hippunfold_AD_metrics/uFA/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_Kiso.shape.gii",
        Kaniso = "derivatives/hippunfold_AD_metrics/uFA/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_Kaniso.shape.gii",
        # DKI inputs
        Dmean = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Dmean.shape.gii",
        Dpar = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Dpar.shape.gii",
        Dperp = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Dperp.shape.gii",
        FA = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_FA.shape.gii",
        Kpar = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Kpar.shape.gii",
        Kperp = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Kperp.shape.gii",
        Wmean = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Wmean.shape.gii",

        # uFA-DKI inputs
        Cc = "derivatives/hippunfold_AD_metrics/Cc/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Cc.shape.gii",
        # MTsat inputs.
        MTsat = "derivatives/hippunfold_AD_metrics/MTsat/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_MTsat.shape.gii",
        R1 = "derivatives/hippunfold_AD_metrics/MTsat/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_R1map.shape.gii",
        M0 = "derivatives/hippunfold_AD_metrics/MTsat/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_M0map.shape.gii",

        # Hippunfold segmentation inputs
        thickness = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-{label}_thickness.shape.gii',
        curvature = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-{label}_curvature.shape.gii',
        gyrification = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-{label}_gyrification.shape.gii',
        subfields_label = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-{label}_atlas-multihist7_subfields.label.gii',
    params:
        # participants list
        participants = 'data/participants.tsv',
    output:
        "derivatives/dataframes/hippunfoldAD_segmentation/sub-{subject}/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_hippunfold-surfmetrics.csv"
    conda:
        #"hyades_dataframe"
       "../envs/pipeline_env.yml"
    threads:  workflow.cores/2
    script:
        "../scripts/subject_hippunfold_surf_metrics.py"


rule subject_hippunfoldAD_surfMetrics_onlyDWI_dataframe:
    input:
        # uFA inputs
        uFA = "derivatives/hippunfold_AD_metrics/uFA/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_uFA.shape.gii",
        D = "derivatives/hippunfold_AD_metrics/uFA/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_D.shape.gii",
        Kiso = "derivatives/hippunfold_AD_metrics/uFA/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_Kiso.shape.gii",
        Kaniso = "derivatives/hippunfold_AD_metrics/uFA/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_Kaniso.shape.gii",
        # DKI inputs
        Dmean = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Dmean.shape.gii",
        Dpar = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Dpar.shape.gii",
        Dperp = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Dperp.shape.gii",
        FA = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_FA.shape.gii",
        Kpar = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Kpar.shape.gii",
        Kperp = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Kperp.shape.gii",
        Wmean = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Wmean.shape.gii",

        # uFA-DKI inputs
        Cc = "derivatives/hippunfold_AD_metrics/Cc/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Cc.shape.gii",

        # Hippunfold segmentation inputs
        thickness = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-{label}_thickness.shape.gii',
        curvature = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-{label}_curvature.shape.gii',
        gyrification = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-{label}_gyrification.shape.gii',
        subfields_label = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-{label}_atlas-multihist7_subfields.label.gii',
    params:
        # participants list
        participants = 'data/participants.tsv',
    output:
        "derivatives/dataframes/hippunfoldAD_segmentation/sub-{subject}/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_hippunfold-surfmetrics_onlyDWI.csv"
    conda:
        #"hyades_dataframe"
       "../envs/pipeline_env.yml"
    threads:  workflow.cores/2
    script:
        "../scripts/subject_hippunfold_surf_metrics_onlyDWI.py"

rule concatenate_hippunfoldAD_surfMetrics_dataframes:
    input:
        expand(
            "derivatives/dataframes/hippunfoldAD_segmentation/sub-{subject}/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_hippunfold-surfmetrics.csv",
            subject=config['subjects'],
            run=config['runs'],
            hemi=config['hemi'],
            density=config['density_hippunfoldV2'],
            label=config['label_hippunfoldV2'],
            tvReg=config['tvReg']
        ),
        expand(
            "derivatives/dataframes/hippunfoldAD_segmentation/sub-{subject}/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_hippunfold-surfmetrics_onlyDWI.csv",
            subject=config['subjects_onlyDWI'],
            run=config['runs'],
            hemi=config['hemi'],
            density=config['density_hippunfoldV2'],
            label=config['label_hippunfoldV2'],
            tvReg=config['tvReg']
        )
    output:
        "derivatives/dataframes/hippunfoldAD_segmentation/hyades_hippunfoldAD_surfmetrics_vertex.csv"
    shell:
        "awk 'NR==1 || FNR!=1' {input}   > {output}"

rule hippunfoldAD_surfMetrics_averageSubfield_dataframe:
    input:
        "derivatives/dataframes/hippunfoldAD_segmentation/hyades_hippunfoldAD_surfmetrics_vertex.csv"
    output:
        "derivatives/dataframes/hippunfoldAD_segmentation/hyades_hippunfoldAD_surfmetrics.csv"
    conda:
       "../envs/pipeline_env.yml"
    script:
        "../scripts/hippocampal_average_subfield.py"


rule concatenate_volumes_hippunfoldAD_dataframes:
    input:
        expand(
            "derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_space-cropT1w_desc-subfields_atlas-multihist7_volumes.tsv",
            subject=config['subjects']
        ),
        expand(
            "derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_space-cropT1w_desc-subfields_atlas-multihist7_volumes.tsv",
            subject= config['subjects_onlyDWI']
        )
    output:
        "derivatives/dataframes/hippunfoldAD_segmentation/hyades_hippunfoldAD_volumes.tsv"
    shell:
        "awk 'NR==1 || FNR!=1' {input} > {output}"

rule concatenate_volumes_normalized_hippunfoldAD_dataframes:
    input:
        expand(
            "derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_run-{run}_space-cropT1w_desc-subfields_atlas-multihist7_volumes_normalized.tsv",
            subject=config['subjects'],
            run=config['runs']
        ),
        expand(
            "derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_run-{run}_space-cropT1w_desc-subfields_atlas-multihist7_volumes_normalized.tsv",
            subject= config['subjects_onlyDWI'],
            run=config['runs']
        )
    output:
        "derivatives/dataframes/hippunfoldAD_segmentation/hyades_hippunfoldAD_volumes_normalized.tsv"
    shell:
        "awk 'NR==1 || FNR!=1' {input} > {output}"