#!/bin/bash
#PBS -P VELAB
#PBS -N Update_db
#PBS -l select=1:ncpus=4:mem=1000GB
#PBS -l walltime=100:00:00
#PBS -M jmif9945@hpc.sydney.edu.au
#PBS -m bea
#PBS -o update_db_2.log

# load modules
module load diamond
module load blast+
module load edirect
module load hmmer

# set path to databases
path_db=/scratch/VELAB/Databases

# Today is the database that will run today, it will be named with the following month
today=$(date -d "next month" +%b-%Y)

# past_file is the database that will be removed, it will be named with the previous month (two months before "$today")
past_file=$(date -d "last month" +%b-%Y)

# set edirect api key
export NCBI_API_KEY="CHANGE ME"


cd "$path_db"/Blast/

function buildDiamondNR {
    # Convert nr fasta blast database to Diamond format
    diamond makedb --in "$path_db"/Blast/nr."$today".gz \
        --db "$path_db"/Blast/nr."$today" \
        --taxonmap "$path_db"/Blast/prot.accession2taxid."$today" \
        --taxonnodes "$path_db"/Blast/taxdmp."$today"/nodes.dmp \
        --taxonnames "$path_db"/Blast/taxdmp."$today"/names.dmp
    # Remove old files
    diamond dbinfo --db "$path_db"/Blast/nr."$today"
    rm nr."$past_file".*
    
}

function buildRVDBHMM {
    # Convert RVDB HMM database to Diamond format
    diamond makedb --in "$path_db"/HMM/RVDB.prot."$today" \
        --db "$path_db"/Blast/HMM/RVDB.prot."$today" \
        --taxonmap "$path_db"/Blast/taxdmp."$today"/prot.accession2taxid \
        --taxonnodes "$path_db"/Blast/taxdmp."$today"/nodes.dmp \
        --taxonnames "$path_db"/Blast/taxdmp."$today"/names.dmp
    diamond dbinfo --db "$path_db"/Blast/HMM/RVDB.prot."$today"
    # Remove old files
    rm "$path_db"/HMM/RVDB.prot."$past_file".*
}

function buildVirusProt {
        diamond makedb --in "$path_db"/Blast/ALL_Virus_prot.NCBI."$today".fasta \
                --db "$path_db"/Blast/ALL_Virus_prot.NCBI."$today".dmnd
        diamond dbinfo --db "$path_db"/Blast/ALL_Virus_prot.NCBI."$today".dmnd
}

