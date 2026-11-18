# Unit tests for Functions/check_FASTQs.R
# Run from the repository root:  Rscript tests/test_check_FASTQs.R
# Uses only base R; creates empty throw-away FASTQ files in tempdir().
source("Functions/check_FASTQs.R")
n_fail <- 0
check <- function(desc, cond) {
  if (isTRUE(cond)) cat("PASS:", desc, "\n") else { cat("FAIL:", desc, "\n"); n_fail <<- n_fail + 1 }
}
mk <- function(dir, files) { dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  for (f in files) file.create(file.path(dir, f)); invisible(dir) }
q <- function(...) suppressWarnings(suppressMessages(check_FASTQs(...)))

root <- file.path(tempdir(), "fq_test"); unlink(root, recursive = TRUE)

# 1. 10 samples; S1 and S2 were sequenced on two runs (same file names) -> 12 rows
s <- paste0("S", 1:10)
runA <- mk(file.path(root, "runA"), c(paste0(s, "_R1_001.fastq.gz"), paste0(s, "_R2_001.fastq.gz")))
runB <- mk(file.path(root, "runB"), c("S1_R1_001.fastq.gz", "S1_R2_001.fastq.gz",
                                      "S2_R1_001.fastq.gz", "S2_R2_001.fastq.gz", "notes.txt"))
units <- data.frame(sample = s, group = rep(c("ctl", "trt"), 5))
r <- q(units, fastqDirs = c(runA, runB))
check("example: 12 data rows for 10 samples", nrow(r$units) == 12)
check("example: all fq1/fq2 found", r$all_fq1_found && r$all_fq2_found)
check("example: S1 has runA and runB pairs",
      identical(r$units$fq1[r$units$sample == "S1"], c("runA/S1_R1_001.fastq.gz", "runB/S1_R1_001.fastq.gz")))
check("example: fq1 values unique (workflow requirement)", !any(duplicated(r$units$fq1)))
check("example: group copied to every row", all(r$units$group[r$units$sample == "S2"] == "trt"))
check("example: multi_pair_samples lists S1, S2", identical(sort(r$multi_pair_samples$sample), c("S1", "S2")))
check("example: folder_links map link -> folder", identical(unname(r$folder_links[c("runA", "runB")]), c(runA, runB)))
check("example: fastq_paths point to real files", all(file.exists(r$fastq_paths)) && length(r$fastq_paths) == 24)
check("example: column order sample, group, fq1, fq2", identical(colnames(r$units)[1:4], c("sample", "group", "fq1", "fq2")))

# 2. re-checking the returned units (explicit mode) is stable
r2 <- q(r$units, fastqDirs = c(runA, runB))
check("re-check: identical units", identical(r2$units, r$units) && r2$all_fq2_found)

# 3. explicit bare file names found in two folders -> one row per folder
ex <- data.frame(sample = c("S1", "S3"), group = c("a", "b"),
                 fq1 = c("S1_R1_001.fastq.gz", "S3_R1_001.fastq.gz"),
                 fq2 = c("S1_R2_001.fastq.gz", "S3_R2_001.fastq.gz"))
r3 <- q(ex, fastqDirs = c(runA, runB))
check("explicit: S1 expands to 2 rows, S3 1 row", nrow(r3$units) == 3 && sum(r3$units$sample == "S1") == 2)
ex$fq2[2] <- "S3_R2_typo.fastq.gz"
r4 <- q(ex, fastqDirs = c(runA, runB))
check("explicit: typo reported missing", !r4$all_fq2_found && identical(r4$missing_fq2, "S3_R2_typo.fastq.gz"))

# 4. lanes in one folder pair by name; sample A vs A_2 (longest name wins)
lanes <- mk(file.path(root, "lanes"), c("A_S1_L001_R1_001.fastq.gz", "A_S1_L001_R2_001.fastq.gz",
                                        "A_S1_L002_R1_001.fastq.gz", "A_S1_L002_R2_001.fastq.gz",
                                        "A_2_R1.fq.gz", "A_2_R2.fq.gz", "D.x_1.fq.gz", "D.x_2.fq.gz",
                                        "DAx_1.fq.gz", "DAx_2.fq.gz"))
