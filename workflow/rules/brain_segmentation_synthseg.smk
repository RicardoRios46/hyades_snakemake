# todo. Is more optimal for execution to run all the files in the same line

#Note: GPU usage possible but require spetialized GPU software in path. Using cpu for now

rule brain_synthseg_segmentation:
    input:
        config['input_T1w']
    output:
        dseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w1mm_dseg.nii.gz',
        vol = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w1mm_vol.csv',
        qc = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w1mm_qc.csv'
    threads:  workflow.cores
    params:
        cortex_parc = '--parc',
        robust = '--robust'
    envmodules:
        config['freesurfer']
    shell:
        "mri_synthseg --i {input} --o {output.dseg} {params.cortex_parc} {params.robust} --threads {threads} --vol {output.vol} --qc {output.qc}"

rule upscale_synthseg_segmentation:
    input:
        dseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w1mm_dseg.nii.gz',
        ref = 'derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_desc-brain_T1w.nii.gz'
    output:
        'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_dseg.nii.gz'
    threads:  workflow.cores
    params:
        interpolation = 'MultiLabel'
    envmodules:
        config['ants']
    shell:
        "antsApplyTransforms -i {input.dseg} -r {input.ref} -n {params.interpolation} -o {output}"

rule crop_segmentation_b0meanMask:
    input:
        dseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_dseg.nii.gz',
        ref = 'derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_desc-brain_b0mean_mask.nii.gz'
    output:
        'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_cropped_dseg.nii.gz'
    threads:  workflow.cores
    envmodules:
        config['mrtrix']
    shell:
        "mrcalc {input.dseg} {input.ref} -mult {output}"