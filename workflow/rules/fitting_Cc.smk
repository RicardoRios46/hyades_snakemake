# Rules for calculate Cc metric (FA^2/uFA^2)
rule get_Cc:
    input:
        FA = rules.fit_DKI.output.FA,
        uFA = rules.fit_uFA.output.uFA
    output:
        "derivatives/Cc-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_tvReg-{tvReg}_Cc.nii.gz"
    threads: workflow.cores/4
    envmodules:
        config['mrtrix']
    shell: 
        "mrcalc -nthreads {threads} {input.FA} 2 -pow {input.uFA} 2 -pow -div {output}"