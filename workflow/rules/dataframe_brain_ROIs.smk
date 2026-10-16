rule dataframe_statsSegROIs_uFA:
    input:
        metric = "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_{metric}.nii.gz",
        dseg = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_cropped_dseg.nii.gz'
    output:
        ('derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_{metric}.csv')
    threads: workflow.cores/4
    envmodules:
        config['itksnap']
    script:
        "../scripts/subject_synthseg_dataframe_metric.sh"

rule dataframe_statsSegROIs_DKI:
    input:
        metric = "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_{metric}.nii.gz",
        dseg = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_cropped_dseg.nii.gz'
    output:
        ('derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_{metric}.csv')
    threads: workflow.cores/4
    envmodules:
        config['itksnap']
    script:
        "../scripts/subject_synthseg_dataframe_metric.sh"

rule dataframe_statsSegROIs_MTsat:
    input:
        metric = 'derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_{metric}.nii.gz',
        dseg = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_cropped_dseg.nii.gz'
    output:
        ('derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_{metric}.csv')
    threads: workflow.cores/4
    envmodules:
        config['itksnap']
    script:
        "../scripts/subject_synthseg_dataframe_metric.sh"



rule subject_segmentationROIs_dataframe:
    input:
        # uFA dataframes inputs
        uFA = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_uFA.csv',
        D = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_D.csv',
        Kiso = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_Kiso.csv',
        Kaniso = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_Kaniso.csv',
        # DKI dataframe inputs
        Dmean = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dmean.csv',
        Dpar = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dpar.csv',
        Dperp = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dperp.csv',
        FA = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_FA.csv',
        Kpar = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Kpar.csv',
        Kperp = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Kperp.csv',
        Wmean = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Wmean.csv',
        # uFA-DKI dataframe inputs
        Cc = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Cc.csv',
        # MTsat dataframe inputs.
        MTsat = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_MTsat.csv',
        R1 = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_R1map.csv',
        M0 = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_M0map.csv',
    params:
        # participants list
        participants = 'data/participants.tsv',
        # structures label list
        structures = 'supplemental_metadata/brain_parcellation_ROIs_labels.csv'
    output:
        temp("derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats_tmp.csv")
    conda:
       "../envs/pipeline_env.yml"
    threads: workflow.cores/3
    script:
        "../scripts/subject_ROIs_dataframe.py"


rule subject_onlyDWI_segmentationROIs_dataframe:
    input:
        # uFA dataframes inputs
        uFA = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_uFA.csv',
        D = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_D.csv',
        Kiso = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_Kiso.csv',
        Kaniso = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_Kaniso.csv',
        # DKI dataframe inputs
        Dmean = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dmean.csv',
        Dpar = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dpar.csv',
        Dperp = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dperp.csv',
        FA = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_FA.csv',
        Kpar = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Kpar.csv',
        Kperp = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Kperp.csv',
        Wmean = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Wmean.csv',
        # uFA-DKI dataframe inputs
        Cc = 'derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Cc.csv',
    params:
        # participants list
        participants = 'data/participants.tsv',
        # structures label list
        structures = 'supplemental_metadata/brain_parcellation_ROIs_labels.csv'
    output:
        temp("derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats_onlyDWI_tmp.csv")
    conda:
       "../envs/pipeline_env.yml"
    threads: workflow.cores/3
    script:
        "../scripts/subject_ROIs_dataframe_onlyDWI.py"


# Add normalized volume to dataframe
rule brain_ROIs_calc_volumes:
    input: 
        roi_csv = "derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats_tmp.csv",
        tiv_dseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_dseg.nii.gz'
    output:
        csv = "derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats.csv",
    threads:  workflow.cores/4
    conda:
        "../envs/pipeline_env.yml"
    script:
        "../scripts/compute_normalized_volumes.py"

rule brain_ROIs_calc_volumes_onlyDWI:
    input: 
        roi_csv = "derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats_onlyDWI_tmp.csv",
        tiv_dseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_dseg.nii.gz'
    output:
        csv = "derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats_onlyDWI.csv",
    threads:  workflow.cores/4
    conda:
        "../envs/pipeline_env.yml"
    script:
        "../scripts/compute_normalized_volumes.py"


rule concatenate_segmentationROIs_dataframes:
    input:
        expand(
            "derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats.csv",
            subject=config['subjects'] ,
            run=config['runs'],
            tvReg=config['tvReg']
        ),
        expand(
           "derivatives/dataframes/brain_segmentation_ROIs/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats_onlyDWI.csv",
            subject=config['subjects_onlyDWI'] ,
            run=config['runs'],
            tvReg=config['tvReg']
        )
    output:
        "derivatives/dataframes/brain_segmentation_ROIs/hyades_wholeBrain_ROIs.csv"
    shell:
        "awk 'NR==1 || FNR!=1' {input}   > {output}"