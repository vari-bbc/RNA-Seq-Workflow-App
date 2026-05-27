# RNA-Seq-Workflow-App

![Version](https://img.shields.io/npm/v/your-package)

## Launching the app

To run this app, go to: https://ondemand1.vai.zone/pun/sys/dashboard/batch_connect/sys/sh_shiny/session_contexts/new

Select a local copy of this repository as the "path to your shiny project"

Select "bbc2/R/alt/R-4.6.0-setR_LIBS_USER" as the R version

Click "Launch"

Click "Connect to shiny app" 

## Using the app in 6 easy steps

When started you will have an option to [start a new workflow](#start-new) or [check one that has already been started](#already-exists).

### Start New

#### Select Samplesheet

The samplesheet must include two columns: "sample" & "group". The group column designates sample groups to be compared during the differential expression workflow. Columns named "fq1" and "fq2" designate the input fastq file names. These columns are needed for the workflow, but optional for the input samplesheet; if they are not included, an attempt to find the FASTQ files will be made after a FASTQ folder is selected. Input file must have a .tsv (tab-separated values) or .csv (comma-separated values) extension.'

Columns fq1 and fq2 are the names of each sample's read 1 and read 2 FASTQ files.

The group column can represent any group of interest (e.g. genotype, treatment, tissue). 

See https://github.com/vari-bbc/rnaseq_workflow for full details on the samplesheet.

##### Example samplesheet
| sample          | group        | fq1  | fq2       | patient   |
|---------------|-------------|-------------|----------------|----------|
| o1 | ovary    | o1_R1.fastq.gz     | o1_R2.fastq.gz       | a   |
| o2     | ovary    | o2_R1.fastq.gz     | o2_R2.fastq.gz  | b   |
| e1   | endometrium     | e1_R1.fastq.gz  | e1_R2.fastq.gz         | a |
| e2     | endometrium     | e2_R1.fastq.gz     | e2_R2.fastq.gz          | b   |
| b1   | blood     | b1_R1.fastq.gz  | b1_R2.fastq.gz         | a |
| b2     | blood     | b2_R1.fastq.gz     | b2_R2.fastq.gz          | b   |

#### Select folder with FASTQ files

You must now select a folder containing the FASTQ files. If columns fq1 and fq2 were included in the samplesheet, then the filenames must match *exactly*. If columns fq1 and fq2 were *not* included, then an attempt is made to associate samples to files in the selected folder. To be found, FASTQ files *must* start with the **sample name followed by an underscore**; end in fastq.gz or fq.gz; and have a _1 or _R1 to designate fq1 and _2/_R2 for fq2.)'

#### Select a folder to run the analysis

Select an output folder where the RNAseq workflow will be run. Once selected, click 'Download Snakemake workflow from github' to clone the git repo. This step will also update the cloned repo's samplesheet and link in the FASTQ files where they are needed.

#### Save workflow options

Specify configuration options then click 'Save Settings'

> 💡 **Tip:** Select the correct genome build and annotation!

#### Build differential expression comparisons

Pairwise comparisons between all levels of column group will be made by default. For more complicated contrasts and help with this step, contact [bioinfo@vai.org](mailto:bioinfo@vai.org)

#### Start Workflow

Click 'Start Snakemake RNAseq Workflow'

From this tab you can monitor the workflow's progress or close the session and click 'Already Exists' when you restart the app.

### Already Exists

#### Select an existing workflow

Specify the folder you selected to run your analysis.

On the next tab, you have the option to 

 - check the status of your workflow job on the HPC
 - check the Snakemake workflow logs
 - download the RNAseq workflow results.



