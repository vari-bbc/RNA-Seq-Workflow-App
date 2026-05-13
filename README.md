# RNA-Seq-Workflow-App

![Version](https://img.shields.io/npm/v/your-package)

## Launching the app

To run this app, go to: https://ondemand1.vai.zone/pun/sys/dashboard/batch_connect/sys/sh_shiny/session_contexts/new

select a local copy of this repository as the "path to your shiny project"

Select "bbc2/R/alt/R-4.6.0-setR_LIBS_USER" as the R version

Click "Launch"

Click "Connect to shiny app" 

## Using the app in 6 easy steps

> 💡 **Tip:** Follow along step by step

### Step 1 Upload a samplesheet - units.tsv

a units.tsv has 4 essential columns named exactly:

 - sample
 - group
 - fq1
 - fq2

Columns fq1 and fq2 are the names of each sample's read 1 and read 2 FASTQ files.

The group column can represent any group of interest (e.g. genotype, treatment, tissue). 

> 💡 **Critical!** The group column is used in step 5 to build differential expression contrasts

Additional columns by any name can also be included. 

See https://github.com/vari-bbc/rnaseq_workflow for full details.

#### Example samplesheet: units.tsv
| sample          | group        | fq1  | fq2       | patient   |
|---------------|-------------|-------------|----------------|----------|
| o1 | ovary    | o1_R1.fastq.gz     | o1_R2.fastq.gz       | a   |
| o2     | ovary    | o2_R1.fastq.gz     | o2_R2.fastq.gz  | b   |
| e1   | endometrium     | e1_R1.fastq.gz  | e1_R2.fastq.gz         | a |
| e2     | endometrium     | e2_R1.fastq.gz     | e2_R2.fastq.gz          | b   |
| b1   | blood     | b1_R1.fastq.gz  | b1_R2.fastq.gz         | a |
| b2     | blood     | b2_R1.fastq.gz     | b2_R2.fastq.gz          | b   |

### Step 2 Select FASTQ Folder

You must now select a folder containing the fq1 and fq2 files in the samplesheet.

### Step 3 Select Output Folder

 - Select an output folder where the RNAseq workflow will be run.
 - Once selected, click 'Download Workflow' to initiate.

### Step 4 Workflow Options

Click 'Compile Config' following selection of configuration options.

> 💡 **Tip:** Select the correct species!

### Step 3. Select Comparisons 

Click 'Build contrasts from units.tsv group column'.

### Step 4. Run Workflow

Click 'Start Snakemake RNAseq Workflow'


