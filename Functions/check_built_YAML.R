#' Check that a species' reference files exist
#'
#' Stops with an error naming the first reference file (salmon index,
#' annotation, dict, sequence, fai) listed under `species_name` in the
#' (already VERSION-substituted) master YAML that does not exist on disk.
#' Currently not called (the call in build_YAML() is commented out).
#'
#' @param master_YAML list, master_config.yaml as read by yaml::read_yaml()
#'   after `VERSION` substitution.
#' @param species_name top-level key of the species block, e.g. `"human_hg38_gencode"`.
#'
#' @export
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
