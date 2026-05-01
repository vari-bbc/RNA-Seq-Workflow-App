#' Build a YAML file for RNAseq Workflow Shiny App.
#'
#' This is the description.
#'
#' These are further details.
#'
#'
#' @param ref_genome_version reference genome version to use 
#' @param species_name species to use, e.g. human, mouse, fly.
#'
#' @export
#'
#' @examples
#' add_numbers(1, 2) ## returns 3
#'
build_YAML <- function(
    ref_genome_version = '2026-02-12_15.29.54_v23', 
    species_name = 'human',
    FDR = 0.1
) {
  
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required. Install with: install.packages('yaml')")
  }
  
  message("ref_genome_version: ", ref_genome_version)
  message("class: ", class(ref_genome_version))
  message("length: ", length(ref_genome_version))
  message("species_name: ", species_name)
  
  # first import the template master YAML
  print(file.exists('Necessary\ Files/master_config.yaml'))
  master <- yaml::read_yaml('Necessary\ Files/master_config.yaml')
  
  # substitute in ref_genome_version for [[species_name]]
  master[[species_name]]$ref <- lapply(
    master[[species_name]]$ref, 
    gsub, 
    pattern = "VERSION", 
    replacement = as.character(ref_genome_version)[1]
  )
  # make additional modifications to YAML from input args
  # < to do >
  master$modifiable_parameters[["FDR"]] <- FDR
  
  # write this out along with the other unchanged yaml
  write_yaml(
    c(
      master[[species_name]],
      master[["modifiable_parameters"]],
      master[["unchanged"]]
    ),
    "output_config.yaml"
  )
  

}
