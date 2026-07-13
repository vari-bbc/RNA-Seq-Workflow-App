# RNA-Seq-Workflow-App

## Launching the app

To run this app, go to: https://ondemand1.vai.zone/pun/sys/dashboard/batch_connect/sys/sh_shiny/session_contexts/new

Select a 'RNA-seq App' from the drop down.

Click "Launch"

Click "Connect to shiny app" 

## Using the App

When started you will have an option to [start a new workflow](#start-new) or [check one that was already started](#already-exists).

### Start New

#### Select Samplesheet

The samplesheet must include two columns: "sample" & "group". The group column designates sample groups to be compared during the differential expression workflow. Columns named "fq1" and "fq2" designate the input fastq file names. These columns are needed for the workflow, but optional for the input samplesheet; if they are not included, an attempt to find the FASTQ files will be made after a FASTQ folder is selected. Input file must have a .tsv (tab-separated values) or .csv (comma-separated values) extension.'

Columns fq1 and fq2 are the names of each sample's read 1 and read 2 FASTQ files.

The group column can represent any group of interest. Other columns can be included as needed (e.g. genotype, treatment, tissue).

See https://github.com/vari-bbc/rnaseq_workflow for full details on the samplesheet.

#### Select folder with FASTQ files

You must now select a folder containing the FASTQ files. If columns fq1 and fq2 were included in the samplesheet, then the filenames must match *exactly*. If columns fq1 and fq2 were *not* included, then an attempt is made to associate samples to files in the selected folder. To be found, FASTQ files *must* start with the **sample name followed by an underscore**; end in fastq.gz or fq.gz; and have a _1 or _R1 to designate fq1 and _2/_R2 for fq2.)'

#### Select a folder to run the analysis

Select an output folder where the RNAseq workflow will be run. Once selected, click 'Download Snakemake workflow from github' to clone the git repo. This step will also update the cloned repo's samplesheet and link in the FASTQ files where they are needed.

#### Save workflow options

Specify configuration options then click 'Save Settings'

> 💡 **Tip:** Select the correct genome build and annotation!

#### Build differential expression comparisons

Select a column of interest from your samplesheet. Pairwise comparisons between all levels of the selected column can be made by default. You can also build individual comparisons with the option to select a covariate and specify filtering criteria for select comparisons.

For more complicated contrasts including interaction terms or multiple covariates, edit the comparisons.tsv directly with the correct group_reg_formula. For help contact [bioinfo@vai.org](mailto:bioinfo@vai.org)

#### Start Workflow

Click 'Start Snakemake RNAseq Workflow'

From this tab you can monitor the workflow's progress or close the session and click 'Already Exists' when you restart the app to get information on the job status. For help contact [bioinfo@vai.org](mailto:bioinfo@vai.org) 

You will receive an email when the snakemake workflow is done running. 
















### Already Exists

#### Select an existing workflow

Specify the folder you selected to run your analysis.

On the next tab, you have the option to 

 - check the status of your workflow job on the HPC
 - check the Snakemake workflow logs
 - download the RNAseq workflow results.



