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
  singleTab("Input File",
    # navDownload("templateDownload", "Download a Template",
                # tooltipText = "Required columns: Conditions, Sample ID, ..."),
    navUpload("sampleUpload", "Upload Genomics PRXXXXXX_Library_Export_YYYY_MM_DD.csv)", "Single"),
    shinyDirButton("inputPathSelect","Select FASTQ Input Folder",
                   "Please select a folder", viewtype = "icon"),
    shinyDirButton("outputPathSelect","Select Workflow Output Folder",
                   "Please select a folder", viewtype = "icon"),
    navButton("checkFiles", "Check Files and Folders"),
    navOutputText("errorText"),
    navOutputText("inputErrorText"),
    navOutputText("outputErrorText"),
    navOutputText("checkLibTemplate"),
    navOutputText("gitCloneMessage"),
    navOutputText("symLinkFastq")
  ),
  
  ## 2.0 Input ----
  singleTab("Options",
    navSelect("refVersions", "Reference Version", "Single", "Locked", 
              theChoices = c("2026-02-12_15.29.54_v23","2025-12-18_22.42.45_v22")),
    navSelect("speciesSelect","Select the Species", "Single", "Locked",
              theChoices = c("human_hg38_gencode","mouse_mm10_gencode","mouse_mm39_gencode")),
    navNumeric("fdrCutoff","False discover rate", 0.01, tooltipText = "Default: 0.01"),
    navSelect("pairedSingle","Paired-end or single-end genomics library", "Single", "Locked",
              theChoices = c("Paired End","Single End")),
    navCheckbox("visBigWig","Run VisBigWig", "True"),
    navCheckbox("rSeqC","Run rSeqC", "True"),
    actionButton("compileConfig","Compile Config"),
    hr(),
    navDownload("workflowFiles","Download a Zip of the Workflow Input Files")
  ),
  singleTab("Select Comparisons and Run",
    navSelect("relevantComps", "Select Comparisons", "Multi", "Locked")
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
      filesCheck = F
    )
  )
  
  
  ## 2.0 Run on Start ----
  # Hide pages and deactivate buttons that should not be used yet
  observe({
    startSection("Run on Start")
    
    # Deactivate buttons that need other things to function
    deactivateItems(c("compileConfig","checkFiles"))

    # Deactivate downloads that need other things to function
    deactivateItems(c("workflowFiles"))
    
    #Unnecessary for final app, actually used elsewhere
    output$errorText <- renderText({ "Text here will display if sample sheet is proper" })
    
    endSection("Run on Start")
  })
  
  
  ## 3.0 File Imports ----
  output$templateDownload <- downloadHandler(
    filename = function() {
      paste("sampleTemplate.xlsx")
    },
    content = function(file) {
      writexl::write_xlsx(template, file)
    }
  )
  
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
    if (dir.exists(repoPath) && length(list.files(repoPath)) > 0) {
      shinyalert(
        title = "'rnaseq_workflow' repository already exists in selected workflow output folder",
        text  = paste0("'", repoPath, "' already exists and is not empty. Please choose a different output folder or remove the existing 'rnaseq_workflow' directory from ",outputDir,"."),
        type  = "error"
      )
      return()
    }
    
    
    # Check if selected directory is writable
    # Returns TRUE if writable, FALSE otherwise
    is_writable <- file.access(outputDir, mode = 2) == 0
    warning("is_writable: ",is_writable)
    if(is_writable == TRUE){
      output$outputErrorText <- renderText({ paste0("The selected output directory is: ",outputDir) })
      globals$checks$outputDirCheck <- TRUE
      
    }else{
      shinyalert(
        title = "Selected Output Directory Not Writable",
        text = paste("The selected directory is not writable:\n\n", outputDir,
                     "\n\nPlease select a different directory with write permissions."),
        type = "error"
      )
      return()
    }
    
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck){
      activateItems(c("checkFiles"))
    }
  })
  
  
  ## 5.0 Check Files ----
  observeEvent(input$checkFiles, {
    startSection("Check files")
    
    ## Inputs
    inputDir <- parseDirPath(rootDir,input$inputPathSelect)
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
    
    
    ## Read in xlsx first page
    #inputFile <- read_xlsx(inputFilePath, sheet = 1)
    
    ## Function to pull apart input file
    # check that all 'Library Name' files are also FASTQS
    output$checkLibTemplate <- renderText({ paste("Placeholder message for checking lib_template.csv against inputDir .fastq.gz files") })
    # Function should result in condition list
    theConditions <- c("condition1","condition2","condition3")
    

    ## App interactions
    # activate downloads/buttons, set up downloads, deactivate downloads/buttons,
    # update inputs/outputs
    
    # Check if input folder, output folder, and fastq files in input folder are good
    # If not update the corresponding error messages
    
    # If everything is good, unlock the compileConfig button
    # and download the rnaseq_workflow github repository
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck){
      
      
      
      # Clone github folder to outputDir
      repo.url <- "https://github.com/vari-bbc/rnaseq_workflow.git"
      repoName <- gsub(pattern = '.git$',replacement = '',x = basename(repo.url))
      repoPath <- file.path(outputDir, repoName)
      # 
      # # Check if repo already exists --
      # if (dir.exists(repoPath) && length(list.files(repoPath)) > 0) {
      #   shinyalert(
      #     title = "'rnaseq_workflow' repository already exists in selected workflow output folder",
      #     text  = paste0("'", repoPath, "' already exists and is not empty. Please choose a different output folder or remove the existing 'rnaseq_workflow' directory from ",outputDir,"."),
      #     type  = "error"
      #   )
      #   return()  # or req(FALSE) if inside a reactive
      # }
      
      message('Downloading BBC rnaseq_workflow', repo.url, "into", repoPath)
      system2("git", args = c("clone", repo.url, repoPath))
      output$gitCloneMessage <- renderText({ paste("Cloned",repoName,"into",repoPath) })
      
      # require that repo exists
      # req(
      # Sym link fastq files to repoPath/raw_data

      message("getwd",getwd())
      message("inputFilePath",inputDir)
      message("repoPath",repoPath)
      message("list.files(inputDir)",list.files(inputDir, pattern = "\\.fastq\\.gz$"))
      
      system2("ln", args = c(
        "-s",
        file.path(inputDir, list.files(inputDir, pattern = "\\.fastq\\.gz$")),
        file.path(repoPath,'raw_data')
      ))
      output$symLinkFastq <- renderText({ paste("FASTQ Files ln -s OK -- Proceed to 'Options' Tab",repoName,"into",repoPath) })
      
      activateItems(c("compileConfig"))
    }
    
    # By default, select all conditions
    updateSelectizeInput(session, "relevantComps", choices = theConditions, 
                         selected = theConditions)
    
    globals$checks$filesCheck <- TRUE
    
    # Check if workflow is runnable -- should all be TRUE to get to here anyway ...
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck & globals$checks$filesCheck){
      activateItems(c("compileConfig"))
    }
    
    endSection("Check files")
  })
  
  
  ## 6.0 Create Workflow Files ----
  observeEvent(input$compileConfig, {
    startSection("Create workflow files")
    
    ## Load outdir
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
    
    ## Load inputs
    refVersions <- input$refVersions
    speciesSelect <- input$speciesSelect
    fdrCutoff <- input$fdrCutoff
    pairedSingle <- input$pairedSingle
    visBigWig <- input$visBigWig
    rSeqC <- input$rSeqC
    relevantComps <- input$relevantComps
    
    
    ## Check that there are a minimum of 2 conditions selected first!
    
    ## Check that the output folder, input folder, and fastq files are good
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck & globals$checks$filesCheck){
      ## Create config file into output directory
      
      # print config options -- testing --
      print(paste("Config option PE_or_SE",pairedSingle,"\n"))
      print(paste("outputDir",outputDir,"\n"))
      
      ## create the config.YAML
      build_YAML(
        outputDir          = as.character(outputDir),
        ref_genome_version = as.character(refVersions),
        species_name       = as.character(speciesSelect),
        fdrCutoff          = as.numeric(fdrCutoff), # numeric
        PE_or_SE           = as.character(pairedSingle)
      )
      showNotification(paste0("YAML created in ",outputDir,'/rnaseq_workflow/config/config.yaml'), type = "message")
      
      
      ## Create comparisons dataframe from selections
    
      
      ## Create units dataframe from selections
      
      
      ## App interactions
      
      # Create zip folder of config file, unit file, and comparison file
      activateItems(c("workflowFiles"))
      output$workflowFiles <- downloadHandler(
        filename = function() {
          "RNA Seq Workflow Files.zip"
        },
        content = function(file) {
          disable("workflowFiles")
          # Make config file (should be a function to use again later)
          
          # Make other two dataframes into files
          
          # Combine all three files into one zip
          
          print("Done Downloading zip")
        }
      )
      
    }
    
    endSection("Create workflow files")
  })
  
}


# ___________________ ----
# Run App ----
shinyApp(ui = ui, server = server)

