#!/usr/bin/env bash

file="${snakemake_resources[tmpdir]}/tmp_${snakemake_wildcards[subject]}_${snakemake_wildcards[metric]}.txt"
c3d "${snakemake_input[metric]}" "${snakemake_input[dseg]}" -lstat > $file

## Parsing the file
# changing spaces for a sinlge comma:
sed -i -e 's/\s\+/,/g' $file
#remmoving the first comma
sed -i 's/,//' $file
#changing the first line
cols=LabelID,Mean,StdD,Max,Min,Count,Vol_mm3,ext1,ext2,ext3
sed -i "1s/.*/$cols/" $file

mv $file "${snakemake_output[0]}"