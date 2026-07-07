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
    comparisons = NULL,
    columnsToContrast = NULL,
    baselineGrpContrast = NULL,
    relavtiveGrpContrast = NULL,
    covariateColumn = NULL,
    columnsToFilterOn = NULL,
    filterColumnLevel = NULL,
    repoPath = NULL
) {

  # these are the current columns for rnaseq_workflow
  # comparison_name	group_test	group_reference	group_reg_formula	filterColumn	filterColumnLevel
  formula1 <- NULL
  name <- NULL
  is_empty <- function(x) {
    is.null(x) || length(x) == 0 || (length(x) == 1 && is.character(x) && x == "") || (length(x) == 1 && is.na(x))
  }
  if(!is_empty(covariateColumn) & !is_empty(filterColumnLevel)){
    message('comparisons func: yes covariate, yes filter')
    formula1 <- paste0('~',columnsToContrast,'+',covariateColumn)
    name <- paste0(columnsToContrast,'_',relavtiveGrpContrast,'_vs_',baselineGrpContrast,'_covariate_',covariateColumn,'_',columnsToFilterOn,'_',filterColumnLevel)
  }else if(!is_empty(covariateColumn)){
    message('comparisons func: yes covariate, no filter')
    formula1 <- paste0('~',columnsToContrast,'+',covariateColumn)
    name <- paste0(columnsToContrast,'_',relavtiveGrpContrast,'_vs_',baselineGrpContrast,'_covariate_',covariateColumn)
  }else if(!is_empty(filterColumnLevel)){
    message('comparisons func: no covariate, yes filter')
    formula1 <- paste0('~',columnsToContrast)
    name <- paste0(columnsToContrast,'_',relavtiveGrpContrast,'_vs_',baselineGrpContrast,'_',columnsToFilterOn,'_',filterColumnLevel)
  }else{
    message('comparisons func: no covariate, no filter')
    formula1 <- paste0('~',columnsToContrast)
    name <- paste0(columnsToContrast,'_',relavtiveGrpContrast,'_vs_',baselineGrpContrast)
  }

  safe1 <- function(x) if (is.null(x) || length(x) == 0) NA_character_ else x

  message('lengths: name=', length(name),
          ' group_test=', length(relavtiveGrpContrast),
          ' group_reference=', length(baselineGrpContrast),
          ' formula=', length(formula1),
          ' filterColumn=', length(columnsToFilterOn),
          ' filterColumnLevel=', length(filterColumnLevel))

  tmp <- data.frame(
    name = safe1(name),
    group_test = safe1(relavtiveGrpContrast),
    group_reference = safe1(baselineGrpContrast),
    group_reg_formula = safe1(formula1),
    filterColumn = safe1(columnsToFilterOn),
    filterColumnLevel = safe1(filterColumnLevel),
    stringsAsFactors = FALSE
  )

  # do checks that filtering won't result in <2 samples per group


  message('comparisons dim',dim(tmp))
  message('comparisons class',class(tmp))
  if (is.null(comparisons)) {
    message('comparisons is.null')
    comparisons <- tmp
  } else {
    message('comparisons ! is.null')
    # sanity check that column names match before rbinding
    if (!identical(names(comparisons), names(tmp))) {
      stop("Column names don't match between comparisons and new comparison: ",
           paste(setdiff(union(names(comparisons), names(tmp)),
                         intersect(names(comparisons), names(tmp))),
                 collapse = ", "))
    }
    comparisons <- rbind(comparisons, tmp)
  }

  # readr::write_delim(comparisons,file=file.path(repoPath,'config/samplesheet/comparisons.tsv'),
  #             delim="\t",quote="none")

  return(
    list(
      'datatable' = comparisons
    )
  )
}