r5 <- q(data.frame(sample = c("A", "A_2", "D.x"), group = c("g", "g", "h")), fastqDirs = lanes)
check("lanes: A has 2 pairs (L001, L002)", sum(r5$units$sample == "A") == 2 &&
        all(sub(".*_(L00[12])_R1.*", "\\1", r5$units$fq1[r5$units$sample == "A"]) == c("L001", "L002")))
check("lanes: R1/R2 of same lane paired", all(sub("_R1_", "_R2_", r5$units$fq1[1:2]) == r5$units$fq2[1:2]))
check("prefix: A_2 files go to sample A_2 only", sum(r5$units$sample == "A_2") == 1 && !any(grepl("A_2_", r5$units$fq1[r5$units$sample == "A"])))
check("regex: '.' in sample name is literal", r5$units$fq1[r5$units$sample == "D.x"] == "lanes/D.x_1.fq.gz")

# 5. missing: sample with no files, orphan R1
orph <- mk(file.path(root, "orph"), c("E_R1.fastq.gz"))
r6 <- q(data.frame(sample = c("E", "F"), group = c("x", "y")), fastqDirs = orph)
check("missing: F has no files, E has no read 2", !r6$all_fq1_found && !r6$all_fq2_found && nrow(r6$units_missing) == 2)

# 6. two selected folders with the same folder name get unique link names
dup1 <- mk(file.path(root, "p1", "fastq"), c("G_R1.fastq.gz", "G_R2.fastq.gz"))
dup2 <- mk(file.path(root, "p2", "fastq"), c("G_R1.fastq.gz", "G_R2.fastq.gz"))
r7 <- q(data.frame(sample = "G", group = "z"), fastqDirs = c(dup1, dup2))
check("link names: fastq and fastq_1", identical(names(r7$folder_links), c("fastq", "fastq_1")) && nrow(r7$units) == 2)

# 7. legacy single-folder argument; same folder given twice counted once
r8 <- q(data.frame(sample = "S3", group = "a"), fastqDir = runA, fastqDirs = runA)
check("legacy fastqDir + dedup of folders", nrow(r8$units) == 1 && length(r8$folder_links) == 1)

# 8. app flow: add runA, then add runB -> re-check from units_for_recheck()
step1 <- q(units, fastqDirs = runA)
check("flow: runA only -> 10 rows", nrow(step1$units) == 10)
step1$units$group[1] <- "edited"                     # user edit in the app
step2 <- q(units_for_recheck(step1$units, autodetected = TRUE), fastqDirs = c(runA, runB))
check("flow (autodetect): adding runB gives 12 rows", nrow(step2$units) == 12 && step2$all_fq2_found)
check("flow: user edit kept on both S1 rows", all(step2$units$group[step2$units$sample == "S1"] == "edited"))
ex1 <- q(ex[1, ], fastqDirs = runA)
ex2 <- q(units_for_recheck(ex1$units, autodetected = FALSE), fastqDirs = c(runA, runB))
check("flow (explicit): adding runB expands S1 to 2 rows", nrow(ex1$units) == 1 && nrow(ex2$units) == 2)
miss <- q(data.frame(sample = c("S1", "Z"), group = "a"), fastqDirs = runA)
fixed <- mk(file.path(root, "zdir"), c("Z_R1.fastq.gz", "Z_R2.fastq.gz"))
miss2 <- q(units_for_recheck(miss$units, TRUE), fastqDirs = c(runA, fixed))
check("flow: sample missing in first folder found after adding second", !miss$all_fq1_found && miss2$all_fq1_found && miss2$all_fq2_found)

unlink(root, recursive = TRUE)
cat(if (n_fail == 0) "\nAll tests passed\n" else paste("\n", n_fail, "test(s) FAILED\n"))
quit(status = as.integer(n_fail > 0))
