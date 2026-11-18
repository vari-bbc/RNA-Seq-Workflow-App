#' Standardise an uploaded samplesheet into the units.tsv layout
#'
#' Called after the samplesheet is uploaded (step 1). Recognises three input
#' layouts, checked in this order:
#'
#' 1. `sample`, `group`, `fq1`, `fq2` all present - used as is (columns
#'    reordered to the front; `RG` added as NA if absent).
#' 2. `sample`, `group` present - FASTQ names are filled in later by
#'    [check_FASTQs()] once FASTQ folder(s) are selected (step 2).
#' 3. A Genomics Core library template (`Library.Name`, `Library.ID`,
#'    `Library.Prep.Kit`) - `Library.Name` becomes `sample`; fq1/fq2 are
#'    built as `<sample><fq1_suffix>` / `<sample><fq2_suffix>`. At least one of
#'    genotype, cell.line, cell.type, treatment, batch, condition, group must
#'    be present (used to define comparisons).
#'
#' Any other layout stops with an error naming the missing columns.
#'
#' @param inputFileName samplesheet file name (used in error messages only).
#' @param df the samplesheet, already read into a data.frame.
#' @param fq1_suffix suffix appended to `sample` to make the read 1 file name
#'   (Genomics Core template only).
#' @param fq2_suffix suffix appended to `sample` to make the read 2 file name
#'   (Genomics Core template only).
#'
#' @return list(`units` = standardised data.frame, `message` = text shown in the app).
#'
#' @export
build_units_TSV <- function(
    inputFileName = NULL,
    df,
    fq1_suffix = '_L000_R1_001.fastq.gz',
    fq2_suffix = '_L000_R2_001.fastq.gz'
) {
  
  
  units_columns1 <- c('sample','group')
  units_columns2 <- c('fq1','fq2')
  columnsFromGenomics <- c('Library.Name','Library.ID','Library.Prep.Kit')
  
  # === units.tsv complete
  if(all(c(units_columns1,units_columns2) %in% colnames(df))){
    message('Samplesheet has required columns\n',paste(c(units_columns1,units_columns2),collapse="\n"))
    
    if (!'RG' %in% colnames(df)) { df$RG <- NA }
    df <- df %>% dplyr::select(all_of(c(units_columns1,units_columns2)),everything())
    
    return(
      list(
        'units' = df,
        'message' = paste0('Samplesheet has required columns \'sample\', \'group\', \'fq1\' and \'fq2\'.')
      )
    )
    
  }else if(all(units_columns1 %in% colnames(df))){
    message('Samplesheet has required columns\n',paste(c(units_columns1),collapse="\n"))
    if (!'RG' %in% colnames(df)) { df$RG <- NA }
    df <- df %>% dplyr::select(all_of(c(units_columns1)),everything())
    return(
      list(
        'units' = df,
        'message' = paste('Samplesheet has required columns \'sample\' and \'group\'.\n',"\nColumns \'fq1\' and \'fq2\' were not found.") 
      )
    )
  }else if(all(columnsFromGenomics %in% colnames(df))){
    message('genomics library template input')
    
    columns.in <- c(
      'genotype',
      'cell.line',
      'cell.type',
      'treatment',
      'batch',
      'condition',
      'group'
    )
    ci <- which(colnames(df) %in% columns.in)
    i <- length(ci)

    if (i<1) stop(paste("None of these columns found in genomics library template ",inputFileName,":\n",paste(columns.in,collapse="\n\nYou need to add one of these columns to use this as a samplesheet")))

    # validate that anyof the columns.in have more than two levels
    j <- unlist(lapply(ci,FUN=function(x){
      length(unique(df[,ci]))
    }))
    message('value of anyof columns ',j)
    if (!any(j>1)) stop(paste("None of these columns in ",inputFileName," have >1 level:\n",paste(columns.in,collapse="\n")))
    
    units <- df %>% dplyr::select(
      any_of(c(columnsFromGenomics[1],columns.in))
    )
    
    # set RG column to null
    if (!'RG' %in% colnames(units)) { units$RG <- NA }
    
    units <- units %>% 
      dplyr::rename('sample'='Library.Name')  %>%
      dplyr::mutate(
        fq1 = paste0(sample,fq1_suffix),
        fq2 = paste0(sample,fq2_suffix)
      ) %>% dplyr::select('sample', 'fq1', 'fq2', 'RG', everything())
    
    return(
      list(
        'units' = units,
        'message' = 'Autodetected a genomics core library template.'
      )
    )
  }else{
    # ---
    stop(paste('Error: Not able to detect required columns sample or group in',inputFileName,'\n'))
  }
}
