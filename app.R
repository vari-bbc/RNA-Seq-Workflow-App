# ___________________ ----
# App Startup ----

if (!require("pacman", quietly = TRUE))
    install.packages("pacman", repos = "https://cloud.r-project.org")


## 1.0 Load Libraries ----
# change back to individual loads
pacman::p_load(shiny,bslib,shinyjs,shinyWidgets,bsicons,plotly,DT,readr,
               tidytable,colourpicker,pheatmap,grid,ggnewscale,stringr,
               viridis,tibble,shinyFiles,readxl,writexl,yaml,here,shinyjs,shinyalert,shinyFiles)


## 2.0 Load Basics ----
functionFolderPath <<- "Functions"
source(paste0(functionFolderPath,"/Updated Shiny RMD Standards.R"))
sourceFunctions(functionFolderPath)


## 3.0 Universal Vars ----fr
# App Name here:
appName <<- "RNA Seq Workflow Starter"
cardHeight <<- '65vh'
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
  useShinyjs(),
  uiOutput("tab_buttons"), 
  progressBar(id = "workflow_progress", value = 1, total = 1, display_pct = FALSE),
  navset_hidden(
    id = "main_tabs",
    
    nav_panel("step1",card( height = cardHeight,
       navUpload("sampleUpload", "Select Samplesheet", "Single"),
        navOutputText("sampleUploadText"),
        navOutputText("showUnitsTSV_Message"),
        tableOutput("showUnitsTSV")
      )
    ),
    nav_panel("step2",card( height = cardHeight,
        shinyDirButton("fastqPathSelect","Select FASTQ Input Folder",
                   "Please select folder with FASTQs", viewtype = "icon"),
        navOutputText("fastqDirText"),
        navOutputText("fqFound")
      ),
    ),
    nav_panel("step3",card( height = cardHeight,
        shinyDirButton("outputPathSelect","Select Output Folder",
                       "Please select a folder to run the analysis", viewtype = "icon"),
        navOutputText("outputErrorText"),
        navOutputText("outputErrorText2"),
        navButton("downloadRepo", "Download Workflow"),
        navOutputText("gitCloneMessage"),
        navOutputText("symLinkFastq"),
        navOutputText("wroteUnitsTSV")
      ),
    ),
    nav_panel("step4",card( height = cardHeight,
        navSelect("refVersions", "Reference Version", "Single", "Locked", 
                  theChoices = c("2026-02-12_15.29.54_v23","2025-12-18_22.42.45_v22")),
        navSelect("speciesSelect","Select the Species & Annotation", "Single", "Locked",
                  theChoices = c("human_hg38_gencode","mouse_mm10_gencode","mouse_mm39_gencode")),
        navNumeric("fdrCutoff","False discover rate", 0.01, tooltipText = "Default: 0.01",min=0,max=1),
        navSelect("pairedSingle","Paired-end or single-end genomics library", "Single", "Locked",
                  theChoices = c("Paired End","Single End")),
        navCheckbox("visBigWig","Run VisBigWig", "True"),
        navCheckbox("rSeqC","Run rSeqC", "True"),
        actionButton("compileConfig","Compile Config"),
        hr(),
      ),
    ), 
    nav_panel("step5",card( height = cardHeight,
        fluidRow(
          column(12,
           p("'comparisons.tsv' is used to run differential expression contrasts in the RNAseq workflow."),
           # p("From the column group, we have identified the following available contrasts."),
           p("We are working to build more options. For now, contact bbc@vai.org for help building more complicated contrasts.")
          )
        ),
        actionButton("buildContrasts","Build contrasts from units.tsv group column"),
        navOutputText("contrastsInfo1"),
        tableOutput("contrastsTableOutput"),
        actionButton("editComparisons", "Optional: edit comparisons.tsv"),
        verbatimTextOutput("filepath")
      ),
    ),
    nav_panel('step6',card( height = cardHeight,
        actionButton("runWorkflow","Start Snakemake RNAseq Workflow"),
        navOutputText("workflowStarted"),
        verbatimTextOutput("job_status"),
        navOutputText("errorFilesEmail"),
        actionButton("checkStatus","Click here to refresh job status"),
        verbatimTextOutput("job_status_refresh"),
        actionButton("openResults","Open the results folder"),
        downloadButton("downLoadFinalReport", "Download Results")
      )
    ),
    nav_panel("stepb1",card( height = cardHeight,
        shinyDirButton("selectExistingWorkflow","Select Existing 'rnaseq_workflow' Folder",
                       "Select Existing 'rnaseq_workflow' Folder", viewtype = "icon"),
      )
    ),
    nav_panel('stepb2',card( height = cardHeight,
         actionButton("checkStatus_b2","Click here to refresh job status"),
         verbatimTextOutput("job_status_refresh"),
         actionButton("openResults_b2","Open the results folder"),
         downloadButton("downLoadFinalReport_b2", "Download Results")
      )
    )
  ),
  div(
    style = "padding: 0px 10px; text-align: center;",
    actionButton("btn_prev", "< Previous", class = "btn-secondary"),
    actionButton("btn_next", "Next >", class = "btn-primary")
  ),
  tags$footer(
    fluidRow(
      column(12,
             p("contact bbc@vai.org for help."),
             style = "text-align: center; padding: 15px; border-top: 1px solid #ddd; margin-top: 20px; color: #666;"
      )
    )
  )
)
  
  
# ___________________ ----
# Server ----

