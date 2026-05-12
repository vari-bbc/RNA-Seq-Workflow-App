#' Build config/samplesheet/units.tsv 
#'
#' Build a units.tsv with 
#' sample	group	fq1	fq2	RG
#' 
#' sample from 
#' 
#' @param units returned from build_units_TSV.R
#' 
#' @export
#'
#' @examples
#'
build_comparisons_TSV <- function(
    units = NULL,
    repoPath = NULL
) {
  
  columns.in <- c(
    'genotype',
    'cell.line',
    'cell.type',
    'treatment',
    'batch',
    'condition',
    'group'
  )
  ci <- which(colnames(units) %in% columns.in)
  i <- length(ci)

    
  if (i<1) stop(paste("This error should not be possible -- yet here we are #45fndvo34qtuqgvv"))
  
  # validate which of the columns.in have more than two levels
  j <- unlist(lapply(ci,FUN=function(x){
    length(unique(units[,ci]))
  }))
  if (!any(j>1)) stop(paste("This error should not be possible -- yet here we are #vndklartja4tgohnvbw"))
  
  message('Value of i:',i)
  
  comparisons <- lapply(columns.in, function(col) {
    warning(paste("on Column", col))
    if (!col %in% names(units)) {
      warning(paste("Column", col, "not found in units, skipping."))
      return(NULL)
    }
    group_levels <- unique(units[[col]])
    as.data.frame(t(combn(group_levels, 2))) |>
      setNames(c("group_test", "group_reference")) |>
      mutate(
        column   = col,
        comparison_name = paste0(group_test, "_vs_", group_reference),
        group_reg_formula = paste0('~',col)
      ) |>
      select(comparison_name, group_test, group_reference, group_reg_formula)
  }) |>
    bind_rows()
  
  message('write_delim comparisons')
  readr::write_delim(comparisons,file=file.path(repoPath,'config/samplesheet/comparisons.tsv'),
              delim="\t",quote="none")
  
  
  return(
    list(
      'comparisons' = comparisons
    )
  )
}
