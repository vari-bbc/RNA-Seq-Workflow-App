#' Locate and pair FASTQ files for every sample, across one or more folders
#'
#' Given the samplesheet (`units`) and one or more FASTQ folders, find every
#' read 1 / read 2 FASTQ pair of every sample and return a units table with
#' **one row per FASTQ pair**. A sample sequenced on several runs/lanes gets
#' several rows; rnaseq_workflow trims each pair separately and combines
#' them per sample at alignment/quantification.
#'
#' **How files are referenced.** Each selected folder is given a short *link
#' name* (its folder name, made unique as `name_1`, `name_2`... if two
#' selected folders have the same name). At workflow set-up the folder itself is
#' symlinked to `rnaseq_workflow/raw_data/<link name>`, and `fq1`/`fq2` are
#' written as `<link name>/<file name>` (the workflow reads
#' `raw_data/<fq1>`). Identical file names in different folders are therefore
#' fine - they are different pairs.
#'
#' Two modes, chosen automatically:
#'
#' 1. **Explicit** - the samplesheet has `fq1` and `fq2` columns.
#'    * `<link name>/<file>` (as written by this function) is used as is.
#'    * A plain file name is looked for in every selected folder; each folder
#'      containing both the `fq1` and `fq2` file contributes one row.
#' 2. **Autodetect** - no `fq1`/`fq2` columns. A file belongs to a sample when
#'    its name
#'      * starts with the sample name, optionally followed by `_<anything>`,
#'      * then `_1`/`_R1` (read 1) or `_2`/`_R2` (read 2), optionally followed
#'        by `_<anything>`, and
#'      * ends in `.fastq.gz` or `.fq.gz`.
#'    If a file matches several sample names (e.g. samples `A` and `A_2`), it
#'    is given to the longest one. Read 1 and read 2 files are paired when
#'    they are in the same folder and their names differ only in the read
#'    number (`A_L001_R1_001` <-> `A_L001_R2_001`).
#'
#' Folders are searched non-recursively (only files directly inside each folder).
#'
#' @param units data.frame samplesheet; must contain `sample`, optionally `fq1`, `fq2`.
#' @param fastqDirs character vector of one or more folder paths to search.
#' @param fastqDir deprecated single-folder argument (appended to `fastqDirs`).
#'
#' @return A list with
#'   * `all_fq1_found`, `all_fq2_found` - logical: every sample has at least
#'     one pair and every row has both files.
#'   * `units` - one row per FASTQ pair (other samplesheet columns copied to
#'     each row); rows for samples/files that could not be found or paired
#'     are kept with `NA` so they can be shown to the user.
#'   * `missing_fq1`, `missing_fq2` - character, what was not found.
#'   * `units_missing` - rows with a missing fq1 or fq2.
#'   * `folder_links` - named character vector, link name -> folder path; each
#'     must be symlinked as `raw_data/<link name>`.
#'   * `fastq_paths` - named character vector, `fq1`/`fq2` value -> full source path.
#'   * `multi_pair_samples` - data.frame (`sample`, `n_pairs`) of samples with
#'     more than one FASTQ pair.
#'
#' @examples
#' units <- data.frame(sample = c("A", "B"), group = c("ctl", "trt"))
#' res <- check_FASTQs(units, fastqDirs = c("/path/run1", "/path/run2"))
#' res$units         # e.g. A, ctl, run1/A_R1.fastq.gz, run1/A_R2.fastq.gz ...
#' res$folder_links  # run1 -> /path/run1, run2 -> /path/run2
#'
#' @export
check_FASTQs <- function(
    units = NULL,
    fastqDirs = NULL,
    fastqDir = NULL
) {
  # (VAI HPC AI-agent operating rules: see docs/VAI_HPC_AI_AGENTS.md)
  fastqDirs <- c(fastqDirs, fastqDir)
  fastqDirs <- fastqDirs[!is.na(fastqDirs) & nzchar(fastqDirs)]
  fastqDirs <- fastqDirs[!duplicated(normalizePath(fastqDirs, mustWork = FALSE))]
  if (length(fastqDirs) == 0) stop("check_FASTQs(): no FASTQ folder supplied")
  units <- as.data.frame(units, stringsAsFactors = FALSE)
  units$sample <- as.character(units$sample)

  # == Link name for each folder: folder name, sanitised, made unique
  link <- gsub("[^A-Za-z0-9._-]", "_", basename(normalizePath(fastqDirs, mustWork = FALSE)))
  link[link %in% c("", ".", "..")] <- "fastq"
  link <- make.unique(link, sep = "_")
  folder_links <- stats::setNames(fastqDirs, link)

  # == Index every FASTQ directly inside each folder (one listing per folder)
  index <- do.call(rbind, lapply(seq_along(fastqDirs), function(i) {
    f <- list.files(fastqDirs[i], pattern = "\\.(fastq|fq)\\.gz$", full.names = FALSE)
    data.frame(file = f, link = rep(link[i], length(f)), dir = rep(fastqDirs[i], length(f)),
               stringsAsFactors = FALSE)
  }))
  if (is.null(index)) index <- data.frame(file = character(0), link = character(0), dir = character(0))
  index$rel <- file.path(index$link, index$file)
  rel2full <- stats::setNames(file.path(index$dir, index$file), index$rel)

  other_cols <- setdiff(colnames(units), c("fq1", "fq2"))
  na_row <- function(r) { r$fq1 <- NA_character_; r$fq2 <- NA_character_; r }
  explicit <- all(c("fq1", "fq2") %in% colnames(units))

  if (explicit) {
    # == Resolve each row; a bare file name may expand to one row per folder
    rows <- list(); missing_fq1 <- character(0); missing_fq2 <- character(0)
    for (i in seq_len(nrow(units))) {
      r <- units[i, , drop = FALSE]
      f1 <- as.character(r$fq1); f2 <- as.character(r$fq2)
      if (!is.na(f1) && f1 %in% index$rel && !is.na(f2) && f2 %in% index$rel) {
        rows[[length(rows) + 1]] <- r                   # already <link>/<file>
        next
      }
      b1 <- basename(f1); b2 <- basename(f2)
      in1 <- if (!is.na(f1) && f1 %in% index$rel) dirname(f1) else index$link[index$file == b1]
      in2 <- if (!is.na(f2) && f2 %in% index$rel) dirname(f2) else index$link[index$file == b2]
      both <- intersect(in1, in2)
      if (length(both) > 0) {
        out <- r[rep(1, length(both)), , drop = FALSE]
        out$fq1 <- file.path(both, b1); out$fq2 <- file.path(both, b2)
        rows[[length(rows) + 1]] <- out
        next
      }
      # no folder holds both files: accept only if each file is found exactly once
      r$fq1 <- if (length(in1) == 1) file.path(in1, b1) else NA_character_
      r$fq2 <- if (length(in2) == 1) file.path(in2, b2) else NA_character_
      why <- function(n) if (n == 0) "" else paste0(" (found in ", n, " folders, none holding its mate)")
      if (is.na(r$fq1)) { message("NOT FOUND: ", f1); missing_fq1 <- c(missing_fq1, paste0(f1, why(length(in1)))) }
      if (is.na(r$fq2)) { message("NOT FOUND: ", f2); missing_fq2 <- c(missing_fq2, paste0(f2, why(length(in2)))) }
      rows[[length(rows) + 1]] <- r
    }
    units_out <- do.call(rbind, rows)
  } else {
    # == Autodetect: assign files to samples, then pair R1 with R2
    escape_regex <- function(x) gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
    samples <- unique(units$sample)
    # regex with 3 groups: (prefix up to read number)(read number)(suffix)
    pat <- function(s) paste0("^(", escape_regex(s), "(?:_.*)?_R?)([12])((?:_[^/]*)?\\.(?:fastq|fq)\\.gz)$")
    owner <- rep(NA_character_, nrow(index))
    for (s in samples[order(nchar(samples))]) {        # longer names win
      owner[grepl(pat(s), index$file, perl = TRUE)] <- s
    }
    index$sample <- owner
    hit <- index[!is.na(index$sample), , drop = FALSE]
    hit$read <- if (nrow(hit)) mapply(function(f, s) sub(pat(s), "\\2", f, perl = TRUE), hit$file, hit$sample) else character(0)
    hit$key  <- if (nrow(hit)) mapply(function(f, s) sub(pat(s), "\\1#\\3", f, perl = TRUE), hit$file, hit$sample) else character(0)
    hit$key  <- paste(hit$link, hit$key, sep = "/")

    rows <- list(); missing_fq1 <- character(0); missing_fq2 <- character(0)
    for (s in samples) {
      base <- units[units$sample == s, , drop = FALSE][1, , drop = FALSE]
      h <- hit[hit$sample == s, , drop = FALSE]
      if (nrow(h) == 0) {
        rows[[length(rows) + 1]] <- na_row(base)
        missing_fq1 <- c(missing_fq1, paste0(s, " (no matching file)"))
        missing_fq2 <- c(missing_fq2, paste0(s, " (no matching file)"))
        next
      }
      keys <- unique(h$key)
      keys <- keys[order(match(sub("/.*", "", keys), link), keys)]   # folder order, then name
      for (k in keys) {
        r <- base
        r1 <- h$rel[h$key == k & h$read == "1"]; r2 <- h$rel[h$key == k & h$read == "2"]
        r$fq1 <- if (length(r1) == 1) r1 else NA_character_
        r$fq2 <- if (length(r2) == 1) r2 else NA_character_
        if (is.na(r$fq1)) missing_fq1 <- c(missing_fq1, paste0(s, ": no read 1 partner for ", r2))
        if (is.na(r$fq2)) missing_fq2 <- c(missing_fq2, paste0(s, ": no read 2 partner for ", r1))
        rows[[length(rows) + 1]] <- r
      }
    }
    units_out <- do.call(rbind, rows)
  }

  rownames(units_out) <- NULL
  front <- intersect(c("sample", "group", "fq1", "fq2"), colnames(units_out))
  units_out <- units_out[, c(front, setdiff(colnames(units_out), front)), drop = FALSE]

  ok1 <- !is.na(units_out$fq1); ok2 <- !is.na(units_out$fq2)
  used <- unique(c(units_out$fq1[ok1], units_out$fq2[ok2]))
  n_pairs <- table(units_out$sample[ok1 & ok2])

  list(
    'all_fq1_found'      = all(ok1),
    'all_fq2_found'      = all(ok2),
    'units'              = units_out,
    'missing_fq1'        = as.character(missing_fq1),
    'missing_fq2'        = as.character(missing_fq2),
    'units_missing'      = units_out[!(ok1 & ok2), , drop = FALSE],
    'folder_links'       = folder_links,
    'fastq_paths'        = rel2full[used],
    'multi_pair_samples' = data.frame(sample = names(n_pairs)[n_pairs > 1],
                                      n_pairs = as.integer(n_pairs[n_pairs > 1]),
                                      stringsAsFactors = FALSE)
  )
}


