# Rules for fitting uFA to the data

rule fit_uFA:
    input:
        dwi = rules.designer.output.dwi_preproc,
        brain_mask = rules.designer.output.brain_mask,
        bvals =  rules.designer.output.bval_preproc,
        ste_bool = rules.get_ste_metadata.output
    output: 
        uFA = "derivatives/uFA-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_uFA.nii.gz",
        D = "derivatives/uFA-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_D.nii.gz",
        Kiso = "derivatives/uFA-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_Kiso.nii.gz",
        Klte = 'derivatives/uFA-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_Klte.nii.gz'
    threads: workflow.cores
    resources:
        gpu = 1
    shadow: "shallow"
    envmodules:
        config['matlab']
    shell:
        """
        matlab -batch "addpath(genpath('{config[matmri_path]}'));[uFA,Klin,Kiso,D,uFA_FWE,Kiso_FWE,Klin_FWE,D_FWE,sf_FWE,uA2,sSTE,sLTE] = nii2uFA_fwe('{input.dwi}', '{input.bvals}', '{input.ste_bool}', '{input.brain_mask}', [], 'sub-{wildcards.subject}');"

        mv sub-{wildcards.subject}_uFA.nii.gz {output.uFA}
        mv sub-{wildcards.subject}_D.nii.gz {output.D}
        mv sub-{wildcards.subject}_Kiso.nii.gz {output.Kiso}
        mv sub-{wildcards.subject}_Klin.nii.gz {output.Klte}
        """

rule get_Kaniso:
    input:
        Kiso = rules.fit_uFA.output.Kiso,
        Klte = rules.fit_uFA.output.Klte
    output:
        "derivatives/uFA-fit/sub-{subject}/dwi/sub-{subject}_run-{run}_Kaniso.nii.gz"
    envmodules:
        config['mrtrix']
    threads: workflow.cores/2
    shell: 
        "mrcalc -nthreads {threads} {input.Klte} {input.Kiso} -subtract {output}"