server <- function(session, input, output) {
  
  ## 0.1 Global Vars ----
  # Any variables here that need to carry across app sections, but should be local to the user
  # Keep all variables inside a list to help with debugging later
  globals <- reactiveValues(
    checks = list(
      fastqFilesFound = FALSE,
      outputDirCheck = FALSE,
      sampleSheetCheck = FALSE,
      gitCheck = F
    ),
    library_template = NULL,
    samplesheet_path = NULL,
    units = NULL,
    repoPath = NULL,
    tab_order = NULL, # for dynamic tabs
    current_index = 1 # for dynamic tabs
  )
  
  observe({
    # Deactivate buttons that need other things to function
    deactivateItems(
      c(
        # "fastqPathSelect",
        # "outputPathSelect",
        # "compileConfig",
        # "buildContrasts",
        # "editComparisons",
        # "downloadRepo",
        # "runWorkflow",
        # "checkStatus",
        # "btn_next",
        # "btn_prev"
      )
    )
  })
  
  ## 0.1.2 Modals ----
  # --- Modal ---
  showModal(
    modalDialog(
      title = "Welcome",
      "Would you like to launch a workflow or check an existing one?",
      footer = tagList(
        actionButton("btn_new", "Start New", class = "btn-primary"),
        actionButton("btn_existing", "Already Exists")
      ),
      easyClose = FALSE
    )
  )
  
  observeEvent(input$btn_new, {
    removeModal()
    # rv$path <- "new"
    globals$tab_order <- c("step1", "step2", "step3", "step4", "step5", "step6", "step7")
    globals$current_index <- 1
    nav_select("main_tabs", selected = globals$tab_order[1])
    total_steps <- length(globals$tab_order)
    updateProgressBar(
      session = session,
      id = "workflow_progress",
      value = 1,          # Start at the first tab
      total = total_steps,
      range_value = c(1,total_steps)
    )
  })
  
  observeEvent(input$btn_existing, {
    removeModal()
    # rv$path <- "existing"
    globals$tab_order <- c("stepb1", "stepb2")
    globals$current_index <- 1
    nav_select("main_tabs", selected = globals$tab_order[1])
    total_steps <- length(globals$tab_order)
    updateProgressBar(
      session = session,
      id = "workflow_progress",
      value = 1,          # Start at the first tab
      total = total_steps,
      range_value = c(1,total_steps)
    )
  })
  
  observe({
    n <- length(globals$tab_order)
    i <- globals$current_index
    
    # Toggle visibility instead of recreating the UI
    # toggleState("btn_prev", condition = (i > 1))
    # toggleState("btn_next", condition = (i < n))
  })
  
  observeEvent(input$btn_next, {
    globals$current_index <- min(globals$current_index + 1, length(globals$tab_order))
    message('globals$current_index',globals$current_index)
    nav_select("main_tabs", selected = globals$tab_order[globals$current_index])
    # stop users from going to next until action taken
    updateProgressBar(
      session = session,
      id = "workflow_progress",
      value = globals$current_index,
      total = length(globals$tab_order),
      range_value = c(1,length(globals$tab_order))
    )
    # deactivateItems("btn_next")
  })
  
  observeEvent(input$btn_prev, {
    globals$current_index <- max(globals$current_index - 1, 1)
    message('globals$current_index',globals$current_index)
    nav_select("main_tabs", selected = globals$tab_order[globals$current_index])
    
    updateProgressBar(
      session = session,
      id = "workflow_progress",
      value = globals$current_index,
      total = length(globals$tab_order),
      range_value = c(1,length(globals$tab_order))
    )
    
  })

  
  
  ## 1.0 Import Samplesheet ----
  observeEvent(input$sampleUpload, {
    req(input$sampleUpload)
    
    file <- input$sampleUpload
    globals$samplesheet_path <- file$name

    # Check file extension
    ext <- tools::file_ext(file$name)
    df <- NULL
    if (tolower(ext) == "csv") {
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
    }else if (tolower(ext) == "tsv") {
      # Read TSV into data.frame and save it as a global variable
      df <- tryCatch({
        read.delim(file$datapath, sep = "\t", stringsAsFactors = FALSE)
        
      }, error = function(e) {
        shinyalert::shinyalert(
          title = "File Read Error",
          text  = paste("Could not read",file$name,"\n\n", e$message),
          type  = "error"
        )
        return(NULL)
      })
    }else{
      shinyalert::shinyalert(
        title = "File Read Error",
        text  = paste("Will not read in file with extension",ext,"\n\n",file$name),
        type  = "error"
      )
    }
    
    req(df)
    
    build_units_TSV_output <- NULL
    # ==  Create the repoPath/config/samplesheet/units.tsv file
    tryCatch({
      message('inputFile=',file$name)
      message('df=',class(df))
      build_units_TSV_output <- build_units_TSV(
        inputFile = file$name,
        df = df
      )
      globals$checks$sampleSheetCheck <- TRUE
      globals$units <- build_units_TSV_output[['units']]
      
      shinyalert(
        title = "Samplesheet Uploaded!",
        text  = paste("Go to next\n\n","Please contact bbc@vai.org with questions"),
        type  = "success"
      )
    }, error = function(e) {
      showNotification(e$message, type = "error")
      shinyalert(
        title = "Problem with the samplesheet!",
        text  = paste(e$message,"\n\n","Please contact bbc@vai.org with questions"),
        type  = "error"
      )
      globals$checks$sampleSheetCheck <- FALSE
    })
    
    # messaging
    output$sampleUploadText <- renderText({ paste('Samplesheet Loaded:',file$name,"\n") })
    output$showUnitsTSV_Message <- renderText({ "units.tsv to be created for workflow:" })
    output$showUnitsTSV <- renderTable({ build_units_TSV_output[['units']] })
    
    if(globals$checks$sampleSheetCheck){
      activateItems(c('fastqPathSelect','btn_next'))
    }
  })
  
  ## 2.0 Select FASTQ Folder ----
  shinyDirChoose(input, "fastqPathSelect", roots = rootDir, session = session, filetypes = character(0),
                 allowDirCreate = FALSE, hidden = FALSE, restrictions = restrictDir)
  
  observeEvent(input$fastqPathSelect,{
    fastqDir <- parseDirPath(rootDir,input$fastqPathSelect)
    
    req(parseDirPath(rootDir, input$fastqPathSelect) != "") # this stops code being run until a dir is selected
    
    # Check if selected directory is readable
    # Returns TRUE if readable, FALSE otherwise
    is_readable <- file.access(fastqDir, mode = 4) == 0
    warning("is_readable: ",is_readable)
    if(is_readable == TRUE){
      output$fastqDirText <- renderText({ paste0("The selected input directory is: ",fastqDir) })
    }else{
      shinyalert(
        title = "Selected FASTQ Directory Not Readable",
        text = paste("The selected directory is not readable:\n\n", fastqDir,
                     "\n\nPlease select a different directory with read permissions."),
        type = "error"
      )
      return()
    }
    
    # check that FASTQs exist in fastqDir
    check_FASTQs_result <- check_FASTQs(
      units = globals$units,
      fastqDir = fastqDir
    )
    
    if(check_FASTQs_result[['all_fq1_found']]==FALSE){
      shinyalert(
        title = "fq1 files missing!",
        text  = paste0("Not all read 1 FASTQs from fq1 column of units.tsv (Step 1) were found in ",fastqDir,"."),
        type  = "warning"
      )
      globals$checks$fastqFilesFound <- FALSE
    }else if(check_FASTQs_result[['all_fq2_found']]==FALSE){
      shinyalert(
        title = "fq2 files missing!",
        text  = paste0("Not all read 2 FASTQs from fq2 column of units.tsv (Step 1) were found in ",fastqDir,"."),
        type  = "warning"
      )
      globals$checks$fastqFilesFound <- FALSE
    }else{
      globals$checks$fastqFilesFound <- TRUE
      # get # of files
      n <- nrow(globals$units)
      output$fqFound <- renderText({ paste0("Found all ",n," expected FASTQs in ",fastqDir," from column 'fq1' and 'fq2' of ",globals$samplesheet_path) })
      shinyalert(
        title = "FASTQ Files OK!",
        text  = paste0("Go to next"),
        type  = "success"
      )
    }
    
    # Check if 'Check Files and Folders' runnable
    if (globals$checks$fastqFilesFound){
      activateItems(c("outputPathSelect","btn_next"))
    }
  })
  
  ## 3.1 Select Output Folder ----
  shinyDirChoose(input, "outputPathSelect", roots = rootDir, session = session, filetypes = character(0),
                 allowDirCreate = TRUE)
  observeEvent(input$outputPathSelect,{
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
    
    req(parseDirPath(rootDir, input$outputPathSelect) != "") # this stops code being run until a dir is selected
    
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
    
    ### 
    # Check if rnaseq_workflow github repo already exists
    repo.url <- "https://github.com/vari-bbc/rnaseq_workflow.git"
    repoName <- gsub(pattern = '.git$',replacement = '',x = basename(repo.url))
    repoPath <- file.path(outputDir, repoName)
    if (dir.exists(repoPath) && length(list.files(repoPath)) > 0) {
      shinyalert(
        title = "An 'rnaseq_workflow' repository already exists in the selected workflow output folder",
        text  = paste0("'", repoPath, "' already exists and is not empty. Please choose a different output folder or remove the existing 'rnaseq_workflow' directory from ",outputDir,"."),
        type  = "warning"
      )
      globals$checks$outputDirCheck <- FALSE # disable if already exists
      return()
    }
    
    
    if (globals$checks$fastqFilesFound & globals$checks$outputDirCheck){
      activateItems(c("downloadRepo"))
      output$outputErrorText2 <- renderText({ 'You can now download the workflow!' })
      deactivateItems(c("sampleUpload","fastqPathSelect","outputPathSelect"))
    }
  })
  
  ## 3.2 download repo, ln -s .fq, write units.tsv ----
  observeEvent(input$downloadRepo, {
    startSection("Download github repo")
    
    # == Inputs
    fastqDir <- parseDirPath(rootDir,input$fastqPathSelect)
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
      
    # ==  Clone github folder to outputDir ==
    repo.url <- "https://github.com/vari-bbc/rnaseq_workflow.git"
    repoName <- gsub(pattern = '.git$',replacement = '',x = basename(repo.url))
    repoPath <- file.path(outputDir, repoName)
    message('repoPath:',repoPath)
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
    
    # == Link the fastqDir FASTQs to repoPath/raw_data ==
    system2("ln", args = c(
      "-s",
      file.path(fastqDir, list.files(fastqDir, pattern = "\\.fastq\\.gz$|\\.fq\\.gz$")),
      file.path(repoPath,'raw_data')
    ))
    output$symLinkFastq <- renderText({ paste0("FASTQ files linked from ",fastqDir," into ",repoPath,"/raw_data/") })
    
    # write units.tsv
    readr::write_delim(globals$units,file=file.path(repoPath,'config/samplesheet/units.tsv'),
    delim="\t",quote="none")
    output$wroteUnitsTSV <- renderText({ "units.tsv saved" })
    
    
    if (globals$checks$gitCheck){
      shinyalert::shinyalert(
        title = "Success!",
        text  = "Go to next\n\nPlease contact bbc@vai.org for help.",
        type  = "success"
      )
      activateItems(c("compileConfig",'btn_next'))
      deactivateItems(c("downloadRepo"))
    }else{
      shinyalert::shinyalert(
        title = "Failure!",
        text  = "Redo Step 1 following any warnings/errors.\n\nPlease contact bbc@vai.org for help.",
        type  = "info"
      )
    }
    
    endSection("Check files")
  })
  
  
  ## 4.0 Create Config.yaml ----
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
      text  = paste0("Go to next\n\nPlease contact bbc@vai.org for help."),
      type  = "success"
    )
      
    activateItems(c("buildContrasts",'btn_next'))
    
    endSection("End create config files")
  })
  
  
  ## 5.1 Select Comparisons ----
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
    activateItems(c("runWorkflow","editComparisons",'btn_next'))
    
    shinyalert::shinyalert(
      title = "Success!",
      text  = "Go to next\n\nPlease contact bbc@vai.org for help.",
      type  = "success"
    )
    
    dir <- file.path(repoPath,'config/samplesheet/comparisons.tsv')
    
    
    
  })
  
  # 5.2 Edit Comparisons ----
  observeEvent(input$editComparisons, {
    runjs("window.open('https://ondemand1.vai.zone/pun/sys/dashboard/files/edit/fs/varidata/research/projects/bbc/ian/comparisons.tsv', '_blank');")  
  })
  
  
  ## 6.1 Run Snakemake Workflow ----
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
        title = "Workflow Launched!",
        text  = paste("\n\n","Please contact bbc@vai.org with questions"),
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
  
  ## 6.2 Check Job Status ----
  observeEvent(input$checkStatus, {
    # Poll status
    output$job_status_refresh <- renderText({
      squeue_output <- system2("squeue", args = c("-j", globals$job_id), stdout = TRUE)
      paste(squeue_output, collapse = "\n")
    })
  })
  
  ## 6.3 Open Results Folder ----
  observeEvent(input$openResults, {
    runjs("window.open('https://ondemand1.vai.zone/pun/sys/dashboard/files/fs/varidata/researchtemp/hpctmp/ian.beddows/rnaseq_workflow/results', '_blank');")  
  })
 
  ## 6.2 Download Final Report ----
  output$downLoadFinalReport <- downloadHandler(
    filename = function() {
      "BBC_RNAseq_Report.zip"
    },
    content = function(file) {
      zip(
        zipfile = file,
        files = "/varidata/researchtemp/hpctmp/ian.beddows/rnaseq_workflow/results/make_final_report/BBC_RNAseq_Report",
        flags = "-r"   # recursive
      )
    }
  )
}


# ___________________ ----
# Run App ----
shinyApp(ui = ui, server = server)

