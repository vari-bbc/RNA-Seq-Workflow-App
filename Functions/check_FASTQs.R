#' Locate and validate FASTQ files for every sample, across one or more folders
#'
#' Given the samplesheet (`units`) and one or more FASTQ folders, find the
#' read 1 / read 2 FASTQ file of every sample and report anything that cannot
#' be found or is ambiguous.
#'
#' Two modes, chosen automatically:
#'
#' 1. **Explicit** - the samplesheet already has `fq1` and `fq2` columns.
#'    Each value is a file *name* (basename, e.g. `S1_R1_001.fastq.gz`). The
#'    file may live in any of the selected folders.
#' 2. **Autodetect** - `fq1`/`fq2` columns are absent. For each sample, a file
#'    is matched when its name
#'      * starts with the sample name, optionally followed by `_<anything>`,
#'      * then `_1`, `_R1` (read 1) or `_2`, `_R2` (read 2), and
#'      * ends in `.fastq.gz` or `.fq.gz`.
#'    e.g. `S1_R1.fastq.gz`, `S1_S7_L001_R1_001.fastq.gz`, `S1_1.fq.gz`.
#'    The `fq1`/`fq2` columns are then filled in.
#'
#' Folders are searched non-recursively (only files directly inside each
#' selected folder). Because the workflow links all FASTQs into a single flat
#' `raw_data/` folder, a file name must be unique across the selected folders;
#' a name present in more than one folder is reported as a duplicate and the
#' affected samples are treated as not found.
#'
#' @param units data.frame samplesheet; must contain a `sample` column, and
#'   optionally `fq1` and `fq2`.
#' @param fastqDirs character vector of one or more folder paths to search.
#' @param fastqDir deprecated single-folder argument, kept for backwards
#'   compatibility; appended to `fastqDirs` if given.
#'
#' @return A list with
#'   * `all_fq1_found`, `all_fq2_found` - logical, TRUE when every sample's
#'     read 1 / read 2 file was found exactly once.
#'   * `units` - the samplesheet (with `fq1`/`fq2` filled in when autodetected).
#'   * `missing_fq1`, `missing_fq2` - character, file names (explicit mode) or
#'     sample names (autodetect mode) that were not found; `character(0)` if none.
#'   * `units_missing` - rows of `units` with a missing/ambiguous fq1 or fq2.
#'   * `fastq_paths` - named character vector, file name -> full source path,
#'     for every FASTQ referenced by `units` that was found. Used to create
#'     the symlinks in `raw_data/`.
#'   * `duplicates` - data.frame (`file`, `dirs`) of file names found in more
#'     than one of the selected folders; zero rows when none.
#'
#' @examples
#' units <- data.frame(sample = c("A", "B"), group = c("ctl", "trt"))
#' res <- check_FASTQs(units, fastqDirs = c("/path/run1", "/path/run2"))
#' res$units        # fq1/fq2 now filled in
#' res$fastq_paths  # where each file was found
#'
#' @export
check_FASTQs <- function(
    units = NULL,
    fastqDirs = NULL,
    fastqDir = NULL
) {
  # (VAI HPC AI-agent operating rules: see docs/VAI_HPC_AI_AGENTS.md)
  fastqDirs <- unique(c(fastqDirs, fastqDir))
  fastqDirs <- fastqDirs[!is.na(fastqDirs) & nzchar(fastqDirs)]
  if (length(fastqDirs) == 0) stop("check_FASTQs(): no FASTQ folder supplied")
  units <- as.data.frame(units)

  # == Index every FASTQ directly inside each folder (one listing per folder)
  fq_pattern <- "\\.(fastq|fq)\\.gz$"
  index <- do.call(rbind, lapply(fastqDirs, function(d) {
    f <- list.files(d, pattern = fq_pattern, full.names = FALSE)
    data.frame(file = f, dir = rep(d, length(f)), stringsAsFactors = FALSE)
  }))
  if (is.null(index)) index <- data.frame(file = character(0), dir = character(0))

  dup_files  <- unique(index$file[duplicated(index$file)])
  duplicates <- data.frame(
    file = dup_files,
    dirs = vapply(dup_files, function(f) paste(index$dir[index$file == f], collapse = "; "),
                  character(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
  if (nrow(duplicates) > 0) {
    warning("FASTQ file names present in more than one selected folder: ",
            paste(dup_files, collapse = ", "))
  }
  # unique file name -> full path (duplicated names are excluded on purpose)
  unique_idx <- index[!index$file %in% dup_files, , drop = FALSE]
  lookup <- stats::setNames(file.path(unique_idx$dir, unique_idx$file), unique_idx$file)

  explicit <- all(c("fq1", "fq2") %in% colnames(units))

  if (!explicit) {
    # == Autodetect fq1/fq2 from sample names
    escape_regex <- function(x) gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
    find_sample_files <- function(sample) {
      s <- escape_regex(sample)
      # read number is matched AFTER the sample name, so sample names that
      # themselves contain _1/_R2 do not confuse the R1/R2 assignment
      p1 <- paste0("^", s, "(_.*)?_R?1(_[^/]*)?\\.(fastq|fq)\\.gz$")
      p2 <- paste0("^", s, "(_.*)?_R?2(_[^/]*)?\\.(fastq|fq)\\.gz$")
      cand <- unique(index$file)
      fq1 <- cand[grepl(p1, cand)]
      fq2 <- cand[grepl(p2, cand)]
      if (length(fq1) > 1) warning("sample ", sample, ": more than one read 1 file matched: ",
                                   paste(fq1, collapse = ", "))
      if (length(fq2) > 1) warning("sample ", sample, ": more than one read 2 file matched: ",
                                   paste(fq2, collapse = ", "))
      c(fq1 = if (length(fq1) == 1) fq1 else NA_character_,
        fq2 = if (length(fq2) == 1) fq2 else NA_character_)
    }
    found <- vapply(as.character(units$sample), find_sample_files, character(2))
    units$fq1 <- unname(found["fq1", ])
    units$fq2 <- unname(found["fq2", ])
    # keep the column order expected by the workflow: sample, group, fq1, fq2, ...
    front <- intersect(c("sample", "group", "fq1", "fq2"), colnames(units))
    units <- units[, c(front, setdiff(colnames(units), front)), drop = FALSE]
  }

  ok1 <- !is.na(units$fq1) & units$fq1 %in% names(lookup)
  ok2 <- !is.na(units$fq2) & units$fq2 %in% names(lookup)
  for (f in c(units$fq1[!ok1], units$fq2[!ok2])) message("NOT FOUND: ", f)

  # report file names when known, otherwise the sample name
  label_missing <- function(fq, ok) {
    ifelse(is.na(fq[!ok]), paste0(units$sample[!ok], " (no matching file)"), fq[!ok])
  }
  used <- unique(c(units$fq1[ok1], units$fq2[ok2]))

  list(
    'all_fq1_found' = all(ok1),
    'all_fq2_found' = all(ok2),
    'units'         = units,
    'missing_fq1'   = as.character(label_missing(units$fq1, ok1)),
    'missing_fq2'   = as.character(label_missing(units$fq2, ok2)),
    'units_missing' = units[!(ok1 & ok2), , drop = FALSE],
    'fastq_paths'   = lookup[used],
    'duplicates'    = duplicates
  )
}
