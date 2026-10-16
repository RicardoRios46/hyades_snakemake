#Note: GPU is faster

rule brain_SIAM_segmentation:
    input: 
        config['input_T1w']
    output:
        dseg = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_SIAM_dseg.nii.gz',
    threads:  workflow.cores
    params:
        model = '0',
    container:
        config['SIAM_container']
    #shadow: "shallow"
    shell:
        """
        # Create tmp folder for output in /tmp
        output_folder={resources.tmpdir}/sub-{wildcards.subject}_output_siam
        mkdir -p $output_folder

        cp {input} $output_folder/sub-{wildcards.subject}_run-{wildcards.run}_T1w.nii.gz

        siam-pred  -i $output_folder/sub-{wildcards.subject}_run-{wildcards.run}_T1w.nii.gz -nbthread {threads} -m {params.model} 

		# Copy output to correct outputpath
        cp $output_folder/siamV03_sub-{wildcards.subject}_run-{wildcards.run}_T1w.nii.gz {output.dseg}

        # Eraste tmp output folder
        rm -rf $output_folder
        """


rule cleanCSF_HippoAmyg_SIAM_segmentation:
    input:
        T1 = config['input_T1w'],
        siam = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_SIAM_dseg.nii.gz',
    output:
        siam_corrected = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_SIAM-csfCorrected_dseg.nii.gz',
        excluded_csf = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_SIAM-csfExcludedOnly_dseg.nii.gz',
        log_csv = temp('derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_SIAM_csfCorrected_log.csv')
    threads:  workflow.cores/3
    params:
        epsilon_detect = 0, # Threshold for detecting leakage. I observed that it correction helped everytime so no need to protect the user.
        safety_cap_fraction = 0.15, # Warn to user if more than 15% of the hippocampus/amygdala is removed. Just for QC puprposes, the correction is apply anyway with --force-apply.
        connectivity = 26,
        csf_margin_sigma = 1.0, # For V1 (aggressive) this was 0. Worked great with extreme leakage but in general it is better to have a margin to avoid removing too much tissue.
    conda:
        "../envs/pipeline_env.yml"
    #script:
    #    "../scripts/parcellate_siam_gm.py"
    shell:
        """
        python workflow/scripts/correct_hippo_amyg_leakage.py \
            --labels {input.siam} \
            --t1 {input.T1} \
            --out-labels {output.siam_corrected} \
            --out-mask {output.excluded_csf} \
            --epsilon-detect {params.epsilon_detect} \
            --safety-cap-fraction {params.safety_cap_fraction} \
            --connectivity {params.connectivity} \
            --csf-margin-sigma {params.csf_margin_sigma} \
            --log-csv {output.log_csv} \
            --force-apply
        """

rule concatenate_cleanCSF_HippoAmyg_SIAM_logs:
    input:
        expand(
            'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_SIAM_csfCorrected_log.csv',
            subject=config['subjects'] + config['subjects_onlyDWI'],
            run=config['runs'],
            tvReg=config['tvReg']
        ),
    output:
        "derivatives/SIAM/SIAM_csfCorrected_log.csv"
    shell:
        "awk 'NR==1 || FNR!=1' {input}   > {output}"


rule parcellateGM_SIAM_segmentation:
    input:
        siam = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_SIAM-csfCorrected_dseg.nii.gz',
        synthseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_dseg.nii.gz'
    output:
        'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_SIAM-csfCorrected-parcellated_dseg.nii.gz',
    threads:  workflow.cores/2
    params:
        structures = 'ALL'
    conda:
        "../envs/pipeline_env.yml"
    script:
        "../scripts/parcellate_siam_gm.py"


rule group_parcellated_SIAM_segmentation:
    input:
        dseg_SIAM_parcellated = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_SIAM-csfCorrected-parcellated_dseg.nii.gz',
    output:
        'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_dseg.nii.gz'
    params:
        grouping_labels_json = 'supplemental_metadata/dseg2rois_config.json'
    threads:  workflow.cores/4
    conda:
        "../envs/pipeline_env.yml"
    shell:
        """
        python workflow/scripts/combine_dseg.py {input.dseg_SIAM_parcellated} --groups {params.grouping_labels_json} --output {output}
        """

rule crop_SIAM_segmentation_b0meanMask:
    input:
        dseg = 'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_dseg.nii.gz',
        ref = 'derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_desc-brain_b0mean_mask.nii.gz'
    output:
        'derivatives/SIAM/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_cropped_dseg.nii.gz'
    threads:  workflow.cores
    envmodules:
        config['mrtrix']
    shell:
        "mrcalc {input.dseg} {input.ref} -mult {output}"