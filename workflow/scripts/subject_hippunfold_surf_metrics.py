import numpy as np
import pandas as pd
import nibabel as nib

# Inputs
# input: subject to read and participants file
participantID= 'sub-' + snakemake.wildcards.subject
participants_tsv = snakemake.params.participants

# read participants_list
participants_list = pd.read_csv(participants_tsv, sep='\t', header=0)
# Specify the row index to copy
participant = participants_list.query("participant_id == @participantID")

# output: path to dataframe
output_dataframe = snakemake.output[0]

# input: Load gifti objects / extract numpy object data
metrics_name = ['uFA', 'Ka', 'Ki', 'D_uFA', 'FA', 'D_dki', 'Dpar', 'Dperp', 'Kpar', 'Kperp', 'Wmean', 'Cc', 'MTsat', 'M0map', 'R1map', 'thickness', 'curvature','gyrification','subfield_ID']
# uFA
uFA = nib.load(snakemake.input.uFA).agg_data()
Ka = nib.load(snakemake.input.Kaniso).agg_data()
Ki = nib.load(snakemake.input.Kiso).agg_data()
D_uFA = nib.load(snakemake.input.D).agg_data()
# DKi
FA = nib.load(snakemake.input.FA).agg_data()
D_dki = nib.load(snakemake.input.Dmean).agg_data()
Dpar = nib.load(snakemake.input.Dpar).agg_data()
Dperp = nib.load(snakemake.input.Dperp).agg_data()
Kpar = nib.load(snakemake.input.Kpar).agg_data()
Kperp = nib.load(snakemake.input.Kperp).agg_data()
Wmean = nib.load(snakemake.input.Wmean).agg_data()
# uFA + DKI
Cc = nib.load(snakemake.input.Cc).agg_data()
#MTsat
MTsat = nib.load(snakemake.input.MTsat).agg_data()
M0map = nib.load(snakemake.input.M0).agg_data()
R1map = nib.load(snakemake.input.R1).agg_data()

# Hippunfold metrics
thickness = nib.load(snakemake.input.thickness).agg_data()
curvature = nib.load(snakemake.input.curvature).agg_data()
gyrification = nib.load(snakemake.input.gyrification).agg_data()

# Hippunfold label
subfield_ID = nib.load(snakemake.input.subfields_label).agg_data()

# hemishpere
hemisphere = snakemake.wildcards.hemi


# Creating the dataframe

# Concatenate metrics and create initial data_frame
metrics=np.stack([uFA, Ka, Ki, D_uFA, FA, D_dki, Dpar, Dperp, Kpar, Kperp, Wmean, Cc, MTsat, M0map, R1map, thickness, curvature, gyrification, subfield_ID],axis=1)
dataframe = pd.DataFrame(metrics,columns=metrics_name)

# Create list with the shortname of the subfield instead of number
subfields_names_dict = {'1':'Sub','2':'CA1','3':'CA2','4':'CA3','5':'CA4','6':'DG','7':'SRLM','8':'Cyst'}
dataframe["subfield_ID"] = dataframe["subfield_ID"].astype(int)
dataframe["subfield"] = dataframe["subfield_ID"].astype(str).replace(regex=subfields_names_dict) 

# read only the string of data to repopulate dataframe
dataframe['participant_id'] = participant.iloc[0,0]
dataframe['age'] = participant.iloc[0,1]
dataframe['sex'] = participant.iloc[0,2]
dataframe['group'] = participant.iloc[0,3]
dataframe['subgroup'] = participant.iloc[0,4]

dataframe['hemisphere'] = hemisphere

# Rearrange columns for legibility
dataframe = dataframe[['participant_id', 'group', 'subgroup', 'age', 'sex', 'hemisphere', 'subfield_ID', 'subfield', 'uFA', 'Ka', 'Ki', 'D_uFA', 'FA', 'D_dki', 'Dpar', 'Dperp', 'Kpar', 'Kperp', 'Wmean', 'Cc', 'MTsat', 'M0map', 'R1map', 'thickness', 'curvature','gyrification']]

# Save dataframe as csv or tsv
dataframe.to_csv(output_dataframe,index=False)