#' Prepare the current samplesheet for a fresh FASTQ check
#'
#' After a check, `units` has one row per FASTQ pair and `fq1`/`fq2` hold
#' `<link name>/<file>`. When folders are added (or the check is re-run after
#' edits), the check must start again from one row per sample so that every
#' selected folder is searched for every sample:
#'
#' * `autodetected = TRUE` (the uploaded samplesheet had no fq1/fq2): keep the
#'   first row of each sample and drop `fq1`/`fq2`, so they are re-detected.
#' * `autodetected = FALSE` (fq1/fq2 came from the samplesheet): strip the
#'   `<link name>/` prefix and drop repeated rows, so each file name is again
#'   looked up in every selected folder.
#'
#' Edits made in the app to other columns (group, covariates...) are kept.
#'
#' @param units current samplesheet (data.frame).
#' @param autodetected logical, were fq1/fq2 absent from the uploaded samplesheet?
#' @return data.frame to pass to [check_FASTQs()].
#' @export
units_for_recheck <- function(units, autodetected) {
  units <- as.data.frame(units, stringsAsFactors = FALSE)
  if (!all(c("fq1", "fq2") %in% colnames(units))) return(units)
  if (isTRUE(autodetected)) {
    units <- units[!duplicated(units$sample), setdiff(colnames(units), c("fq1", "fq2")), drop = FALSE]
  } else {
    strip <- function(x) ifelse(is.na(x), NA_character_, basename(as.character(x)))
    units$fq1 <- strip(units$fq1); units$fq2 <- strip(units$fq2)
    units <- units[!duplicated(units[c("sample", "fq1", "fq2")]), , drop = FALSE]
  }
  rownames(units) <- NULL
  units
}
