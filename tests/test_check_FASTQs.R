# Unit tests for Functions/check_FASTQs.R
# Run from the repository root:  Rscript tests/test_check_FASTQs.R
# Uses only base R; creates throw-away FASTQ files in tempdir().
source("Functions/check_FASTQs.R")
n_fail <- 0
check <- function(desc, cond) {
  if (isTRUE(cond)) cat("PASS:", desc, "\n") else { cat("FAIL:", desc, "\n"); n_fail <<- n_fail + 1 }
}
mk <- function(dir, files) { dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  for (f in files) file.create(file.path(dir, f)); dir }

root <- file.path(tempdir(), "fq_test"); unlink(root, recursive = TRUE)
run1 <- mk(file.path(root, "run1"), c("A_S1_L001_R1_001.fastq.gz", "A_S1_L001_R2_001.fastq.gz",
                                      "B_R1.fastq.gz", "B_R2.fastq.gz", "notes.txt"))
run2 <- mk(file.path(root, "run2"), c("C_1.fq.gz", "C_2.fq.gz", "D.x_R1.fastq.gz", "D.x_R2.fastq.gz"))
units <- data.frame(sample = c("A", "B", "C", "D.x"), group = c("g1", "g1", "g2", "g2"))

# 1. autodetect across two folders
r <- suppressMessages(check_FASTQs(units, fastqDirs = c(run1, run2)))
check("autodetect: all fq1 found across 2 folders", r$all_fq1_found)
check("autodetect: all fq2 found across 2 folders", r$all_fq2_found)
check("autodetect: C read 1 assigned", r$units$fq1[r$units$sample == "C"] == "C_1.fq.gz")
check("autodetect: full paths recorded", all(file.exists(r$fastq_paths)) && length(r$fastq_paths) == 8)
check("autodetect: column order sample, group, fq1, fq2", identical(colnames(r$units)[1:4], c("sample","group","fq1","fq2")))

# 2. one folder only -> samples in run2 missing, reported by sample name
r <- suppressMessages(check_FASTQs(units, fastqDirs = run1))
check("single folder: fq1 not all found", !r$all_fq1_found)
check("single folder: missing samples reported", length(r$missing_fq1) == 2 && nrow(r$units_missing) == 2)

# 3. regex metacharacter in sample name: 'D.x' must not match 'DAx'
invisible(mk(run2, c("DAx_R1.fastq.gz")))
r <- suppressMessages(check_FASTQs(units, fastqDirs = c(run1, run2)))
check("sample name '.' is literal (no ambiguity)", r$all_fq1_found && r$units$fq1[4] == "D.x_R1.fastq.gz")

# 4. explicit fq1/fq2 columns, files spread across folders
ex <- r$units
r2 <- suppressMessages(check_FASTQs(ex, fastqDirs = c(run1, run2)))
check("explicit: all found", r2$all_fq1_found && r2$all_fq2_found)
ex$fq2[2] <- "B_R2_typo.fastq.gz"
r3 <- suppressMessages(check_FASTQs(ex, fastqDirs = c(run1, run2)))
check("explicit: typo reported missing", !r3$all_fq2_found && identical(r3$missing_fq2, "B_R2_typo.fastq.gz"))

# 5. duplicate file name in two folders -> flagged, sample treated as missing
run3 <- mk(file.path(root, "run3"), c("B_R1.fastq.gz"))
r4 <- suppressWarnings(suppressMessages(check_FASTQs(units, fastqDirs = c(run1, run2, run3))))
check("duplicate: reported", nrow(r4$duplicates) == 1 && r4$duplicates$file == "B_R1.fastq.gz")
check("duplicate: affected sample not found", !r4$all_fq1_found)

# 6. backwards-compatible single fastqDir argument
r5 <- suppressMessages(check_FASTQs(units[1:2, ], fastqDir = run1))
check("legacy fastqDir argument works", r5$all_fq1_found && r5$all_fq2_found)

unlink(root, recursive = TRUE)
cat(if (n_fail == 0) "\nAll tests passed\n" else paste("\n", n_fail, "test(s) FAILED\n"))
quit(status = as.integer(n_fail > 0))
