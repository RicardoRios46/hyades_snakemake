import numpy as np
import pandas as pd
import nibabel as nib

# Inputs
# input: subject to read and participants file
participantID= 'sub-' + snakemake.wildcards.subject

participants_tsv = snakemake.params.participants

# read values from participant list to create repeated list of subject info
# read participants_list
participants_list = pd.read_csv(participants_tsv, sep='\t', header=0)
# Specify the row index to copy
participant = participants_list.query("participant_id == @participantID")

# dataframe with label structures
structures = pd.read_csv(snakemake.params.structures)

# input: Load csv objects
# uFA
uFA = pd.read_csv(snakemake.input.uFA)
Ka = pd.read_csv(snakemake.input.Kaniso)
Ki = pd.read_csv(snakemake.input.Kiso)
D_uFA = pd.read_csv(snakemake.input.D)
# DKi
FA = pd.read_csv(snakemake.input.FA)
D_dki = pd.read_csv(snakemake.input.Dmean)
Dpar = pd.read_csv(snakemake.input.Dpar)
Dperp = pd.read_csv(snakemake.input.Dperp)
Kpar = pd.read_csv(snakemake.input.Kpar)
Kperp = pd.read_csv(snakemake.input.Kperp)
Wmean = pd.read_csv(snakemake.input.Wmean)
# uFA + DKI
Cc = pd.read_csv(snakemake.input.Cc)

# output: path to dataframe
output_dataframe = snakemake.output[0]


# Prepare new dataframe 
# #read shared info an add structure name based in structure labelsID
dataframe = uFA[['LabelID', 'Count','Vol_mm3']]
dataframe['structure'] = dataframe['LabelID'].map(structures.set_index('LabelID')['structure'])
# read only the string of data to repopulate dataframe
dataframe['participant_id'] = participant.iloc[0,0]
dataframe['age'] = participant.iloc[0,1]
dataframe['sex'] = participant.iloc[0,2]
dataframe['group'] = participant.iloc[0,3]
dataframe['subgroup'] = participant.iloc[0,4]
# rearrange for legilitibity
dataframe = dataframe[['participant_id', 'group', 'subgroup', 'age', 'sex', 'LabelID', 'structure', 'Count', 'Vol_mm3']]


# Read and save means of the structures values of each metric on dataframe
metrics_name = ['uFA', 'Ka', 'Ki', 'D_uFA', 'FA', 'D_dki', 'Dpar', 'Dperp', 'Kpar', 'Kperp', 'Wmean', 'Cc']
for metric in metrics_name:
    dataframe[metric] = eval(metric)["Mean"]

metrics_mt_name = ['MTsat', 'M0map', 'R1map']
for metric in metrics_mt_name:
    dataframe[metric] = np.nan

# Save dataframe as csv or tsv
dataframe.to_csv(output_dataframe,index=False)