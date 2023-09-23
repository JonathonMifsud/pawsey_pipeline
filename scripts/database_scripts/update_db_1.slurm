#!/bin/bash
#PBS -P VELAB
#PBS -N Update_db
#PBS -l select=1:ncpus=4:mem=60GB
#PBS -l walltime=300:00:00
#PBS -M jmif9945@hpc.sydney.edu.au
#PBS -m bea
#PBS -o update_db_1.log
#PBS -q dtq

# DATABASE SCRIPT 1
# This script will update the blast databases (and others) used by the Holmes lab
# Database script 2 build SILVA and HMM databases
# Script 3 will build the Diamond database and is dependent on script 1

# load modules
module load diamond
module load blast
module load hmmer
module load cd-hit
module load blast+/2.9.0
module load perl
module load wget

# set path to databases
path_db=/scratch/VELAB/Databases

# Today is the database that will run today, it will be named with the following month
today=$(date -d "next month" +%b-%Y)

# past_file is the database that will be removed, it will be named with the previous month (two months before "$today")
past_file=$(date -d "last month" +%b-%Y)

# set edirect api key
export NCBI_API_KEY="CHANGE ME"


function updateBlastNT {
    # Import Blast databases nt (pre-formatted)
    cd "$path_db"/Blast/
    mkdir "$path_db"/Blast/nt."$today"/
    cd "$path_db"/Blast/nt."$today"/
    perl /usr/local/blast+/2.9.0/bin/update_blastdb.pl --decompress --force nt
    rm -r ../nt.$past_file/
}

function updateBlastNR {
    # Import Blast databases nr
    mkdir "$path_db"/Blast/nr."$today"/
    cd "$path_db"/Blast/nr."$today"/
    perl /usr/local/blast+/2.9.0/bin/update_blastdb.pl --decompress --force nr
    perl /usr/local/blast+/2.9.0/bin/update_blastdb.pl --decompress --force taxdb

    # remove the old files
    rm -r "$path_db"/Blast/nr."$past_file"/
    rm "$path_db"/Blast/nr."$today"/nucl_gb.accession2taxid."$past_file".gz

    cd "$path_db"/Blast/
    wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz -O "$path_db"/Blast/nr."$today".gz

    # get the taxonomy file that links the accession number to the taxid
    wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.gz -O "$path_db"/Blast/prot.accession2taxid."$today".gz
    gzip -c -d "$path_db"/Blast/prot.accession2taxid."$today".gz > "$path_db"/Blast/prot.accession2taxid."$today"

}

function updateTaxdmp {
    # update the tax dump files used for general taxonomy
    mkdir "$path_db"/Blast/taxdmp."$today"
    wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdmp.zip -O "$path_db"/Blast/taxdmp."$today"/taxdmp."$today".zip
    wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz -O "$path_db"/Blast/nucl_gb.accession2taxid."$today".gz
    cd "$path_db"/Blast/taxdmp."$today"
    unzip taxdmp."$today".zip
    cp * ../ 
}

function updateVirusProt {
    # Import all virus proteins
    # this has been failing so we will use a newer verison of entrez - JM 
    CONDA_BASE=$(conda info --base) #figure out the path to conda directory so I can source it
    source $CONDA_BASE/etc/profile.d/conda.sh
    conda activate edirect
    esearch -db protein -query "Viruses[Organism]" | efetch -format fasta > "$path_db"/Blast/ALL_Virus_prot.NCBI."$today".fasta
    conda deactivate
    rm "$path_db"/Blast/ALL_Virus_prot.NCBI."$past_file".fasta
}

function updateVirusRefSeq {
    # Import RefSeq viral genomes
    wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/ref_viruses_rep_genomes.tar.gz -O "$path_db"/Blast/Virus_RefSeq."$today".tar.gz
    tar zxvpf "$path_db"/Blast/Virus_RefSeq."$today".tar.gz
}

function updateVirusHost {
    # Import Virus-Host db
    cd "$path_db"/Virus_Host_db/
    wget ftp://ftp.genome.jp/pub/db/virushostdb/virushostdb.daily.tsv -O "$path_db"/Virus_Host_db/virushostdb."$today".tsv
    rm *$past_file*
}

function updateRVDBHMM {
    # Import RVDB HMM
    wget https://rvdb-prot.pasteur.fr/files/U-RVDBv18.0-prot.fasta.bz2 -O "$path_db"/HMM/RVDB.prot."$today".bz2
    bzip2 -d "$path_db"/HMM/RVDB.prot."$today".bz2
    rm "$path_db"/HMM/RVDB.prot."$past_file"

}

function updateRVDBprotein {
    # Import RVDB protein
    # There is no latest version link, so we have to do something a little more complicated.
    # We will check the current version, and if it is not the latest, we will download the latest
    # and update the current version variable in the file.
    # If it is the latest, we will continue with the existing database.
    # This assumes that the database updates in a predictable manner 26 -> 27 -> 28, etc. - JM

    # Get the current version
    local rvdb_current_version=25
    local rvdb_new_version=$((rvdb_current_version + 1))
    local url="https://rvdb-prot.pasteur.fr/files/U-RVDBv${rvdb_new_version}.0-prot.fasta.xz"

    local response=$(curl --head --silent "$url")

    # Check if the response indicates success and the file size is greater than 0
    if [[ $response == *"200 OK"* && $(curl -sI "$url" | awk '/Content-Length/{print $2}' | tr -d '\r') -gt 0 ]]; then
        echo "New version available. Downloading..."
        wget "$url" -O "$path_db/Blast/U-RVDBv${rvdb_new_version}.0-prot.$today.fasta.xz"
        xz -d "$path_db/Blast/U-RVDBv${rvdb_new_version}.0-prot.$today.fasta.xz"
        # Proceed with updating the database

        # Update current_version
        rvdb_current_version=$rvdb_new_version
    else
        echo "No new version available."
        # Continue with the existing database
    fi

    # Function to update current_version variable in a file
    update_current_version() {
        local version=$1
        local file_path=$2
        sed -i "s/^rvdb_current_version=.*/rvdb_current_version=$version/" "$file_path"
    }

    # Update the current version in the update_db_1.pbs file
    update_current_version "$rvdb_current_version" "/scratch/VELAB/Databases/update_db_1.pbs"

    touch /scratch/VELAB/Databases/Blast/rvdb_current_version
    echo "$rvdb_current_version" > /scratch/VELAB/Databases/Blast/rvdb_current_version
}




function cleanUp {
    # Clean up
    chmod g+wr "$path_db"/update_db_1.log
    rename ".log" ".$today.log" "$path_db"/update_db_1.log
    rename ".log" ".$today.log" "$path_db"/update_db_1.log_usage
}

# Run Block
updateBlastNT
updateBlastNR
updateTaxdmp
updateVirusProt
updateVirusRefSeq
updateVirusHost
updateRVDBprotein