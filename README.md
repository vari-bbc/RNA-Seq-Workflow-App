# RNA-Seq-Workflow-App

## Launching the app

To run this app, go to: https://ondemand1.vai.zone/pun/sys/dashboard/batch_connect/sys/sh_shiny/session_contexts/new

select a local copy of this repository as the "path to your shiny project"

Select "bbc2/R/alt/R-4.6.0-setR_LIBS_USER" as the R version

Click "Launch"

Click "Connect to shiny app" 

## Using the app

### Step 1. Input Files

Step 1.1 Upload Genomics Library Export CSV.

Step 1.2 Select FASTQ Input Folder (e.g. 'HPC Primary' -> genomicscore -> XXXX.Lab -> PRXXXXXX_NNNN).

Step 1.3 Select Workflow Output Folder. 

Step 1.4 Click 'Validate Samplesheet, FASTQs, Output Folder' -- Follow any messages

### Step 2. Options

Change configuration options as needed. Click 'Compile Config'

### Step 3. Select Comparisons 

Click 'Autogenerate contrasts from units.tsv'

### Step 4. Run Workflow

Click 'Start Snakemake RNAseq Workflow'


