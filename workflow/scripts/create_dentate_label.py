import nibabel as nib

gifti_img = nib.load(snakemake.input[0])

# change the values to label
dentate_label = 6
gifti_img.darrays[0].data[:] = dentate_label

nib.save(gifti_img, snakemake.output[0])