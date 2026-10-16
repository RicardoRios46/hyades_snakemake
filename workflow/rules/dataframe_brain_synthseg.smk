rule dataframe_statsSeg_uFA:
    input:
        metric = "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_{metric}.nii.gz",
        dseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_cropped_dseg.nii.gz'
    output:
        ('derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_{metric}.csv')
    threads: workflow.cores/3
    envmodules:
        config['itksnap']
    script:
        "../scripts/subject_synthseg_dataframe_metric.sh"

rule dataframe_statsSeg_DKI:
    input:
        metric = "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_{metric}.nii.gz",
        dseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_cropped_dseg.nii.gz'
    output:
        ('derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_{metric}.csv')
    threads: workflow.cores/3
    envmodules:
        config['itksnap']
    script:
        "../scripts/subject_synthseg_dataframe_metric.sh"

rule dataframe_statsSeg_MTsat:
    input:
        metric = 'derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_{metric}.nii.gz',
        dseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_cropped_dseg.nii.gz'
    output:
        ('derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_{metric}.csv')
    threads: workflow.cores/3
    envmodules:
        config['itksnap']
    script:
        "../scripts/subject_synthseg_dataframe_metric.sh"



rule subject_segmentation_synthseg_dataframe:
    input:
        # uFA dataframes inputs
        uFA = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_uFA.csv',
        D = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_D.csv',
        Kiso = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_Kiso.csv',
        Kaniso = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_Kaniso.csv',
        # DKI dataframe inputs
        Dmean = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dmean.csv',
        Dpar = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dpar.csv',
        Dperp = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dperp.csv',
        FA = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_FA.csv',
        Kpar = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Kpar.csv',
        Kperp = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Kperp.csv',
        Wmean = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Wmean.csv',
        # uFA-DKI dataframe inputs
        Cc = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Cc.csv',
        # MTsat dataframe inputs.
        MTsat = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_MTsat.csv',
        R1 = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_R1map.csv',
        M0 = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_M0map.csv',
    params:
        # participants list
        participants = 'data/participants.tsv',
        # structures label list
        structures = 'supplemental_metadata/brain_parcellation_labels.csv'
    output:
        "derivatives/dataframes/brain_segmentation/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats.csv"
    conda:
       "../envs/pipeline_env.yml"
    threads: workflow.cores/2
    script:
        "../scripts/subject_synthseg_dataframe.py"


rule subject_onlyDWI_segmentation_synthseg_dataframe:
    input:
        # uFA dataframes inputs
        uFA = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_uFA.csv',
        D = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_D.csv',
        Kiso = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_Kiso.csv',
        Kaniso = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_dsegStats_Kaniso.csv',
        # DKI dataframe inputs
        Dmean = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dmean.csv',
        Dpar = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dpar.csv',
        Dperp = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Dperp.csv',
        FA = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_FA.csv',
        Kpar = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Kpar.csv',
        Kperp = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Kperp.csv',
        Wmean = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Wmean.csv',
        # uFA-DKI dataframe inputs
        Cc = 'derivatives/dataframes/brain_segmentation/sub-{subject}/metrics/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_dsegStats_Cc.csv',
    params:
        # participants list
        participants = 'data/participants.tsv',
        # structures label list
        structures = 'supplemental_metadata/brain_parcellation_labels.csv'
    output:
        "derivatives/dataframes/brain_segmentation/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats_onlyDWI.csv"
    conda:
       "../envs/pipeline_env.yml"
    threads: workflow.cores/2
    script:
        "../scripts/subject_synthseg_dataframe_onlyDWI.py"


rule concatenate_segmentation_synthseg_dataframes:
    input:
        expand(
            "derivatives/dataframes/brain_segmentation/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats.csv",
            subject=config['subjects'] ,
            run=config['runs'],
            tvReg=config['tvReg']
        ),
        expand(
           "derivatives/dataframes/brain_segmentation/sub-{subject}/sub-{subject}_run-{run}_tvReg-{tvReg}_dsegStats_onlyDWI.csv",
            subject=config['subjects_onlyDWI'] ,
            run=config['runs'],
            tvReg=config['tvReg']
        )
    output:
        "derivatives/dataframes/brain_segmentation/hyades_wholeBrain.csv"
    shell:
        "awk 'NR==1 || FNR!=1' {input}   > {output}"

rule concatenate_brain_QCsegmentation_synthseg_dataframes:
    input:
        expand(
            'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w1mm_qc.csv',
            subject=config['subjects'] ,
            run=config['runs'],
            tvReg=config['tvReg']
        ),
        expand(
           'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w1mm_qc.csv',
            subject=config['subjects_onlyDWI'] ,
            run=config['runs'],
            tvReg=config['tvReg']
        )
    output:
        "derivatives/dataframes/brain_segmentation/synthseg_qc.csv"
    shadow: "shallow"
    shell:
        """
        awk 'NR==1 || FNR!=1' {input} > tmp.csv
        sed -e 's/_run-0[0-9]_desc-brain_T1w//g' tmp.csv > {output}
        """