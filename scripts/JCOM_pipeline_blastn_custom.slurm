#!/bin/bash
# JM
# script to blastn and extract positive virus contigs

#SBATCH --job-name="blastn_custom_array"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --mail-user="$user@uni.sydney.edu.au"
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --partition=work

##load modules
module load singularity/3.11.4

nt_db_basename=$(basename "$db")

# blastn
function Blastn {
    blastn -query "$input" -db "$db" -out "$outpath"/"$library_id"_"$nt_db_basename"_nt_blastn_results.txt -max_target_seqs 10 -num_threads "$CPU" -mt_mode 0 -evalue 1E-4 -subject_besthit -outfmt '6 qseqid qlen sacc salltitles staxids pident length evalue'
}

#tool to extract contigs from assembly Blast to fasta
function blastToFasta {
    grep -i ".*" "$outpath"/"$library_id"_"$nt_db_basename"_nt_blastn_results.txt | cut -f1 | uniq > "$outpath"/"$library_id""_temp_contig_names.txt"
    grep -A1 -I -Ff "$outpath"/"$library_id""_temp_contig_names.txt" $input > "$outpath"/"$library_id"_"$nt_db_basename"_nt_blastcontigs.fasta
    sed -i 's/--//' "$outpath"/"$library_id"_"$nt_db_basename"_nt_blastcontigs.fasta
    sed -i '/^[[:space:]]*$/d' "$outpath"/"$library_id"_"$nt_db_basename"_nt_blastcontigs.fasta
    sed --posix -i "/^\>/ s/$/"_$library_id"/" "$outpath"/"$library_id"_"$nt_db_basename"_nt_blastcontigs.fasta
    rm "$outpath"/"$library_id""_temp_contig_names.txt"
}


library_id="$(basename -- $input)"
inpath=$(dirname -- $input)

wd="$wd"
outpath="$wd"
CPU=6
MEM=2

cd "$wd" || exit

Blastn
blastToFasta

