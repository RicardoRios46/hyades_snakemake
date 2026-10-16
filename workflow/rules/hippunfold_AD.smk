rule hippunfold_AD:
    input: # T1w in the bids folder
        'data/sub-{subject}'
    params:
        modality = 'T1w',
        nnunet_model = 'ADNI_T1w_v1'
    output: 
        L_dseg= 'derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_hemi-L_space-T1w_label-hipp_desc-subfields_atlas-multihist7_dseg.nii.gz',
        R_dseg= 'derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_hemi-R_space-T1w_label-hipp_desc-subfields_atlas-multihist7_dseg.nii.gz',
        volumes_tsv = 'derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_space-cropT1w_desc-subfields_atlas-multihist7_volumes.tsv',
        surface_spec = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_den-8k_surfaces.spec',

        L_hipp_midthickness = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-L_space-T1w_den-8k_label-hipp_midthickness.surf.gii',
        L_hipp_outer_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-L_space-T1w_den-8k_label-hipp_outer.surf.gii',
        L_hipp_inner_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-L_space-T1w_den-8k_label-hipp_inner.surf.gii',
        R_hipp_midthickness = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-R_space-T1w_den-8k_label-hipp_midthickness.surf.gii',
        R_hipp_outer_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-R_space-T1w_den-8k_label-hipp_outer.surf.gii',
        R_hipp_inner_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-R_space-T1w_den-8k_label-hipp_inner.surf.gii',

        L_dentate_midthickness = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-L_space-T1w_den-8k_label-dentate_midthickness.surf.gii',
        L_dentate_outer_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-L_space-T1w_den-8k_label-dentate_outer.surf.gii',
        L_dentate_inner_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-L_space-T1w_den-8k_label-dentate_inner.surf.gii',
        R_dentate_midthickness = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-R_space-T1w_den-8k_label-dentate_midthickness.surf.gii',
        R_dentate_outer_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-R_space-T1w_den-8k_label-dentate_outer.surf.gii',
        R_dentate_inner_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-R_space-T1w_den-8k_label-dentate_inner.surf.gii',
        

        L_hipp_metric_thickness = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-L_den-8k_label-hipp_thickness.shape.gii',
        R_hipp_metric_thickness = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-R_den-8k_label-hipp_thickness.shape.gii',
        L_hipp_metric_curvature = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-L_den-8k_label-hipp_curvature.shape.gii',
        R_hipp_metric_curvature = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-R_den-8k_label-hipp_curvature.shape.gii',
        L_hipp_metric_gyrification = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-L_den-8k_label-hipp_gyrification.shape.gii',
        R_hipp_metric_gyrification = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-R_den-8k_label-hipp_gyrification.shape.gii',

        L_dentate_metric_thickness = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-L_den-8k_label-dentate_thickness.shape.gii',
        R_dentate_metric_thickness = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-R_den-8k_label-dentate_thickness.shape.gii',
        L_dentate_metric_curvature = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-L_den-8k_label-dentate_curvature.shape.gii',
        R_dentate_metric_curvature = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-R_den-8k_label-dentate_curvature.shape.gii',
        L_dentate_metric_gyrification = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-L_den-8k_label-dentate_gyrification.shape.gii',
        R_dentate_metric_gyrification = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-R_den-8k_label-dentate_gyrification.shape.gii',

        L_subfields_label = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-L_den-8k_label-hipp_atlas-multihist7_subfields.label.gii',
        R_subfields_label = 'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-R_den-8k_label-hipp_atlas-multihist7_subfields.label.gii',

    container:
        config['hippunfoldV2_container']
    threads: workflow.cores
    resources:
        gpu = 1
    shadow: "shallow"
    shell:
        """
        hippunfold data/ hipponfuld_AD_output participant --participant_label {wildcards.subject} --cores {threads} --modality {params.modality} --force-nnunet-model {params.nnunet_model} -q

        cp -r hipponfuld_AD_output/sub-{wildcards.subject} derivatives/hippunfold_AD/
        """

