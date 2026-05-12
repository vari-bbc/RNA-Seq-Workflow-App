# ___________________ ----
# App Startup ----

if (!require("pacman", quietly = TRUE))
    install.packages("pacman", repos = "https://cloud.r-project.org")


## 1.0 Load Libraries ----
# change back to individual loads
pacman::p_load(shiny,bslib,shinyjs,shinyWidgets,bsicons,plotly,DT,readr,
               tidytable,colourpicker,pheatmap,grid,ggnewscale,stringr,
               viridis,tibble,shinyFiles,readxl,writexl,yaml,here,shinyalert)


## 2.0 Load Basics ----
functionFolderPath <<- "Functions"
source(paste0(functionFolderPath,"/Updated Shiny RMD Standards.R"))
sourceFunctions(functionFolderPath)


## 3.0 Universal Vars ----fr
# App Name here:
appName <<- "RNA Seq Workflow Starter"
# Necessary Files here:
template <<- read_excel(paste0("Necessary Files/SampleTemplate.xlsx"), sheet = 1)
# Root Dir for Folder Selection:
rootDir <<- c(Home = "~", "HPC Primary" = "~/../../primary", "HPC Secondary" = "~/../../secondary", "researchtemp" = "~/../../varidata/researchtemp/")
restrictDir <<- c("afs","bin","cloudstorage","cm","dev","etc","legacy","lib",
                  "lib64","localdisk","media","mnt","opt","proc","root","run",
                  "sbin","srv","sys","tmp","usr")


# ___________________ ----
# UI ----
# Ensure use of document outline and preloading as many inputs as possible
# Tool tips are last in nav item and should be specified with tooltipText = "..."
ui <- UINav(

  ## 1.0 Input ----
  singleTab("Step 1: Input Files",
    # navDownload("templateDownload", "Download a Template",
                # tooltipText = "Required columns: Conditions, Sample ID, ..."),
    navUpload("sampleUpload", "Upload Genomics Library Export (i.e. PRXXXXXX_Library_Export_YYYY_MM_DD.csv)", "Single"),
    shinyDirButton("inputPathSelect","Select FASTQ Input Folder",
                   "Please select folder with FASTQs", viewtype = "icon"),
    shinyDirButton("outputPathSelect","Select Workflow Output Folder",
                   "Please select a folder to run the analysis", viewtype = "icon"),
    navButton("checkFiles", "Validate Samplesheet, FASTQs, Output Folder"),
    navOutputText("inputErrorText"),
    navOutputText("outputErrorText"),
    navOutputText("gitCloneMessage"),
    navOutputText("symLinkFastq"),
    navOutputText("fqFound"),
    navOutputText("builtUnitsTsv"),
    tableOutput("showUnitsTSV"),
  ),
  
  ## 2.0 Options tab ----
  singleTab("Step 2: Options",
    navSelect("refVersions", "Reference Version", "Single", "Locked", 
              theChoices = c("2026-02-12_15.29.54_v23","2025-12-18_22.42.45_v22")),
    navSelect("speciesSelect","Select the Species", "Single", "Locked",
              theChoices = c("human_hg38_gencode","mouse_mm10_gencode","mouse_mm39_gencode")),
    navNumeric("fdrCutoff","False discover rate", 0.01, tooltipText = "Default: 0.01",min=0,max=1),
    navSelect("pairedSingle","Paired-end or single-end genomics library", "Single", "Locked",
              theChoices = c("Paired End","Single End")),
    navCheckbox("visBigWig","Run VisBigWig", "True"),
    navCheckbox("rSeqC","Run rSeqC", "True"),
    actionButton("compileConfig","Compile Config"),
    hr(),
    # navDownload("workflowFiles","Download a Zip of the Workflow Input Files")
  ),
  singleTab("Step 3: Select Comparisons",
    fluidRow(
      column(12,
       p("'comparisons.tsv' is used to run differential expression contrasts in the RNAseq workflow."),
       # p("From the column group, we have identified the following available contrasts."),
       p("We are working to build more options. For now, contact bbc@vai.org for help building more complicated contrasts.")
      )
    ),
    actionButton("buildContrasts","Autogenerate contrasts from units.tsv (units.tsv shown in 'Step 1: Input Files' tab)"),
    navOutputText("contrastsInfo1"),
    tableOutput("contrastsTableOutput")
   
  ),
  singleTab("Step 4: Run Workflow",
    actionButton("runWorkflow","Start Snakemake RNAseq Workflow"),
    navOutputText("workflowStarted"),
    verbatimTextOutput("job_status"),
    navOutputText("errorFilesEmail"),
    actionButton("checkStatus","Click here to refresh job status"),
    verbatimTextOutput("job_status_refresh")
  )
  

)


