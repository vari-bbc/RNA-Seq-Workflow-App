#' Build a YAML file for RNAseq Workflow Shiny App.
#'
#' This is the description.
#'
#' parameters of this function are used to replace key-value pairs in app/Necessary Files/master_config.yaml 
#' YAML with updated values is written to outputDir/rnaseq_workflow/config/config.yaml 
#'
#'
#' @param ref_genome_version reference genome version to use 
#' @param species_name species to use, e.g. human, mouse, fly.
#' @param fdrCutoff FDR to use with rnaseq_workflow
#' @param PE_or_SE PE_or_SE
#' @param 
#' @param 
#' @param 
#' @param 
#' @param 
#' @param 
#' 
#' @export
#'
#' @examples
#' add_numbers(1, 2) ## returns 3
#'
build_YAML <- function(
    outputDir = 'default_outputDir',
    ref_genome_version = 'default_ref_version', 
    species_name = 'default_species_name',
    fdrCutoff = 1,
    PE_or_SE = 'default paired-end',
    run_rseqc = FALSE,
    run_vis_bigwig = FALSE
) {
  
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required. Install with: install.packages('yaml')")
  }
  
  message("Options from build_YAML.R")
  message("ref_genome_version: ", ref_genome_version)
  message("class: ", class(ref_genome_version))
  message("length: ", length(ref_genome_version))
  message("species_name: ", species_name)
  
  # check FDR ?
  # stopifnot(is.numeric(fdrCutoff), fdrCutoff >= 0, fdrCutoff <= 1)
  
  # =========== import the template master YAML #
  master <- yaml::read_yaml('Necessary\ Files/master_config.yaml')
  
  #----------------------------------------------------------------------------#
  # substitute in ref_genome_version for [[species_name]]
  #----------------------------------------------------------------------------#
  master[[species_name]]$ref <- lapply(
    master[[species_name]]$ref, 
    gsub, 
    pattern = "VERSION", 
    replacement = as.character(ref_genome_version)[1]
  )
  
  #----------------------------------------------------------------------------#
  # make additional modifications to YAML from input args
  #----------------------------------------------------------------------------#
  master$modifiable_parameters[["fdr_cutoff"]] <- fdrCutoff
  if(PE_or_SE=="Single End"){  
    master$modifiable_parameters[["PE_or_SE"]] <- 'SE'
  }else{
    master$modifiable_parameters[["PE_or_SE"]] <- 'PE'
  }
  master$modifiable_parameters[["run_rseqc"]] <- run_rseqc
  master$modifiable_parameters[["run_vis_bigwig"]] <- run_vis_bigwig
  #----------------------------------------------------------------------------#
  # do checks to make sure that all file.exist==TRUE
  #----------------------------------------------------------------------------#
  # check_built_YAML(master_YAML=master,species_name=species_name)
  
  write_yaml(
    c(
      master[[species_name]],
      master[["modifiable_parameters"]],
      master[["unchanged"]]
    ),
    paste0(outputDir,"/rnaseq_workflow/config/config.yaml")
  )


}