rule hippunfold_AD_dentateLabel:
    input:
        'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-dentate_thickness.shape.gii', # todo this onw porbably has to be an output of hippunfold
    output: 
        'derivatives/hippunfold_AD/sub-{subject}/metric/sub-{subject}_hemi-{hemi}_den-{density}_label-dentate_atlas-multihist7_subfields.label.gii',
    threads: workflow.cores/4
    conda:
       "../envs/pipeline_env.yml"
    script:
        "../scripts/create_dentate_label.py"

rule calculate_volumes_normalized_hippunfoldAD_dataframes:
    input: 
        hippunfold_volumes_tsv = 'derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_space-cropT1w_desc-subfields_atlas-multihist7_volumes.tsv',
        tiv_dseg = 'derivatives/synthseg/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_dseg.nii.gz'
    output:
        tsv = 'derivatives/hippunfold_AD/sub-{subject}/anat/sub-{subject}_run-{run}_space-cropT1w_desc-subfields_atlas-multihist7_volumes_normalized.tsv'
    threads:  workflow.cores/4
    conda:
        "../envs/pipeline_env.yml"
    script:
        "../scripts/compute_normalized_volumes_hippunfold.py"

rule uFA2hippsurf_AD:
    input: 
        metric = "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_{metric}.nii.gz",
        midthickness = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_midthickness.surf.gii',
        outer_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_outer.surf.gii',
        inner_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_inner.surf.gii',
    output:
        metric = 'derivatives/hippunfold_AD_metrics/uFA/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_{metric}.shape.gii'
    threads: workflow.cores/4
    envmodules:
        config['connectome-workbench']
    shell:
        """
        wb_command -volume-to-surface-mapping {input.metric} {input.midthickness} {output.metric} -ribbon-constrained {input.outer_surf} {input.inner_surf}
        """

rule DKI2hippsurf_AD:
    input: 
        metric = "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_{metric}.nii.gz",
        midthickness = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_midthickness.surf.gii',
        outer_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_outer.surf.gii',
        inner_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_inner.surf.gii',
    output:
        metric = "derivatives/hippunfold_AD_metrics/DKI/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_{metric}.shape.gii"
    threads: workflow.cores/4
    envmodules:
        config['connectome-workbench']
    shell:
        """
        wb_command -volume-to-surface-mapping {input.metric} {input.midthickness} {output.metric} -ribbon-constrained {input.outer_surf} {input.inner_surf}
        """


rule Cc2hippsurf_AD:
    input: 
        Cc = "derivatives/registration/sub-{subject}/dwi/sub-{subject}_run-{run}_space-T1w_tvReg-{tvReg}_Cc.nii.gz",
        midthickness = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_midthickness.surf.gii',
        outer_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_outer.surf.gii',
        inner_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_inner.surf.gii',
    output:
        Cc = "derivatives/hippunfold_AD_metrics/Cc/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_tvReg-{tvReg}_Cc.shape.gii",
    threads: workflow.cores/4
    envmodules:
        config['connectome-workbench']
    shell:
        """
        wb_command -volume-to-surface-mapping {input.Cc} {input.midthickness} {output.Cc} -ribbon-constrained {input.outer_surf} {input.inner_surf}
        """


rule MTsat2hippsurf_AD:
    input: 
        metric = 'derivatives/registration/sub-{subject}/anat/sub-{subject}_run-{run}_space-T1w_{metric}.nii.gz',
        midthickness = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_midthickness.surf.gii',
        outer_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_outer.surf.gii',
        inner_surf = 'derivatives/hippunfold_AD/sub-{subject}/surf/sub-{subject}_hemi-{hemi}_space-T1w_den-{density}_label-{label}_inner.surf.gii',
    output:
        metric = 'derivatives/hippunfold_AD_metrics/MTsat/sub-{subject}/surf/sub-{subject}_run-{run}_hemi-{hemi}_den-{density}_label-{label}_{metric}.shape.gii'
    threads: workflow.cores/4
    envmodules:
        config['connectome-workbench']
    shell:
        """
        wb_command -volume-to-surface-mapping {input.metric} {input.midthickness} {output.metric} -ribbon-constrained {input.outer_surf} {input.inner_surf}
        """