def get_numeric_tvReg(wildcards):
    "Reads tvReg param from wildcards. Replace 'p' for dot and returns float value"
    tvRegNum=wildcards.tvReg.replace("p",".")
    return f'{float(tvRegNum):0.2f}'

# DKI fit parameters
rule fit_DKI:
    input:
        dwi = rules.get_lte_data.output.lte_preproc,
        bvals =  rules.get_lte_data.output.lte_bval_preproc,
        bvec =  rules.get_lte_data.output.lte_bvec_preproc,
        brain_mask = rules.copy_mask_lte.output,
    params:
        tvReg = get_numeric_tvReg
    output: 
        Dmean = "derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_Dmean.nii.gz",
        Dpar = "derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_Dpar.nii.gz",
        Dperp = "derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_Dperp.nii.gz",
        Dpowder = "derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_Dpowder.nii.gz",
        FA = "derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_FA.nii.gz",
        FAvec = "derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_FAvec.nii.gz",
        Kpar = "derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_Kpar.nii.gz",
        Kperp = 'derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_Kperp.nii.gz',
        Wmean = 'derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_Wmean.nii.gz',
        Wpowder = 'derivatives/DKI-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_Wpowder.nii.gz'
    envmodules:
        config['matlab']
    resources:
        gpu = 1
    threads: workflow.cores
    shell:
        """
        DKI_outputFolder="derivatives/DKI-fit/sub-{wildcards.subject}/dwi/"
        outputFile=$DKI_outputFolder"sub-{wildcards.subject}_run-{wildcards.run}_tvReg-{wildcards.tvReg}"

        # Bash black magic to obtain path+filename without extension
        bvec_bval=$(echo "{input.bvals}" | cut -f 1 -d '.')

        matlab -batch "addpath(genpath('{config[matmri_path]}'));opt.tvReg = {params.tvReg};nii2kurt('{input.dwi}', '$bvec_bval', [], '{input.brain_mask}', opt, '$outputFile');"
        """