function buildHMMProfiles {
    cd "$path_db"/HMM/
    
    # Import HMM profiles of PFAM, RVDB, TIGRFAM, Gene3D, SUPERFAMILY and PIRSF databases

    #RVDB
    wget https://rvdb-prot.pasteur.fr/files/U-RVDBv15.1-prot.hmm.bz2 -O "$path_db"/HMM/RVDB.hmm.$today.bz2
    bzip2 -d RVDB.hmm.$today.bz2
    hmmpress RVDB.hmm.$today

    #PFAM
    wget ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam32.0/Pfam-A.hmm.gz -O  "$path_db"/HMM/Pfam.hmm.$today.gz
    gunzip Pfam.hmm.$today.gz
    hmmpress Pfam.hmm.$today

    #TIGRFAM
    wget ftp://ftp.jcvi.org/pub/data/TIGRFAMs/TIGRFAMs_15.0_HMM.tar.gz
    tar zxvpf TIGRFAMs_15.0_HMM.tar.gz | cat TIGR*.HMM > TIGRFAMs_15.0_HMM.$today.hmm
    hmmpress TIGRFAMs_15.0_HMM.$today.hmm
    rm TIGRFAMs_15.0_HMM.tar.gz

    #gene3d
    # This link looks broken
    wget ftp://orengoftp.biochem.ucl.ac.uk/gene3d/CURRENT_RELEASE/gene3d_hmmsearch/hmms.tar.gz
    tar zxvpf hmms.tar.gz
    mv hmms/main.hmm gene3d_hmmsearch.$today.hmm
    hmmpress gene3d_hmmsearch.$today.hmm

    #Clean up
    rm hmms.tar.gz
    rm -r hmms/

    #Import the Riboviria specific profiles from PFAM
    wget https://pfam.xfam.org/family/PF05919/hmm -O MitoVir_RdRp.PF05919.hmm.$today
    wget https://pfam.xfam.org/family/PF04197/hmm -O Birna_RdRp.PF04197.hmm.$today
    wget https://pfam.xfam.org/family/PF17501/hmm -O Viral_RdRp_C.PF17501.hmm.$today
    wget https://pfam.xfam.org/family/PF00680/hmm -O RdRP_1.PF00680.hmm.$today
    wget https://pfam.xfam.org/family/PF00978/hmm -O RdRP_2.PF00978.hmm.$today
    wget https://pfam.xfam.org/family/PF00998/hmm -O RdRP_3.PF00998.hmm.$today
    wget https://pfam.xfam.org/family/PF02123/hmm -O RdRP_4.PF02123.hmm.$today
    wget https://pfam.xfam.org/family/PF07925/hmm -O RdRP_5.PF07925.hmm.$today
    wget https://pfam.xfam.org/family/PF04196/hmm -O Bunya_RdRp.PF04196.hmm.$today
    wget https://pfam.xfam.org/family/PF00946/hmm -O Mononeg_RNA_pol.PF00946.hmm.$today
    wget https://pfam.xfam.org/family/PF05788/hmm -O Orbi_VP1.PF05788.hmm.$today
    wget https://pfam.xfam.org/family/PF08467/hmm -O Luteo_P1-P2.PF08467.hmm.$today
    wget https://pfam.xfam.org/family/PF00603/hmm -O Flu_PA.PF00603.hmm.$today
    wget https://pfam.xfam.org/family/PF12289/hmm -O Rotavirus_VP1.PF12289.hmm.$today
    wget https://pfam.xfam.org/family/PF00604/hmm -O Flu_PB2.PF00604.hmm.$today
    wget https://pfam.xfam.org/family/PF00602/hmm -O Flu_PB1.PF00602.hmm.$today
    wget https://pfam.xfam.org/family/PF00972/hmm -O Flavi_RdRp.PF00972.hmm.$today
    wget https://pfam.xfam.org/family/PF14314/hmm -O Methyltrans_Mon.PF14314
    wget https://pfam.xfam.org/family/PF12426/hmm -O RdRp.PF12426
    wget https://pfam.xfam.org/family/PF06478/hmm -O Corona_RPol_N.PF06478
    wget https://pfam.xfam.org/family/PF06317/hmm -O Arena_RNA_pol.PF06317
    wget https://pfam.xfam.org/family/PF05413/hmm -O Peptidase_C34.PF05413
    wget https://pfam.xfam.org/family/PF03035/hmm -O RNA_capsid.PF03035
    wget https://pfam.xfam.org/family/PF03431/hmm -O RNA_replicase_B.PF03431

    cat Birna_RdRp.PF04197.hmm.$today MitoVir_RdRp.PF05919.hmm.$today RdRP_1.PF00680.hmm.$today RdRP_2.PF00978.hmm.$today RdRP_3.PF00998.hmm.$today RdRP_4.PF02123.hmm.$today Viral_RdRp_C.PF17501.hmm.$today
    cat *.PF?????.hmm.$today > Pfam_RdRp_clan.hmm.$today
    hmmpress Pfam_RdRp_clan.hmm.$today

    #Import HMM profiles of VOG (http://eggnogdb.embl.de/#/app/viruses)
    wget http://eggnogdb.embl.de/download/eggnog_4.5/data/viruses/ssRNA/ssRNA.hmm.tar.gz -O ssRNA.hmm.$today.tar.gz
    wget http://eggnogdb.embl.de/download/eggnog_4.5/data/viruses/dsRNA/dsRNA.hmm.tar.gz -O dsRNA.hmm.$today.tar.gz
    wget http://eggnogdb.embl.de/download/eggnog_4.5/data/viruses/ssRNA_negative/ssRNA_negative.hmm.tar.gz -O ssRNA_negative.hmm.$today.tar.gz
    wget http://eggnogdb.embl.de/download/eggnog_4.5/data/viruses/ssRNA_positive/ssRNA_positive.hmm.tar.gz -O ssRNA_positive.hmm.$today.tar.gz
    tar zxvpf ssRNA.hmm.$today.tar.gz
    mv "hmm_files" "ssRNA_hmm_files.$today"
    cat ssRNA_hmm_files.$today/*.hmm > ssRNA_hmm_files.$today/ssRNA_hmm.$today
    hmmpress ssRNA_hmm_files.$today/ssRNA_hmm.$today
    cp *_hmm_files.$today/*_hmm.$today .
    tar zxvpf dsRNA.hmm.$today.tar.gz
    mv "hmm_files" "dsRNA_hmm_files.$today"
    cat dsRNA_hmm_files.$today/*.hmm > dsRNA_hmm_files.$today/dsRNA_hmm.$today
    hmmpress dsRNA_hmm_files.$today/dsRNA_hmm.$today
    tar zxvpf ssRNA_negative.hmm.$today.tar.gz
    mv "hmm_files" "ssRNAneg_hmm_files.$today"
    cat ssRNAneg_hmm_files.$today/*.hmm > ssRNAneg_hmm_files.$today/ssRNAneg_hmm.$today
    hmmpress ssRNAneg_hmm_files.$today/ssRNAneg_hmm.$today
    tar zxvpf ssRNA_positive.hmm.$today.tar.gz
    mv "hmm_files" "ssRNApos_hmm_files.$today"
    cat ssRNApos_hmm_files.$today/*.hmm > ssRNApos_hmm_files.$today/ssRNApos_hmm.$today
    hmmpress ssRNApos_hmm_files.$today/ssRNApos_hmm.$today
    mv *_hmm_files.$today/*_hmm.$today .
    rm -r *_hmm_files.$today/
    rm *.tar.gz
    rm *$past_file*

    #Import PROSITE viral RdRp profiles : for additional info, visit https://prosite.expasy.org/PDOC50507
    wget https://prosite.expasy.org/cgi-bin/aligner?psa=PS50524 -O PS50524.clustalW.$today
    wget https://prosite.expasy.org/cgi-bin/aligner?psa=PS50523 -O PS50523.clustalW.$today
    wget https://prosite.expasy.org/cgi-bin/aligner?psa=PS50522 -O PS50522.clustalW.$today
    wget https://prosite.expasy.org/cgi-bin/aligner?psa=PS50526 -O PS50526.clustalW.$today
    wget https://prosite.expasy.org/cgi-bin/aligner?psa=PS50525&color=1 -O PS50525.clustalW.$today
    wget https://prosite.expasy.org/cgi-bin/aligner?psa=PS50507&color=1 -O PS50507.clustalW.$today
    for i in PS50524 PS50523 PS50522 PS50526 PS50525 PS50507 ; do
    mv $i.clustalW. $i.clustalW.$today
    hmmbuild $i.hmm.temp.$today $i.clustalW.$today
    done
    cat *.hmm.temp > PROSITE_vir_RdRp.hmm.$today
    hmmpress PROSITE_vir_RdRp.hmm.$today

    ##Import annotation files from the VOGDB website
    #cd "$path_db"/HMM/VOGDB
    #wget http://fileshare.csb.univie.ac.at/vog/latest/vog.hmm.tar.gz -O vog.hmm.$today.tar.gz
    #wget wget http://fileshare.csb.univie.ac.at/vog/latest/vog.virusonly.tsv.gz -O vog.virusonly.$today.tsv.gz
    #wget http://fileshare.csb.univie.ac.at/vog/vog96/vog.lca.tsv.gz -O vog.lca.$today.tsv.gz
    #gunzip vog.virusonly.$today.tsv.gz
    #gunzip vog.lca.$today.tsv.gz
    #gunzip vog.hmm.$today.tar.gz
    #tar -xvf vog.hmm.$today.tar
    #cat *.hmm > vog.$today.hmm
    #hmmpress vog.$today.hmm
    #rm VOG?????.hmm
    #cat vog.virusonly.$today.tsv | awk -F'\t' '$2 == "1"' | cut -f1 > vog.hmm_virus_only_stringent.$today
    #cat vog.virusonly.$today.tsv | awk -F'\t' '$2 == "0"' | awk -F'\t' '$3 == "1"' | cut -f1 > vog.hmm_virus_only_middle.$today
    #cat vog.virusonly.$today.tsv | awk -F'\t' '$2 == "0"' | awk -F'\t' '$3 == "0"' | awk -F'\t' '$4 == "1"' | cut -f1 > vog.hmm_virus_only_low.$today
}

function buildSILVADB {
    # SILVAdb for SortmeRNA
    cd "$path_db"/SILVA-rRNA/
        module load sortmerna/2.1b
        wget https://github.com/biocore/sortmerna/raw/master/data/rRNA_databases/rfam-5.8s-database-id98.fasta -O $path_db/SILVA-rRNA/rfam-5.8s-database-id98.$today.fasta
        wget https://github.com/biocore/sortmerna/raw/master/data/rRNA_databases/rfam-5s-database-id98.fasta -O $path_db/SILVA-rRNA/rfam-5s-database-id98.$today.fasta
        wget https://github.com/biocore/sortmerna/raw/master/data/rRNA_databases/silva-euk-28s-id98.fasta -O $path_db/SILVA-rRNA/silva-euk-28s-id98.$today.fasta
        wget https://github.com/biocore/sortmerna/raw/master/data/rRNA_databases/silva-euk-18s-id95.fasta -O $path_db/SILVA-rRNA/silva-euk-18s-id95.$today.fasta
        wget https://github.com/biocore/sortmerna/raw/master/data/rRNA_databases/silva-bac-23s-id98.fasta -O $path_db/SILVA-rRNA/silva-bac-23s-id98.$today.fasta
        wget https://github.com/biocore/sortmerna/raw/master/data/rRNA_databases/silva-arc-16s-id95.fasta -O $path_db/SILVA-rRNA/silva-arc-16s-id95.$today.fasta
        wget https://github.com/biocore/sortmerna/raw/master/data/rRNA_databases/silva-bac-16s-id90.fasta -O $path_db/SILVA-rRNA/silva-bac-16s-id90.$today.fasta
        wget https://github.com/biocore/sortmerna/raw/master/data/rRNA_databases/silva-arc-23s-id98.fasta -O $path_db/SILVA-rRNA/silva-arc-23s-id98.$today.fasta
        indexdb --ref $path_db/SILVA-rRNA/silva-bac-16s-id90.$today.fasta,$path_db/SILVA-rRNA/silva-bac-16s.$today:$path_db/SILVA-rRNA/silva-bac-23s-id98.$today.fasta,$path_db/SILVA-rRNA/silva-bac-23s.$today:$path_db/SILVA-rRNA/silva-arc-16s-id95.$today.fasta,$path_db/SILVA-rRNA/silva-arc-16s.$today:$path_db/SILVA-rRNA/silva-arc-23s-id98.$today.fasta,$path_db/SILVA-rRNA/silva-arc-23s.$today:$path_db/SILVA-rRNA/silva-euk-18s-id95.$today.fasta,$path_db/SILVA-rRNA/silva-euk-18s.$today:$path_db/SILVA-rRNA/silva-euk-28s-id98.$today.fasta,$path_db/SILVA-rRNA/silva-euk-28s:$path_db/SILVA-rRNA/rfam-5s-database-id98.$today.fasta,$path_db/SILVA-rRNA/rfam-5s.$today:$path_db/SILVA-rRNA/rfam-5.8s-database-id98.$today.fasta,$path_db/SILVA-rRNA/rfam-5.8s.$today
    rm *$past_file*
}

current_month=$(date +%b-%Y) 

update_build_version() {
        local version=$1
        local file_path=$2
        sed -i "s/^update_build_version=.*/update_build_version=\"$version\"/" "$file_path"
    }


