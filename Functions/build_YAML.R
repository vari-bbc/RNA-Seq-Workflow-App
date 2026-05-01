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
    FDR
) {
  
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required. Install with: install.packages('yaml')")
  }
  
  # first import the template master YAML
  master <- yaml::read_yaml('/Users/ian.beddows/Desktop/RNA-Seq-Workflow-App/Necessary_Files/master_config.yaml')
  
  # substitute in ref_genome_version for [[species_name]]
  master[[species_name]]$ref <- lapply(master[[species_name]]$ref, gsub, pattern = "VERSION", replacement = ref_genome_version)
  
  # make additional modifications to YAML from input args
  # < to do >
  # master$modifiable_parameters[[<parameter_hardcoded>]] <- paramter_value_
  
  # write this out along with the other unchanged yaml
  write_yaml(
    c(
      master[[species_name]], 
      master[["modifiable_parameters"]],
      master[["unchanged"]],
    ),
    "output_config.yaml"
  )
  

}
