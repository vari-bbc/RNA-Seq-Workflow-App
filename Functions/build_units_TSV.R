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
    inputFile = NULL,
    genomics_lib_template = NULL,
    repoName = NULL,
    fq1_suffix = '_L000_R1_001.fastq.gz',
    fq2_suffix = '_L000_R2_001.fastq.gz'
) {
  
  # expand this to check all columns in lib template and pass warning 1, 2 , 3 w/ error messages in app
  columnsFromGenomics <- c('Library.Name')
  
  columns.in <- c(
    'genotype',
    'cell.line',
    'cell.type',
    'treatment',
    'batch',
    'condition',
    'group'
  )
  ci <- which(colnames(genomics_lib_template) %in% columns.in)
  i <- length(ci)
  # require that a minimum of one of columns.in present
  # warning('length of i is',length(i))
  # print(paste('inputFile value:',inputFile))
    
  # stopifnot(is.data.frame(genomics_lib_template))
  if (i<1) stop(paste("None of these columns found in ",inputFile,":\n",paste(columns.in,collapse="\n")))
  # print(colnames(genomics_lib_template))
  
  # validate that anyof the columns.in have more than two levels
  j <- unlist(lapply(ci,FUN=function(x){
    length(unique(genomics_lib_template[,ci]))
  }))
  warning('value of j',j)
  if (!any(j>1)) stop(paste("None of these columns in ",inputFile," have >1 level:\n",paste(columns.in,collapse="\n")))
  
  units <- genomics_lib_template %>% dplyr::select(
    any_of(c(columnsFromGenomics,columns.in))
  )
  
  # set RG column to null
  units$RG <- NA
  
  units <- units %>% 
    dplyr::rename('sample'='Library.Name')  %>%
    dplyr::mutate(
      fq1 = paste0(sample,fq1_suffix),
      fq2 = paste0(sample,fq2_suffix)
    ) %>% dplyr::select('sample', 'fq1', 'fq2', 'RG', everything())
  
  readr::write_delim(units,file=file.path(repoName,'config/samplesheet/units.tsv'),
              delim="\t",quote="none")
  
  # ==   check that all expected 'Library Name' files are also FASTQS
  fefq1 <- lapply(units$fq1,FUN=function(fq){
    path <- file.path(repoName,'raw_data',fq)
    exists <- file.exists(path)
    if (!exists) message("NOT FOUND: ", path)
    return(exists)
  })
  all_fq1_found <- all(unlist(fefq1)==TRUE)
  fefq2 <- lapply(units$fq2,FUN=function(fq){
    path <- file.path(repoName,'raw_data',fq)
    exists <- file.exists(path)
    if (!exists) message("NOT FOUND: ", path)
    return(exists)
  })
  all_fq2_found <- all(unlist(fefq2)==TRUE)
  
  
  return(
    list(
      'units' = units,
      'all_fq1_found' = all_fq1_found,
      'all_fq2_found' = all_fq2_found
    )
  )
}
