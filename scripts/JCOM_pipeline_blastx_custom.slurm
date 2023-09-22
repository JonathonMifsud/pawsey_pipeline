#!/bin/bash
# JM
# script to blastx and extract positive virus contigs

#SBATCH --job-name="blastx_custom_array"

#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=120G
#SBATCH --mail-user="$user@uni.sydney.edu.au"
#SBATCH --mail-type=BEGIN,END,FAIL

##load modules
module load blast
module load diamond

db_basename=$(basename "$db")

# blastx
function Blastx {
    diamond blastx -q "$input" -d "$db" -t "$tempdir" -o "$outpath"/"$library_id"_"$db_basename"_blastx_results.txt -e 1E-4 -c2 -k 3 -b "$MEM" -p "$CPU" -f 6 qseqid qlen sseqid stitle pident length evalue --ultra-sensitive
}

#tool to extract contigs from trinity assembly Blast to fasta
function blastToFasta {
    grep -i ".*" "$outpath"/"$library_id"_"$db_basename"_blastx_results.txt | cut -f1 | uniq > "$outpath"/"$library_id""_temp_contig_names.txt"
    grep -A1 -I -Ff "$outpath"/"$library_id""_temp_contig_names.txt" $input > "$outpath"/"$library_id"_"$db_basename"_blastcontigs.fasta
    sed -i 's/--//' "$outpath"/"$library_id"_"$db_basename"_blastcontigs.fasta
    sed -i '/^[[:space:]]*$/d' "$outpath"/"$library_id"_"$db_basename"_blastcontigs.fasta
    sed --posix -i "/^\>/ s/$/"_$library_id"/" "$outpath"/"$library_id"_"$db_basename"_blastcontigs.fasta
    rm "$outpath"/"$library_id""_temp_contig_names.txt"
}


library_id="$(basename -- $input)"
inpath=$(dirname -- $input)


wd="$wd"
cd "$wd"
outpath="$wd"
tempdir="$wd"
CPU=6
MEM=2
db="$db"

Blastx
blastToFasta

