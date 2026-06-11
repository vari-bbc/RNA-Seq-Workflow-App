#' Build config/samplesheet/units.tsv 
#'
#' Build a units.tsv with 
#' sample	group	fq1	fq2	RG
#' 
#' sample from 
#' 
#' @param units units output from build_units_TSV.R
#' @param fastqDir path to FASTQs
#' 
#' @export
#'
#' @examples
#'
check_FASTQs <- function(
    units = NULL,
    fastqDir = NULL
) {
  
  if(all(c('fq1','fq2') %in% colnames(units))){
    # fields exist in df
    
    # ==  confirm all fq1 and fq2 files exist in inputDir
    fefq1 <- lapply(units$fq1,FUN=function(fq){
      path <- file.path(fastqDir,fq)
      exists <- file.exists(path)
      if (!exists) message("NOT FOUND: ", path)
      return(exists)
    })
    all_fq1_found <- all(unlist(fefq1)==TRUE)
    fefq2 <- lapply(units$fq2,FUN=function(fq){
      path <- file.path(fastqDir,fq)
      exists <- file.exists(path)
      if (!exists) message("NOT FOUND: ", path)
      return(exists)
    })
    all_fq2_found <- all(unlist(fefq2)==TRUE)
    
    return(
      list(
        'all_fq1_found' = all_fq1_found,
        'all_fq2_found' = all_fq2_found,
        'units' = as.data.frame(units)
      )
    )
  }else{
    # === try to autodetect
    
    
    # All files in inputDir
    all_files <- list.files(fastqDir, full.names = TRUE)
    
    # Known paired suffixes

    find_sample_files <- function(sample, files) {
      # Match any file whose basename starts with sample name + known suffix
      pattern <- paste0("^", sample, "_.*_R?[12].*\\.(fastq|fq)\\.gz$")
      matched <- files[grepl(pattern, basename(files))]
      message('for sample ',sample)
      message('matched',matched)
      fq1 <- matched[grepl(".*_R?1.*", basename(matched))]
      fq2 <- matched[grepl(".*_R?2.*", basename(matched))]
      
      list(
        fq1 = if (length(fq1) == 1) basename(fq1) else NA_character_,
        fq2 = if (length(fq2) == 1) basename(fq2) else NA_character_
      )
    }
    
    units <- units %>%
      rowwise() %>%
      mutate(
        fq1 = find_sample_files(sample, all_files)$fq1,
        fq2 = find_sample_files(sample, all_files)$fq2
      ) %>%
      ungroup()
    
    
    # ==  confirm all fq1 and fq2 files exist in inputDir
    # missing_fq1 <- list()
    fefq1 <- lapply(units$fq1,FUN=function(fq){
      path <- file.path(fastqDir,fq)
      exists <- file.exists(path)
      if (!exists) {
        message("NOT FOUND: ", path)
        # missing_fq1[[length(missing_fq1) + 1]] <<- path
      }
      return(exists)
    })
    all_fq1_found <- all(unlist(fefq1)==TRUE)
    fefq2 <- lapply(units$fq2,FUN=function(fq){
      path <- file.path(fastqDir,fq)
      exists <- file.exists(path)
      if (!exists) message("NOT FOUND: ", path)
      return(exists)
    })
    all_fq2_found <- all(unlist(fefq2)==TRUE)
    
    
    return(
      list(
        'all_fq1_found' = all_fq1_found,
        'all_fq2_found' = all_fq2_found,
        'units' = as.data.frame(units)
      )
    )
  }

}
