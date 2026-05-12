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
      'all_fq2_found' = all_fq2_found
    )
  )

}
