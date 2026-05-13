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

sample
group
fq1
fq2

Columns fq1 and fq2 are filepaths to each sample's read [12] FASTQ files.
Group values can be set as e.g. genotype, treatment, condition
Additional columns can also be included such as batch, condition

#### Example units.tsv
| sample          | group        | fq1  | fq2       | patient   |
|---------------|-------------|-------------|----------------|----------|
| o1 | ovary    | /filepath/to/o1_R1.fastq.gz     | /filepath/to/o1_R2.fastq.gz       | a   |
| o2     | ovary    | /filepath/to/o2_R1.fastq.gz     | /filepath/to/o2_R2.fastq.gz  | b   |
| e1   | endometrium     | /filepath/to/e1_R1.fastq.gz  | /filepath/to/e1_R2.fastq.gz         | a |
| e2     | endometrium     | /filepath/to/e2_R1.fastq.gz     | /filepath/to/e2_R2.fastq.gz          | b   |
| b1   | blood     | /filepath/to/b1_R1.fastq.gz  | /filepath/to/b1_R2.fastq.gz         | a |
| b2     | blood     | /filepath/to/b2_R1.fastq.gz     | /filepath/to/b2_R2.fastq.gz          | b   |

Step 1.2 Select FASTQ Input Folder (e.g. 'HPC Primary' -> genomicscore -> XXXX.Lab -> PRXXXXXX_NNNN).

Step 1.3 Select Workflow Output Folder. 

Step 1.4 Click 'Validate Samplesheet, FASTQs, Output Folder' -- Follow any messages

### Step 2. Options

Change configuration options as needed. Click 'Compile Config'

### Step 3. Select Comparisons 

Click 'Autogenerate contrasts from units.tsv'

### Step 4. Run Workflow

Click 'Start Snakemake RNAseq Workflow'


