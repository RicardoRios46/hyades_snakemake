# Anatomicals stuff
rule mask_T1w:
    input:
        config['input_T1w']
    output:
        'derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_desc-brain_T1w.nii.gz'
    threads: workflow.cores
    envmodules:
        config['freesurfer'] 
    shell:
        "mri_synthstrip -i {input} -o {output} "

rule mask_T2w:
    input:
        config['input_T2w']
    output:
        temp('derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_desc-brainTMP_T2w.nii.gz')
    threads: workflow.cores
    envmodules:
        config['freesurfer'] 
    shell:
        "mri_synthstrip -i {input} -o {output} "

rule regMat_T2w2T1w:
    input:
        T1w = 'derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_desc-brain_T1w.nii.gz',
        T2w = 'derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_desc-brainTMP_T2w.nii.gz'
    params: 
        metric = 'NMI',
        iterations = '100x50x1',
    output:
        'derivatives/registration/sub-{subject}/warps/sub-{subject}_run-{run}_from-T2w_to-T1_mode-image_affine.mat'
    envmodules:
        config['itksnap'] 
    threads: workflow.cores
    shell:
        """
        greedy -d 3 -a \
        -threads {threads} \
        -m {params.metric} \
        -i {input.T1w} {input.T2w} \
        -o {output} \
        -n {params.iterations}
        """

rule regT2w:
    input:
        T2w = rules.mask_T2w.output,
        T1w = rules.mask_T1w.output,
        affine = rules.regMat_T2w2T1w.output
    params:
        interpolation = 'LINEAR' #'LABEL 0.2vox',
    output: 
        'derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_T2w.nii.gz'
    envmodules:
        config['itksnap'] 
    threads: workflow.cores
    shell:
        """
        greedy -threads {threads} -d 3 -rf {input.T1w} -rm {input.T2w} {output} -ri {params.interpolation} -r {input.affine}
        """


rule mask_b0mean:
    input:
        'derivatives/designer-v2-preproc/sub-{subject}/dwi/sub-{subject}_run-{run}_b0mean.nii.gz'
    output:
        brain = temp('derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_desc-brain_b0mean.nii.gz'),
        mask = temp('derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_desc-brain_b0mean_mask.nii.gz')
    envmodules:
        config['freesurfer'] 
    threads: workflow.cores
    shell:
         "mri_synthstrip -i {input} -o {output.brain} -m {output.mask}"

rule regWarp_b0mean2T2w:
    input:
        b0mean = 'derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_desc-brain_b0mean.nii.gz',
        T2w = rules.regT2w.output,
    params: 
        metric = 'WNCC 2x2x2',
        dof = '6',
    output:
        'derivatives/registration/sub-{subject}/warps/sub-{subject}_run-{run}_from-b0mean_to-T2w_mode-image_affine.mat',
    envmodules:
        config['itksnap'] 
    threads: workflow.cores
    shell:
        """
        greedy -d 3 -a \
        -threads {threads} \
        -m {params.metric} \
        -i {input.T2w} {input.b0mean} \
        -o {output} \
        -dof {params.dof}
        """

rule regb0mean:
    input: # metric uses metric_DKI in config file
        T2w_ref = rules.regT2w.output,
        b0_mean = 'derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_desc-brain_b0mean.nii.gz',
        warp = rules.regWarp_b0mean2T2w.output
    params:
        interpolation = 'LINEAR' #'LABEL 0.2vox',
    output: 
        'derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_b0mean.nii.gz'
    envmodules:
        config['itksnap'] 
    threads: workflow.cores
    shell:
        """
        greedy -threads {threads} -d 3 -rf {input.T2w_ref} -rm {input.b0_mean} {output} -ri {params.interpolation} -r {input.warp}
        """

rule regb0mean_mask:
    input: # metric uses metric_DKI in config file
        b0_mean = 'derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_b0mean.nii.gz',
        b0_mean_mask = 'derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_desc-brain_b0mean_mask.nii.gz',
        warp = rules.regWarp_b0mean2T2w.output
    params:
        interpolation = 'LABEL 0.2vox',
    output: 
        'derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_desc-brain_b0mean_mask.nii.gz'
    envmodules:
        config['itksnap'] 
    threads: workflow.cores
    shell:
        """
        greedy -threads {threads} -d 3 -rf {input.b0_mean} -rm {input.b0_mean_mask} {output} -ri {params.interpolation} -r {input.warp}
        """

rule regDKI:
    input: # metric uses metric_DKI in config file
        T2w_ref = rules.regT2w.output,
        metric = "derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_{metric}.nii.gz",
        warp = rules.regWarp_b0mean2T2w.output
    params:
        interpolation = 'LINEAR' #'LABEL 0.2vox',
    output: 
        metric = "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_{metric}.nii.gz"
    envmodules:
        config['itksnap'] 
    threads: workflow.cores
    shell:
        """
        greedy -threads {threads} -d 3 -rf {input.T2w_ref} -rm {input.metric} {output.metric} -ri {params.interpolation} -r {input.warp}
        """


rule reg_uFA:
    input: # metric uses metric_uFA in config file
        T2w_ref = rules.regT2w.output,
        metric = "derivatives/uFA-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_{metric}.nii.gz",
        warp = rules.regWarp_b0mean2T2w.output
    params:
        interpolation = 'LINEAR' #'LABEL 0.2vox',
    output: 
        metric = "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_{metric}.nii.gz"
    envmodules:
        config['itksnap']
    threads: workflow.cores
    shell:
        """
        greedy -threads {threads} -d 3 -rf {input.T2w_ref} -rm {input.metric} {output.metric} -ri {params.interpolation} -r {input.warp}
        """

rule reg_Cc:
    input:
        T2w_ref = rules.regT2w.output,
        Cc = rules.get_Cc.output,
        warp = rules.regWarp_b0mean2T2w.output
    params:
        interpolation = 'LINEAR' #'LABEL 0.2vox',
    output: 
        "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_Cc.nii.gz"
    envmodules:
        config['itksnap']
    threads: workflow.cores
    shell:
        """
        greedy -threads {threads} -d 3 -rf {input.T2w_ref} -rm {input.Cc} {output} -ri {params.interpolation} -r {input.warp}
        """

# MT Sat stuff
rule regWarp_mtT1w2T1w:
    input:
        mtT1w = rules.mask_MTsat.output.brain,
        T1w = rules.mask_T1w.output,
    params: 
        metric = 'WNCC 2x2x2',
        iterations = '100x50x10'
    output:
        'derivatives/registration/sub-{subject}/warps/sub-{subject}_run-{run}_from-mtT1w_to-T1w_mode-image_xfm.nii.gz',
    envmodules:
        config['itksnap']
    threads: workflow.cores
    shell:
        """
        greedy -d 3 \
        -threads {threads} \
        -m {params.metric} \
        -i {input.T1w} {input.mtT1w} \
        -o {output} \
        -sv \
        -n {params.iterations}
        """

rule reg_MTsat:
    input: 
        T1w_ref = rules.mask_T1w.output,
        metric = 'derivatives/MTsat-fit/sub-{subject}/anat/sub-{subject}_run-{run}_{metric}.nii.gz',
        warp = rules.regWarp_mtT1w2T1w.output
    params:
        interpolation = 'LINEAR' #'LABEL 0.2vox',
    output: 
        metric = 'derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_{metric}.nii.gz'
    envmodules:
        config['itksnap']
    threads: workflow.cores
    shell:
        """
        greedy -threads {threads} -d 3 -rf {input.T1w_ref} -rm {input.metric} {output.metric} -ri {params.interpolation} -r {input.warp}
        """