import pandas as pd

KEYS = ['participant_id', 'group', 'subgroup', 'sex', 'age', 'subfield', 'subfield_ID', 'hemisphere']

df_raw = pd.read_csv(snakemake.input[0], low_memory=False)
g = df_raw.groupby(KEYS, observed=True, dropna=False)
df = g.mean(numeric_only=True).join(g.size().rename('n_vertices')).reset_index()
df.to_csv(snakemake.output[0], index=False)