function buildRVDB {
    rvdb_build_version=25
    rvdb_current_version=$(cat /scratch/VELAB/Databases/Blast/rvdb_current_version)  # Read the number from the file

    if [ "$rvdb_current_version" -gt "$rvdb_build_version" ]; then
        echo "rvdb_current_version is greater than rvdb_build_version. Updating RVDB database"

        # build taxonomy files for the database
        python /scratch/VELAB/Databases/Blast/mapRVDB.py "$path_db"/Blast/prot.accession2taxid."$today"  "$path_db"/Blast/"U-RVDBv${rvdb_current_version}.0-prot.$today.fasta"

        # Update the database
        diamond makedb --in "$path_db"/Blast/"U-RVDBv${rvdb_current_version}.0-prot.$today.fasta" \
            --db "$path_db"/Blast/RVDB.prot.v"$rvdb_current_version"."$today" \
            --taxonmap "$path_db"/Blast/rvdb.accession2taxid."$current_month".txt \
            --taxonnodes "$path_db"/Blast/taxdmp."$today"/nodes.dmp \
            --taxonnames "$path_db"/Blast/taxdmp."$today"/names.dmp \
            -t /scratch/VELAB
        diamond dbinfo --db "$path_db"/Blast/RVDB.prot.v"$rvdb_current_version"."$today"

        # Database build successful, perform removal
        rm rvdb*"$past_file".*

        update_build_version "$rvdb_current_version" "/scratch/VELAB/Databases/update_db_2.pbs"

    else
        echo "rvdb_current_version is less than rvdb_build_version I don't know what to do ahahah maybe check this out"
    fi
}
function cleanUp {
    chmod g+wr "$path_db"/update_db_2.log
    chmod g+wr "$path_db"/update_db_2.log_usage
    rename ".log" ".$today.log" "$path_db"/update_db_2.log
    rename ".log" ".$today.log" "$path_db"/update_db_2.log_usage
}

# Run Block
buildRVDBHMM
buildVirusProt
buildHMMProfiles
buildSILVADB
buildRVDB