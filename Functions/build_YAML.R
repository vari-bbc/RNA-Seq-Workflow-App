#' Write rnaseq_workflow/config/config.yaml from the app's settings
#'
#' Called when the user clicks "Save Settings" (step 4). Starts from the
#' template `Necessary Files/master_config.yaml`, which has one block per
#' species/annotation plus `modifiable_parameters` and `unchanged` blocks:
#'
#' 1. takes the `species_name` block and replaces the literal text `VERSION`
#'    in its reference paths with `ref_genome_version`;
#' 2. sets `fdr_cutoff`, `PE_or_SE`, `run_rseqc`, `run_vis_bigwig`;
#' 3. checks that every key in the workflow's own (freshly cloned)
#'    `config/config.yaml` is present, so a new workflow parameter that the
#'    template does not know about stops with an error instead of being dropped;
#' 4. overwrites `<outputDir>/rnaseq_workflow/config/config.yaml`.
#'
#' To add a species or a new workflow parameter, edit
#' `Necessary Files/master_config.yaml` (and `speciesSelectChoices` in app.R).
#'
#' @param outputDir analysis folder selected in step 3 (contains `rnaseq_workflow/`).
#' @param repoDir path of the cloned `rnaseq_workflow` repository.
#' @param ref_genome_version BBC versioned-reference folder name, e.g.
#'   `"latest"` or `"2026-02-12_15.29.54_v23"` (see `refVersionChoices` in app.R).
#' @param species_name top-level key in master_config.yaml, e.g. `"human_hg38_gencode"`.
#' @param fdrCutoff numeric FDR cutoff for differential expression (0-1).
#' @param PE_or_SE `"Paired End"` or `"Single End"` (UI labels); written as `PE`/`SE`.
#' @param run_rseqc logical, run RSeQC QC.
#' @param run_vis_bigwig logical, produce bigWig coverage tracks.
#'
#' @return Called for its side effect (writes config.yaml); errors if the
#'   template is missing parameters required by the workflow.
#'
#' @examples
#' \dontrun{
#' build_YAML(outputDir = "/varidata/research/projects/lab/analysis",
#'            repoDir   = "/varidata/research/projects/lab/analysis/rnaseq_workflow",
#'            ref_genome_version = "latest", species_name = "human_hg38_gencode",
#'            fdrCutoff = 0.01, PE_or_SE = "Paired End",
#'            run_rseqc = TRUE, run_vis_bigwig = TRUE)
#' }
#'
#' @export
build_YAML <- function(
    outputDir = 'default_outputDir',
    repoDir   = NULL,
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
  current <- yaml::read_yaml(file.path(repoDir, "config/config.yaml"))
  
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
  
  out_yaml <- c(
    master[[species_name]],
    master[["modifiable_parameters"]],
    master[["unchanged"]]
  )
  
  missing_params <- setdiff(names(current), names(out_yaml))

  if (length(missing_params) > 0){
    stop("Missing params: ", paste0(missing_params, collpase=", "))
  }

  write_yaml(
    out_yaml,
    paste0(outputDir,"/rnaseq_workflow/config/config.yaml")
  )


}
