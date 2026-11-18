# RNA-Seq-Workflow-App

A Shiny app that sets up and launches the BBC
[rnaseq_workflow](https://github.com/vari-bbc/rnaseq_workflow) (Snakemake) on the
VAI HPC without using the command line. It walks you through:

1. uploading a samplesheet,
2. choosing paired-end or single-end and pointing the app at the folder(s)
   containing your FASTQ files,
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
| `fq2` | optional | File **name** (not path) of the read 2 FASTQ. Not used for single-end data. |

A sample with several FASTQ pairs (several runs, lanes or folders) may be
listed on several rows, one per pair, with the same `sample` and `group`.
| anything else | optional | Extra variables (genotype, treatment, batch, tissue …) that can be used for comparisons, covariates or filtering. |

A Genomics Core library template (columns `Library.Name`, `Library.ID`,
`Library.Prep.Kit`) is also recognised: `Library.Name` is used as `sample`, and
at least one of `genotype`, `cell.line`, `cell.type`, `treatment`, `batch`,
`condition`, `group` must be present.

See the [rnaseq_workflow README](https://github.com/vari-bbc/rnaseq_workflow)
for full details on the samplesheet.

### Step 2 – Select FASTQ folder(s)

First choose **Paired End** or **Single End** (*Paired-end or single-end
sequencing library*). This decides how FASTQs are matched below and is
written to `config.yaml` as `PE_or_SE`. Changing it re-runs the FASTQ check.
It cannot be changed after the workflow has been downloaded (step 3).

Then click **Add folder with FASTQ files** and choose a folder.

**FASTQs in more than one folder?** Click **Add folder with FASTQ files** again
for each additional folder. All selected folders are listed under the buttons
and are searched together. Use **Clear selected folders** to start over.

How the files are matched:

- **Only files directly inside each selected folder** are searched – not
  subfolders. Add each subfolder that holds FASTQs separately.
- **If the samplesheet has `fq1`/`fq2` columns**, each file name must match
  exactly, and may be in any of the selected folders.
- **If it does not**, files are found from the sample name. For **paired-end**,
  a file is used for a sample when its name
  - starts with the **sample name**, optionally followed by `_` and anything,
  - then `_R1` or `_1` (read 1) / `_R2` or `_2` (read 2), optionally followed by `_` and anything,
  - ends with `.fastq.gz` or `.fq.gz`.

  | Sample | Matches |
  |--------|---------|
  | `A` | `A_R1.fastq.gz`, `A_S1_L001_R1_001.fastq.gz`, `A_1.fq.gz` |
  | `A` | **not** `A1_R1.fastq.gz` (no `_` after the sample name) |

  For **single-end**, any file whose name is the sample name, optionally
  followed by `_` and anything, then `.fastq.gz`/`.fq.gz`, is used
  (`S1.fastq.gz`, `S1_R1_001.fastq.gz`, `S1_L002.fq.gz`). If a folder holds
  read 1 *and* read 2 files of the same pair, the read 2 files are skipped and
  you are warned – the data are probably paired-end.

  The `fq1`/`fq2` columns are then filled in; check them with
  **Show/edit Sample Sheet**.
- **Single-end:** only `fq1` is needed (an `fq2` column in the samplesheet is
  ignored, with a warning); `fq2` is left empty in `units.tsv`.
- **Several FASTQ pairs (or single-end files) per sample are supported.** Every pair (or file) found for a
  sample, in any selected folder, becomes **its own row** in `units.tsv`; the
  workflow trims each pair and combines them per sample. For example, 10
  samples of which 2 were sequenced on two runs give 12 rows. Read 1 and read 2
  are paired when they are in the same folder and their names differ only in
  the read number (`A_L001_R1_001` ↔ `A_L001_R2_001`).
- **The same file name in different folders is fine** (e.g. two runs that both
  contain `S1_R1_001.fastq.gz`); they are treated as different pairs.
- If a file name could belong to two samples (samples `A` and `A_2`, file
  `A_2_R1.fastq.gz`), it is given to the longer sample name (`A_2`).
- In `units.tsv`, `fq1`/`fq2` are written as `<folder link>/<file name>`, e.g.
  `run1/S1_R1_001.fastq.gz` (see step 3).

When every sample is found, a table shows each sample's files and the folder
each came from. If something is missing, the samples with problems are shown.
Fix them by adding another folder, renaming files, or editing the samplesheet
(**Show/edit Sample Sheet**), then click **Add folder with FASTQ files** and
re-select any folder to re-run the check. Each check starts again from one row
per sample and searches all selected folders, so adding a folder picks up both
missing samples and extra pairs of samples already found.

### Step 3 – Select the analysis folder

Choose the (empty, writable) folder where the workflow will run, then click
**Download Snakemake workflow from github**. This:

- clones `rnaseq_workflow` into `<analysis folder>/rnaseq_workflow/`
  (the step is refused if that folder already exists and is not empty),
- symlinks **each selected FASTQ folder** into `rnaseq_workflow/raw_data/`,
  named after the folder (made unique as `fastq`, `fastq_1`, … if two selected
  folders have the same name). E.g. `raw_data/run1 -> /varidata/…/run1`. The
  original files are not moved or copied,
- writes the samplesheet to `rnaseq_workflow/config/samplesheet/units.tsv`,
  one row per FASTQ pair (single-end: per file, `fq2` empty), with `fq1`/`fq2` relative to `raw_data/`:

  ```
  sample  group  fq1                          fq2                          RG
  S1      ctl    run1/S1_R1_001.fastq.gz      run1/S1_R2_001.fastq.gz
  S1      ctl    run2/S1_R1_001.fastq.gz      run2/S1_R2_001.fastq.gz
  S2      trt    run1/S2_R1_001.fastq.gz      run1/S2_R2_001.fastq.gz
  ```

### Step 4 – Save workflow options

| Setting | Notes |
|---------|-------|
| Species & annotation | Pick the correct genome build and annotation. |
| Reference version | `latest` or a dated BBC reference release. |
| False discovery rate | Default 0.01. |
| Run VisBigWig / Run RSeQC | Optional coverage tracks / QC. |

Paired-end/single-end is chosen in step 2 and shown here for reference.

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
| "Single-end selected, but … read 2 file(s) … were found and skipped" | The folder holds paired-end data. Choose **Paired End**, unless you really want to use read 1 only. |
| "no read 2 partner for …" / "no read 1 partner for …" | A read 1 file has no read 2 file with the same name (apart from the read number) in the same folder, or vice versa. Check for missing/renamed files. |
| A sample has more rows than expected | Each FASTQ pair is a row. Check the `source_folder` column in step 2 – a folder may contain extra files for that sample, or the same data may be in two selected folders (it would then be counted twice). |
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
  gives each folder a unique link name, and returns `units` with **one row per
  FASTQ pair** and `fq1`/`fq2` = `<link name>/<file>`, plus `folder_links`
  (link name → folder) and `fastq_paths` (fq value → full path). The old
  `fastqDir =` argument still works.
- The library type (`input$pairedSingle`, step 2) is passed to
  `check_FASTQs(paired = )`; the check runs in `run_fastq_check()`, called
  when a folder is added and when the toggle changes. `globals$libraryType`
  records the type of the last check and is what `build_YAML()` receives,
  so `config.yaml` and `units.tsv` always agree. `units.tsv` is written with
  `na = ""` so `fq2` is empty for single-end, as rnaseq_workflow expects.
- Before every check the app calls `units_for_recheck()` to collapse the
  table back to one row per sample (autodetect mode) or to bare file names
  (explicit mode), so each check searches all folders from scratch.
  Autodetect vs explicit is decided from the uploaded samplesheet's columns
  (`fq1`+`fq2` for paired-end, `fq1` for single-end); `fq2` cleared by a
  single-end check is restored from the uploaded samplesheet when switching back.
- At **Download Snakemake workflow**, each folder in `globals$folderLinks` is
  symlinked as `raw_data/<link name>`; rnaseq_workflow reads
  `config$raw_data_path + fq1` and merges a sample's rows via its
  `group_index` (rows per sample) logic. It requires `fq1` to be unique,
  which the folder prefix guarantees.

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
