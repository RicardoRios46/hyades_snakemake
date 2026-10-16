# Anatomicals stuff
rule brain_extract_T1w:
    input:
        config['input_T1w']
    output:
        'derivatives/data_repository/sub-{subject}/anat/sub-{subject}_run-{run}_desc-brain_T1w.nii.gz'
    threads: workflow.cores
    envmodules:
        config['freesurfer'] 
    shell:
        "mri_synthstrip -i {input} -o {output} "

rule brain_extract_T2w:
    input:
        config['input_T2w']
    output:
        'derivatives/data_repository/sub-{subject}/anat/sub-{subject}_run-{run}_desc-brain_T2w.nii.gz'
    threads: workflow.cores
    envmodules:
        config['freesurfer'] 
    shell:
        "mri_synthstrip -i {input} -o {output} "


rule brain_extract_MTsat:
    input:
        PDw = config['input_mt_PDw'],
        MTw = config['input_MTw'],
        T1w = config['input_mt_T1w'],
    output:
        PDw = 'derivatives/data_repository/sub-{subject}/anat/sub-{subject}_run-{run}_space-orig_desc-brain_flip-1_mt-off_MTS.nii.gz',
        MTw = 'derivatives/data_repository/sub-{subject}/anat/sub-{subject}_run-{run}_space-orig_desc-brain_flip-1_mt-on_MTS.nii.gz',
        T1w = 'derivatives/data_repository/sub-{subject}/anat/sub-{subject}_run-{run}_space-orig_desc-brain_flip-2_mt-off_MTS.nii.gz',
        mask = 'derivatives/data_repository/sub-{subject}/anat/sub-{subject}_run-{run}_space-orig_desc-brain_MTS_mask.nii.gz'
    threads: workflow.cores
    envmodules:
        config['freesurfer']
    shell:
        """ 
        mri_synthstrip -i {input.T1w} -o {output.T1w} -m {output.mask}
        mris_calc -o {output.PDw} {input.PDw} mul {output.mask}
        mris_calc -o {output.MTw} {input.MTw} mul {output.mask}
        """

# designer output, 
rule brain_extract_b0mean:
    input:
        'derivatives/designer-v2-preproc/sub-{subject}/dwi/sub-{subject}_run-{run}_b0mean.nii.gz'
    output:
        brain = 'derivatives/data_repository/sub-{subject}/dwi/sub-{subject}_run-{run}_desc-brain_b0mean.nii.gz',
        mask = 'derivatives/data_repository/sub-{subject}/dwi/sub-{subject}_run-{run}_desc-brain_b0mean_mask.nii.gz'
    envmodules:
        config['freesurfer'] 
    threads: workflow.cores
    shell:
         "mri_synthstrip -i {input} -o {output.brain} -m {output.mask}"


rule brain_extract_designer:
    input:
        dwi_preproc = "derivatives/designer-v2-preproc/sub-{subject}/dwi/sub-{subject}_acq-mde_run-{run}_desc-preproc_dwi.nii.gz",
        mask = 'derivatives/data_repository/sub-{subject}/dwi/sub-{subject}_run-{run}_desc-brain_b0mean_mask.nii.gz'
    output:
        dwi_preproc_brain = "derivatives/data_repository/sub-{subject}/dwi/sub-{subject}_acq-mde_run-{run}_desc-preproc_dwi.nii.gz",
    threads: workflow.cores/4
    envmodules:
        config['mrtrix']
    shell:
        """ 
        mrcalc -nthreads {threads} -force {input.dwi_preproc} {input.mask} -mult {output.dwi_preproc_brain}  
        """

rule copy_designer_metadata:
    input: 
        ste = 'supplemental_metadata/volumes_bool_postDesigner.ste',
        bval = "derivatives/designer-v2-preproc/sub-{subject}/dwi/sub-{subject}_acq-mde_run-{run}_desc-preproc_dwi.bval",
        bvec = "derivatives/designer-v2-preproc/sub-{subject}/dwi/sub-{subject}_acq-mde_run-{run}_desc-preproc_dwi.bvec",
    output:
       ste =  'derivatives/data_repository/sub-{subject}/dwi/sub-{subject}_acq-mde_run-{run}_desc-preproc_dwi.ste',
       bval = "derivatives/data_repository/sub-{subject}/dwi/sub-{subject}_acq-mde_run-{run}_desc-preproc_dwi.bval",
       bvec = "derivatives/data_repository/sub-{subject}/dwi/sub-{subject}_acq-mde_run-{run}_desc-preproc_dwi.bvec"
    threads: 1
    shell:
        """
        cp {input.ste} {output.ste}
        cp {input.bval} {output.bval}
        cp {input.bvec} {output.bvec}
        """

# segmentations outputs
rule copy_hippunfold_dseg:
    input:
        L_dseg= 'derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_hemi-L_space-T1w_label-hipp_desc-subfields_atlas-multihist7_dseg.nii.gz',
        R_dseg= 'derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_hemi-R_space-T1w_label-hipp_desc-subfields_atlas-multihist7_dseg.nii.gz',
    output:
        L_dseg= 'derivatives/data_repository/sub-{subject}/anat/sub-{subject}_hemi-L_space-T1w_label-hipp_desc-subfields_atlas-multihist7_dseg.nii.gz',
        R_dseg= 'derivatives/data_repository/sub-{subject}/anat/sub-{subject}_hemi-R_space-T1w_label-hipp_desc-subfields_atlas-multihist7_dseg.nii.gz',
    threads: 1
    shell:
        """
        cp {input.L_dseg} {output.L_dseg}
        cp {input.R_dseg} {output.R_dseg}
        """

rule copy_SIAMsynthseg_ROIs:
    input:
        'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_dseg.nii.gz'
    output:
        'derivatives/data_repository/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_desc-ROIs_dseg.nii.gz'
    threads: 1
    shell:
        """
        cp {input} {output}
        """