
rule mask_MTsat:
    input:
        config['input_mt_T1w']
    output:
        brain = temp('derivatives/MTsat-fit/sub-{subject}/anat/sub-{subject}_run-{run}_space-orig_desc-brain_mtT1w.nii.gz'),
        mask = temp('derivatives/MTsat-fit/sub-{subject}/anat/sub-{subject}_run-{run}_space-orig_desc-brain_mask.nii.gz')
    threads: workflow.cores
    envmodules:
        config['freesurfer'] 
    shell:
        " mri_synthstrip -i {input} -o {output.brain} -m {output.mask} "


rule fit_MTsat:
    input:
        PDw = config['input_mt_PDw'],
        MTw = config['input_MTw'],
        T1w = config['input_mt_T1w'],
        brain_mask = rules.mask_MTsat.output.mask
    params: 
        MTsat_metadata = 'supplemental_metadata/MTsat_metadata.json'
    output:
        MTsat = 'derivatives/MTsat-fit/sub-{subject}/anat/sub-{subject}_run-{run}_MTsat.nii.gz',
        R1 = 'derivatives/MTsat-fit/sub-{subject}/anat/sub-{subject}_run-{run}_R1map.nii.gz',
        M0 = 'derivatives/MTsat-fit/sub-{subject}/anat/sub-{subject}_run-{run}_M0map.nii.gz'
    envmodules:
        config['quit']
    shadow: "shallow"
    threads: workflow.cores
    shell:
        """
        qi mtsat {input.PDw} {input.T1w} {input.MTw} -o workingFile_ --json {params.MTsat_metadata} -m {input.brain_mask} --threads {workflow.cores}

        mv workingFile_MTSat_delta.nii.gz derivatives/MTsat-fit/sub-{wildcards.subject}/anat/sub-{wildcards.subject}_run-{wildcards.run}_MTsat.nii.gz
        mv workingFile_MTSat_R1.nii.gz derivatives/MTsat-fit/sub-{wildcards.subject}/anat/sub-{wildcards.subject}_run-{wildcards.run}_R1map.nii.gz
        mv workingFile_MTSat_PD.nii.gz derivatives/MTsat-fit/sub-{wildcards.subject}/anat/sub-{wildcards.subject}_run-{wildcards.run}_M0map.nii.gz
        """