#!/bin/bash

#Usage pre-process.sh R1.fastq.gz R2.fastq.gz SampleName NumbOfCores
#As an example: time ./pre-process.sh Pool-3-1_FKDL210225623-1a-AK25938-AK25939_1.clean.fq.gz Pool-3-1_FKDL210225623-1a-AK25938-AK25939_2.clean.fq.gz FKDL210225623 24
R1=$1 		      #R1.fastq.gz
R2=$2 		      #R2.fastq.gz
SampleName=$3	  #Name associated to the sample
JTrim=$4	      #Number of cores to use

NumOfArgs=4	#At least 4 parameters are needed
Trimgalore="trim-galore.log"
logfile="pre-process.log"
refSLR138="../DBs/SILVA/SILVA.138.1.LSU.fasta" # slr138.fasta
refSSR138="../DBs/SILVA/SILVA.138.1.SSU.fasta" #ssr138.fasta
#SilvaDB_idx="/DBs/SILVA/idx/"

echo "Starting the pre-process task with the following arguments: $R1 $R2 $SampleName $JTrim"

echo "1. Executing Trimgalore"
##Remove adapters using TrimGalore
echo -e "$(date) Executing pimgavir with the following arguments: R1 is $R1, R2 is $R2" > $logfile 2>&1
echo -e "$(date) Removing adapters using Trim Galore using $JTrim cores\n" >> $logfile 2>&1

#Command to execute
trim_galore -j $JTrim --length 80 --paired $R1 $R2 -q 30 --fastqc > $Trimgalore 2>&1
echo -e "$(date) Trim Galore session finished \n" >> $logfile 2>&1

scp -r *val_*fq.gz nas3:/data3/projects/evomics/pimgavir-output/
scp -r *_trimming_report.txt  nas3:/data3/projects/evomics/pimgavir-output/
scp -r *.html nas3:/data3/projects/evomics/pimgavir-output/
scp -r *.zip nas3:/data3/projects/evomics/pimgavir-output/

##Rename files
echo -e "$(date) Remaming files \n" >> $logfile 2>&1
trimmedR1=$SampleName"_R1_trimmed.fq.gz"
trimmedR2=$SampleName"_R2_trimmed.fq.gz"

#Command to execute:
if [[ "$R1" == "*.fq.gz" ]]; then 
	mv `basename $R1 .fq.gz`_val_1.fq.gz $trimmedR1
	mv `basename $R2 .fq.gz`_val_2.fq.gz $trimmedR2
else
	mv `basename $R1 .fastq.gz`_val_1.fq.gz $trimmedR1
	mv `basename $R2 .fastq.gz`_val_2.fq.gz $trimmedR2
fi


echo "2. Executing SortmeRNA"
##Remove ribosomal RNA using sortmeRNA -- ONLY paired reads are saved on the output file
echo -e "$(date) Remove ribosomal RNA using SortMeRNA \n" >> $logfile 2>&1
NotrRNAReads=$SampleName"_not_rRNA"
rRNAReads=$SampleName"_rRNA"
WorkDir=$PWD"/sortmeRNA_wd"

#Command to execute
echo -e "$(date) Running SortMeRNA \n" >> $logfile 2>&1
echo "Removing ribosomal RNA using sortmerna with the following parameters: sortmerna --ref $refSLR138 --ref $refSSR138 --reads $trimmedR1 --reads $trimmedR2 --num_alignments 1 --workdir $WorkDir --fastx --aligned $rRNAReads --paired_out --other $NotrRNAReads --threads $JTrim"

##OLD VERSION, using PRINSEQ
#sortmerna --ref $refSLR138 --ref $refSSR138 --reads $PrinseqFiles"_1.fastq" --reads $PrinseqFiles"_2.fastq" --num_alignments 1 --workdir $WorkDir --fastx --aligned $rRNAReads --paired_out --other $NotrRNAReads --threads $JTrim #>> $logfile 2>&1

sortmerna --ref $refSLR138 --ref $refSSR138 --reads $trimmedR1 --reads $trimmedR2 --num_alignments 1 --workdir $WorkDir --fastx --aligned $rRNAReads --paired_out --other $NotrRNAReads --threads $JTrim #>> $logfile 2>&1
