# RNA-Seq-Workflow-App

A Shiny app that sets up and launches the BBC
[rnaseq_workflow](https://github.com/vari-bbc/rnaseq_workflow) (Snakemake) on the
VAI HPC without using the command line. It walks you through:

1. uploading a samplesheet,
2. pointing the app at the folder(s) containing your FASTQ files,
3. choosing an analysis folder (the workflow is cloned there),
4. choosing the genome and analysis settings,
5. defining differential-expression comparisons,
6. submitting the workflow to Slurm and monitoring it.

It can also re-open a workflow you started earlier to check its status, read
logs, and explore results (PCA plot, heatmap).

For help contact [bioinfo@vai.org](mailto:bioinfo@vai.org).

---

## Contents

- [Launching the app](#launching-the-app)
- [Before you start](#before-you-start)
- [Start New](#start-new)
  - [Step 1 – Select samplesheet](#step-1--select-samplesheet)
  - [Step 2 – Select FASTQ folder(s)](#step-2--select-fastq-folders)
  - [Step 3 – Select the analysis folder](#step-3--select-the-analysis-folder)
  - [Step 4 – Save workflow options](#step-4--save-workflow-options)
  - [Step 5 – Build differential expression comparisons](#step-5--build-differential-expression-comparisons)
  - [Step 6 – Start the workflow](#step-6--start-the-workflow)
- [Already Exists](#already-exists)
- [Troubleshooting](#troubleshooting)
- [Developer notes](#developer-notes)

---

## Launching the app

1. Go to Open OnDemand: <https://ondemand1.vai.zone/pun/sys/dashboard/batch_connect/sys/sh_shiny/session_contexts/new>
2. Select **RNA-seq Workflow** from the drop-down.
3. Click **Launch**, wait for the session to start, then click **Connect to shiny app**.

On the first screen choose **Start New** to set up a new analysis, or
**Already Exists** to check on one you started before.

## Before you start

You need:

- **A samplesheet** (see below).
- **Your FASTQ files**, gzipped (`.fastq.gz` or `.fq.gz`), readable by you on the
  HPC. They may be in **one folder or spread across several folders**
  (e.g. several sequencing runs).
- **An empty analysis folder** that you can write to, e.g. under your lab's
  `/varidata/research/projects/<lab>/` folder.

The folder browser opens at one of these roots: *HPC Home Directory*,
*Local Home Directory*, *HPC Lab Folders* (`/varidata/research/projects/`) and
*HPC Temp Folder* (`/varidata/researchtemp/hpctmp/`).

## Start New

### Step 1 – Select samplesheet

Accepted formats: `.csv`, `.tsv`, `.txt` (tab-separated), `.xls`, `.xlsx`
(first sheet is used). `Necessary Files/SampleTemplate.xlsx` is a template.

| Column | Required? | Meaning |
|--------|-----------|---------|
| `sample` | yes | Unique sample name. If `fq1`/`fq2` are omitted, FASTQ file names must start with this (see step 2). |
| `group` | yes | Sample group used for differential expression. |
| `fq1` | optional | File **name** (not path) of the read 1 FASTQ. |
| `fq2` | optional | File **name** (not path) of the read 2 FASTQ. |
| anything else | optional | Extra variables (genotype, treatment, batch, tissue …) that can be used for comparisons, covariates or filtering. |

A Genomics Core library template (columns `Library.Name`, `Library.ID`,
`Library.Prep.Kit`) is also recognised: `Library.Name` is used as `sample`, and
at least one of `genotype`, `cell.line`, `cell.type`, `treatment`, `batch`,
`condition`, `group` must be present.

See the [rnaseq_workflow README](https://github.com/vari-bbc/rnaseq_workflow)
for full details on the samplesheet.

### Step 2 – Select FASTQ folder(s)

Click **Add folder with FASTQ files** and choose a folder.

**FASTQs in more than one folder?** Click **Add folder with FASTQ files** again
for each additional folder. All selected folders are listed under the buttons
and are searched together. Use **Clear selected folders** to start over.

How the files are matched:

- **Only files directly inside each selected folder** are searched – not
  subfolders. Add each subfolder that holds FASTQs separately.
- **If the samplesheet has `fq1`/`fq2` columns**, each file name must match
  exactly, and may be in any of the selected folders.
- **If it does not**, files are found from the sample name. A file is used for a
  sample when its name
  - starts with the **sample name**, optionally followed by `_` and anything,
  - then `_R1` or `_1` (read 1) / `_R2` or `_2` (read 2), optionally followed by `_` and anything,
  - ends with `.fastq.gz` or `.fq.gz`.

  | Sample | Matches |
  |--------|---------|
  | `A` | `A_R1.fastq.gz`, `A_S1_L001_R1_001.fastq.gz`, `A_1.fq.gz` |
  | `A` | **not** `A1_R1.fastq.gz` (no `_` after the sample name) |

  The `fq1`/`fq2` columns are then filled in; check them with
  **Show/edit Sample Sheet**.
- **A file name must not exist in more than one selected folder.** All FASTQs
  are linked into one `raw_data/` folder, so duplicates are ambiguous and the
  app will ask you to change the folder selection.
- Each sample must match **exactly one** read 1 and one read 2 file. One
  sequencing library split over several lanes/files must be concatenated first.

When every sample is found, a table shows each sample's files and the folder
each came from. If something is missing, the samples with problems are shown.
Fix them by adding another folder, renaming files, or editing the samplesheet
(**Show/edit Sample Sheet**), then click **Add folder with FASTQ files** and
re-select any folder to re-run the check.

### Step 3 – Select the analysis folder

Choose the (empty, writable) folder where the workflow will run, then click
**Download Snakemake workflow from github**. This:

- clones `rnaseq_workflow` into `<analysis folder>/rnaseq_workflow/`
  (the step is refused if that folder already exists and is not empty),
- symlinks every FASTQ named in the samplesheet – from whichever selected
  folder it was found in – into `rnaseq_workflow/raw_data/` (the original
  files are not moved or copied),
- writes the samplesheet to `rnaseq_workflow/config/samplesheet/units.tsv`.

### Step 4 – Save workflow options

| Setting | Notes |
|---------|-------|
| Species & annotation | Pick the correct genome build and annotation. |
| Reference version | `latest` or a dated BBC reference release. |
| False discovery rate | Default 0.01. |
| Paired-end / single-end | Must match your library. |
| Run VisBigWig / Run RSeQC | Optional coverage tracks / QC. |

Click **Save Settings**; this writes `rnaseq_workflow/config/config.yaml`.

> 💡 **Tip:** Select the correct genome build and annotation!

### Step 5 – Build differential expression comparisons

Select a samplesheet column to compare. You can create all pairwise
comparisons between its levels, or build comparisons one at a time
(relative group vs baseline group; positive fold change = higher in the
relative group), optionally with a covariate and/or restricted to a subset of
samples (e.g. treated vs untreated only in WT).

For more complicated designs (interaction terms, several covariates) edit
`rnaseq_workflow/config/samplesheet/comparisons.tsv` directly with the
appropriate `group_reg_formula`, or contact [bioinfo@vai.org](mailto:bioinfo@vai.org).

### Step 6 – Start the workflow

Click **Start Snakemake RNAseq Workflow**. The workflow is submitted to Slurm;
you will get an email at `<username>@vai.org` when it finishes. From this tab
you can refresh the job status, view the Snakemake logs, open the results
folder and download the final report. You may close the app – use
**Already Exists** later to check on the job.

## Already Exists

Select the analysis folder you chose in step 3. You can then:

- check the status of the workflow's Slurm job,
- read the Snakemake logs,
- open/download the results and final report,
- generate a PCA plot and an interactive heatmap.

## Troubleshooting

| Problem | What to do |
|---------|-----------|
| "Selected FASTQ Directory Not Readable" | You lack read permission on the folder; ask the data owner or choose another folder. |
| "fq1/fq2 files missing" | Check the sample names vs file names (see matching rules), add the folder holding the missing files, or edit `fq1`/`fq2`. |
| "Same FASTQ file name in more than one folder" | Click **Clear selected folders** and select folders that do not contain the same file twice. |
| A sample matches several files | Sample names that are prefixes of others with `_` (e.g. `A` and `A_2`), or reads split over lanes. Add explicit `fq1`/`fq2` columns, or concatenate lanes. |
| "rnaseq_workflow repository already exists" | Choose a new analysis folder or remove the old `rnaseq_workflow/`. |
| Workflow job failed | Read the STDERR log in step 6 / Already Exists and contact [bioinfo@vai.org](mailto:bioinfo@vai.org). |

## Developer notes

### Repository layout

| Path | Purpose |
|------|---------|
| `app.R` | UI and server. Server sections are numbered to match the steps (e.g. `## 2.0 Select FASTQ Folder`). |
| `Functions/` | Helpers, all auto-sourced at start-up by `sourceFunctions()`. |
| `Functions/Updated Shiny RMD Standards.R` | Shared BBC Shiny UI helpers (`navButton`, `navSelect`, `activateItems`, …). |
| `Functions/build_units_TSV.R` | Standardises the uploaded samplesheet (step 1). |
| `Functions/check_FASTQs.R` | Finds/validates FASTQs across one or more folders (step 2). |
| `Functions/build_YAML.R`, `check_built_YAML.R` | Write `config.yaml` from `Necessary Files/master_config.yaml` (step 4). |
| `Necessary Files/` | `master_config.yaml` (per-species reference paths + parameters), `SampleTemplate.xlsx`. |
| `tests/` | Unit tests (base R). |
| `www/` | Static assets (logo). |
| `docs/VAI_HPC_AI_AGENTS.md` | VAI HPC rules for AI coding agents (see `AGENTS.md`). |

### Multiple FASTQ folders – implementation

- `globals$fastqDirs` (character vector) holds every folder selected with
  **Add folder with FASTQ files**; **Clear selected folders** resets it.
- `check_FASTQs(units, fastqDirs)` lists each folder once (non-recursive),
  builds a file-name → full-path index, flags names present in more than one
  folder, and returns `fastq_paths` (file name → full source path) for every
  FASTQ the samplesheet uses. The old `fastqDir =` argument still works.
- At **Download Snakemake workflow**, only the files in `globals$fastqPaths`
  are symlinked into `raw_data/` (previously every FASTQ in the single folder
  was linked).

### Running the tests

```bash
module load bbc2/R/alt/R-4.6.0-setR_LIBS_USER
cd /path/to/RNA-Seq-Workflow-App
Rscript tests/test_check_FASTQs.R
```

### Deploying / testing on Open OnDemand

Apps offered in the OnDemand "Shiny" form are listed in
`/varidata/research/software/BBC/shiny_apps/shiny_list.csv`
(`path,r_module,name,runtime_hours,partition`). To test a branch, clone the
repo into a new folder next to the production app, check out the branch, and
add a row for it with a distinct `name`. Remove the row when finished.
