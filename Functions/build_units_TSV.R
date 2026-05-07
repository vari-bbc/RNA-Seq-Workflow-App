#' Build config/samplesheet/units.tsv 
#'
#' Build a units.tsv with 
#' sample	group	fq1	fq2	RG
#' 
#' sample from 
#' 
#' @param genomics_lib_template genomics library template 
#' @param repoName path to rnaseq_workflow
#' 
#' @export
#'
#' @examples
#'
build_units_TSV <- function(
    genomics_lib_template = NULL,
    repoName = NULL,
    fq1_suffix = '_L000_R1_001.fastq.gz',
    fq2_suffix = '_L000_R2_001.fastq.gz'
) {
  
  columns.in <- c(
    'Library.Name',
    'genotype',
    'cell.line',
    'cell.type',
    'treatment',
    'batch',
    'condition',
    'group'
  )
  
  # message('genomics_lib_template class',class(genomics_lib_template))
  stopifnot(is.data.frame(genomics_lib_template))
  
  # print(colnames(genomics_lib_template))
  
  tmp <- genomics_lib_template %>% dplyr::select(
    any_of(columns.in))
  
  # set RG column to null
  tmp$RG <- NA
  
  tmp <- tmp %>% 
    dplyr::rename('sample'='Library.Name')  %>%
    dplyr::mutate(
      fq1 = paste0(sample,fq1_suffix),
      fq2 = paste0(sample,fq2_suffix)
    ) %>% dplyr::select('sample', 'fq1', 'fq2', 'RG', everything())
  
  readr::write_delim(tmp,file=file.path(repoName,'config/samplesheet/units.tsv'),
              delim="\t",quote="none")
  
  all_files_found <- TRUE
  return(tmp)
}
