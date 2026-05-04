#' Check if the built YAML files exist
#'
#' This function is run only by build_YAML.R
#'
#'
#'
#'
#' @param master_YAML reference genome version to use 
#' @param species_name species name in master_config.yaml 
#'
#' @export
#'
#' @examples
#'
check_built_YAML <- function(
    master_YAML = NA, 
    species_name = NA
) {

  files <- c(
    # (master_YAML[[species_name]]$ref$index),
    (master_YAML[[species_name]]$ref$salmon_index),
    (master_YAML[[species_name]]$ref$annotation),
    (master_YAML[[species_name]]$ref$dict),
    (master_YAML[[species_name]]$ref$sequence),
    (master_YAML[[species_name]]$ref$fai)
  )
  
  lapply(files,FUN=function(x){
    if (!file.exists(x)) stop("Does not exist: ", x)
  })
  
  
  
}