# ___________________ ----
# Server ----

server <- function(session, input, output) {
  
  ## 1.0 Global Vars ----
  # Any variables here that need to carry across app sections, but should be local to the user
  # Keep all variables inside a list to help with debugging later
  globals <- reactiveValues(
    checks = list(
      inputDirCheck = F,
      outputDirCheck = F,
      filesCheck = F,
      gitCheck = F
    ),
    library_template = NULL,
    library_template_path = NULL,
    units = NULL,
    repoPath = NULL
  )
  
  
  ## 2.0 Run on Start ----
  # Hide pages and deactivate buttons that should not be used yet
  observe({
    startSection("Run on Start")
    
    # Deactivate buttons that need other things to function
    deactivateItems(
      c(
        "compileConfig",
        "buildContrasts",
        "checkFiles",
        "runWorkflow",
        "checkStatus"
      )
    )

    # Deactivate downloads that need other things to function
    # deactivateItems(c("workflowFiles"))
    
    #Unnecessary for final app, actually used elsewhere
    # output$errorText <- renderText({ "Text here will display if sample sheet is proper" })
    
    endSection("Run on Start")
  })
  
  
  ## 3.0 File Imports ----
  observeEvent(input$sampleUpload, {
    req(input$sampleUpload)
    
    file <- input$sampleUpload
    globals$library_template_path <- file$name
    # Check file extension
    ext <- tools::file_ext(file$name)
    if (tolower(ext) != "csv") {
      shinyalert::shinyalert(
        title = "Invalid File Type",
        text  = "Please upload a valid Genomics Library Template comma-separated values (.csv) file.",
        type  = "error"
      )
      return()
    }
    
    # Read CSV into data.frame and save it as a global variable
    df <- tryCatch({
      read.csv(file$datapath, stringsAsFactors = FALSE)
    }, error = function(e) {
      shinyalert::shinyalert(
        title = "Genomics Library Template File Read Error",
        text  = paste("Could not read the Genomics Library Template:", e$message),
        type  = "error"
      )
      return(NULL)
    })
    req(df)
    globals$library_template <- df
    
    
  })
  
  ## 4.0 Select Folders ----
  # Input FASTQ folder
  shinyDirChoose(input, "inputPathSelect", roots = rootDir, session = session, filetypes = character(0),
                 allowDirCreate = FALSE, hidden = FALSE, restrictions = restrictDir)
  
  observeEvent(input$inputPathSelect,{
    inputDir <- parseDirPath(rootDir,input$inputPathSelect)
    
    req(parseDirPath(rootDir, input$inputPathSelect) != "") # this stops code being run until a dir is selected
    
    # Check if selected directory is readable
    # Returns TRUE if readable, FALSE otherwise
    is_readable <- file.access(inputDir, mode = 4) == 0
    warning("is_readable: ",is_readable)
    if(is_readable == TRUE){
      output$inputErrorText <- renderText({ paste0("The selected input directory is: ",inputDir) })
      globals$checks$inputDirCheck <- TRUE
    }else{
      shinyalert(
        title = "Selected FASTQ Directory Not Readable",
        text = paste("The selected directory is not readable:\n\n", inputDir,
                     "\n\nPlease select a different directory with read permissions."),
        type = "error"
      )
    }
    
    # Check if 'Check Files and Folders' runnable
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck){
      activateItems(c("checkFiles"))
    }
  })
  
  # Output folder
  shinyDirChoose(input, "outputPathSelect", roots = rootDir, session = session, filetypes = character(0),
                 allowDirCreate = TRUE)
  observeEvent(input$outputPathSelect,{
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
    
    # Check if selected directory if writable
    req(parseDirPath(rootDir, input$outputPathSelect) != "") # this stops code being run until a dir is selected
    
    
    # Check if rnaseq_workflow github repo already exists
    repo.url <- "https://github.com/vari-bbc/rnaseq_workflow.git"
    repoName <- gsub(pattern = '.git$',replacement = '',x = basename(repo.url))
    repoPath <- file.path(outputDir, repoName)
    # if (dir.exists(repoPath) && length(list.files(repoPath)) > 0) {
    #   shinyalert(
    #     title = "'rnaseq_workflow' repository already exists in selected workflow output folder",
    #     text  = paste0("'", repoPath, "' already exists and is not empty. Please choose a different output folder or remove the existing 'rnaseq_workflow' directory from ",outputDir,"."),
    #     type  = "error"
    #   )
    #   return()
    # }
    
    
    # Check if selected directory is writable
    # Returns TRUE if writable, FALSE otherwise
    is_writable <- file.access(outputDir, mode = 2) == 0
    noWorkflowYet <- dir.exists(paste0(outputDir,"/rnaseq_workflow"))
    # warning("is_writable: ",is_writable)
    if(is_writable & noWorkflowYet){
      output$outputErrorText <- renderText({ paste0("The selected output directory is: ",outputDir) })
      globals$checks$outputDirCheck <- TRUE
      
    }else if (noWorkflowYet){
      shinyalert(
        title = "Selected Output Directory Not Writable",
        text = paste("The selected directory is not writable:\n\n", outputDir,
                     "\n\nPlease select a different directory with write permissions."),
        type = "error"
      )
      return()
    } else if (is_writable){
      shinyalert(
        title = "Selected Output Directory Already Has Workflow",
        text = paste("The selected directory is already has a workflow:\n\n", outputDir,
                     "\n\nPlease select a different directory or remove the existing workflow (folder labeled rnaseq_workflow)."),
        type = "error"
      )
      return()
    } else {
      shinyalert(
        title = "Selected Output Directory Already Has Workflow AND is Not Writable",
        text = paste("The selected directory is already has a workflow AND is not writable:\n\n", outputDir,
                     "\n\nPlease select a different directory with write permissions and ensure it doesn't have an existing workflow (folder labeled rnaseq_workflow)."),
        type = "error"
      )
    }
    
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck){
      activateItems(c("checkFiles"))
    }
  })
  
  ## 5.0 Check Samplesheet, FASTQs, output dir ----
  ### Create units.tsv 
  observeEvent(input$checkFiles, {
    startSection("Check files")
    
    # == Inputs
    inputDir <- parseDirPath(rootDir,input$inputPathSelect)
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
      
    # ==  Clone github folder to outputDir ==
    repo.url <- "https://github.com/vari-bbc/rnaseq_workflow.git"
    repoName <- gsub(pattern = '.git$',replacement = '',x = basename(repo.url))
    repoPath <- file.path(outputDir, repoName)
    globals$repoPath <- repoPath
    tryCatch({
      message('Downloading BBC rnaseq_workflow ', repo.url, " into ", repoPath)
      result <- system2("git", args = c("clone", repo.url, repoPath), stderr = TRUE)
      exitCode <- attr(result, "status")
      # exitCode=0 # debugging
      if (!is.null(exitCode) && exitCode != 0) {
        stop(paste("git clone failed:", paste(result, collapse = "\n"),
                   "\nDestination path may already exist:", repoPath))
      }
      
      # modify bin/run_snake.sh
      script <- readLines(file.path(repoPath,"bin/run_snake.sh"))
      script <- gsub("cd \\$SLURM_SUBMIT_DIR", paste("cd", repoPath), script)
      writeLines(script, file.path(repoPath,"bin/run_snake_APP.sh"))
      
      
      
      output$gitCloneMessage <- renderText({ paste("Cloned", repoName, "into", repoPath) })
      globals$checks$gitCheck <- TRUE
    }, error = function(e) {
      showNotification(e$message, type = "error")
      shinyalert(
        title = "Problem with downloading the workflow!",
        text  = paste(e$message, "\n\n", "Please contact bbc@vai.org with further questions"),
        type  = "error"
      )
      globals$checks$gitCheck <- FALSE
    })
    
    
    # == Link the inputDir FASTQs to repoPath/raw_data ==
    system2("ln", args = c(
      "-s",
      file.path(inputDir, list.files(inputDir, pattern = "\\.fastq\\.gz$")),
      file.path(repoPath,'raw_data')
    ))
    output$symLinkFastq <- renderText({ paste0("FASTQ files linked from ",inputDir,"/*.fastq.gz into ",repoPath,"/raw_data/") })
    
    
    build_units_TSV_output <- NULL
    # ==  Create the repoPath/config/samplesheet/units.tsv file
    tryCatch({
      build_units_TSV_output <- build_units_TSV(
        inputFile = globals$library_template_path,
        genomics_lib_template = globals$library_template,
        repoName = repoPath
      )
      globals$checks$filesCheck <- TRUE
      
      # message("value of build_units_TSV_output[['all_fq1_found']]:",build_units_TSV_output[['all_fq1_found']])
      # message("value of build_units_TSV_output[['all_fq2_found']]:",build_units_TSV_output[['all_fq2_found']])
      # === warnings if fq1 or fq2 files not found
      if(build_units_TSV_output[['all_fq1_found']]==FALSE){
        shinyalert(
          title = "fq1 files missing!",
          text  = paste0("Not all read 1 FASTQs from fq1 column of ",repoPath,"/config/samplesheet/units.tsv were found in ",inputDir,"."),
          type  = "warning"
        )
        globals$checks$filesCheck <- FALSE
      }
      if(build_units_TSV_output[['all_fq2_found']]==FALSE){
        shinyalert(
          title = "fq2 files missing!",
          text  = paste0("Not all read 2 FASTQs from fq2 column of ",repoPath,"/config/samplesheet/units.tsv were found in ",inputDir,"."),
          type  = "warning"
        )
        globals$checks$filesCheck <- FALSE
      }
      # get # of files
      n <- nrow(build_units_TSV_output[['units']])
      output$fqFound <- renderText({ paste0("Found ",n," FASTQs (*.fastq.gz) in ",repoPath,"/raw_data/ matching ",globals$library_template_path) })
    }, error = function(e) {
      showNotification(e$message, type = "error")
        shinyalert(
              title = "Problem with the samplesheet!",
              text  = paste(e$message,"\n\n","Please contact bbc@vai.org with questions"),
              type  = "error"
        )
        globals$checks$filesCheck <- FALSE
    })
    
    globals$units <- build_units_TSV_output[['units']]
    # table(units$group)
    # output$showUnitsPreludeText <- renderText({ paste0("Built ") })
    output$builtUnitsTsv <- renderText({ paste0("Saved the following samplesheet into ",repoPath,"/config/samplesheet/units.tsv") })
    output$showUnitsTSV <- renderTable({ build_units_TSV_output[['units']] })
  
    
    # == activate compileConfig ==
    # == message proceed to options tab ==
    # ?? should all be TRUE to get to here anyway ... remove if() statement?
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck & globals$checks$filesCheck & globals$checks$gitCheck){
      activateItems(c("compileConfig"))
      
      shinyalert::shinyalert(
        title = "Success!",
        text  = "Proceed to 'Step 2: Options' tab\n\nPlease contact bbc@vai.org for help.",
        type  = "success"
      )
    }else{
      shinyalert::shinyalert(
        title = "Failure!",
        text  = "Redo Step 1 following any warnings/errors.\n\nPlease contact bbc@vai.org for help.",
        type  = "info"
      )
    }
    
    endSection("Check files")
  })
  
  
  ## 6.0 Create Config.yaml ----
  observeEvent(input$compileConfig, {
    startSection("Start create config files")
    
    ## Load outdir
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
    
    ## Load inputs
    refVersions <- input$refVersions
    speciesSelect <- input$speciesSelect
    fdrCutoff <- input$fdrCutoff
    pairedSingle <- input$pairedSingle
    visBigWig <- input$visBigWig
    rSeqC <- input$rSeqC
      
    ## create the config.YAML
    build_YAML(
      outputDir          = as.character(outputDir),
      ref_genome_version = as.character(refVersions),
      species_name       = as.character(speciesSelect),
      fdrCutoff          = as.numeric(fdrCutoff), # numeric
      PE_or_SE           = as.character(pairedSingle),
      run_rseqc          = as.logical(rSeqC),
      run_vis_bigwig          = as.logical(visBigWig)
    )
    showNotification(paste0("YAML created in ",outputDir,'/rnaseq_workflow/config/config.yaml'), type = "message")
    
    shinyalert::shinyalert(
      title = "Success!",
      text  = paste0("Proceed to 'Step 3: Select Comparisons' tab'\n\nPlease contact bbc@vai.org for help."),
      type  = "success"
    )
      
    activateItems(c("buildContrasts"))
    
    endSection("End create config files")
  })
  
  
  ## 7.0 Create comparisons.tsv ----
  observeEvent(input$buildContrasts, {
    repoPath <- globals$repoPath
    # pass 2 build_comparisons_TSV.R
    comparisons <- build_comparisons_TSV(
      units = globals$units,
      repoPath = repoPath
    )
    
    ncontr <- nrow(comparisons)
    output$contrastsInfo1 <- renderText({ paste0("Saved the following ",ncontr," comparisons into ",repoPath,"/config/samplesheet/comparisons.tsv") })
    output$contrastsTableOutput <- renderTable({ comparisons })
    
    # activate run analysis button -- all steps done
    activateItems(c("runWorkflow"))
    
    shinyalert::shinyalert(
      title = "Success!",
      text  = "Proceed to 'Step 4: Run Workflow' tab\n\nPlease contact bbc@vai.org for help.",
      type  = "success"
    )
  })

  ## 8.0 Run Snakemake Workflow ----
  observeEvent(input$runWorkflow, {
    repoPath <- globals$repoPath
    email <- paste0(Sys.getenv("USER"),'@vai.org')
    script <- file.path(repoPath,'bin/run_snake_APP.sh')
    ## === Submit the slurm job to run the workflow
    # Parse the job ID from sbatch output
    
    tryCatch({
      sys2_output <- system2("sbatch", 
        args = c(
          "--mail-type=END", 
          paste0('--mail-user=',email), 
          "-o", file.path(repoPath, "rnaseq_workflow_app_run.o"),
          "-e", file.path(repoPath, "rnaseq_workflow_app_run.e"),
          script
        ), 
        stdout = TRUE, 
        stderr = TRUE
      )
      job_id <- trimws(sub("Submitted batch job ", "", sys2_output))    
      globals$job_id <- job_id
      output$workflowStarted <- renderText({ paste(script,'successfully sumitted to SLURM')})
      output$job_status <- renderText({
        squeue_output <- system2("squeue", args = c("-j", job_id), stdout = TRUE)
        paste(squeue_output, collapse = "\n")
      })
      output$errorFilesEmail <- renderText({ paste0('An email will be sent to ',email,' when JOBID ',job_id,' is finished.\nSLURM output and error files are rnaseq_workflow_app_run.o and rnaseq_workflow_app_run.e in ',repoPath) })
      deactivateItems("runWorkflow") # don't let user run again if already launched
      activateItems("checkStatus")
      
      shinyalert(
        title = "Success!",
        text  = paste("You can now close this app.\n\n","Please contact bbc@vai.org with questions"),
        type  = "info"
      )
      
    }, error = function(e) {
      showNotification(e$message, type = "error")
      shinyalert(
        title = "Problem with submitting job to SLURM!",
        text  = paste(e$message,"\n\n","Please contact bbc@vai.org with questions"),
        type  = "error"
      )
    })
  })
  
  observeEvent(input$checkStatus, {
    # Poll status
    output$job_status_refresh <- renderText({
      squeue_output <- system2("squeue", args = c("-j", globals$job_id), stdout = TRUE)
      paste(squeue_output, collapse = "\n")
    })
  })
}


# ___________________ ----
# Run App ----
shinyApp(ui = ui, server = server)

