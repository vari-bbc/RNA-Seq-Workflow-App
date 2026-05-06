# ___________________ ----
# App Startup ----

if (!require("pacman", quietly = TRUE))
    install.packages("pacman", repos = "https://cloud.r-project.org")


## 1.0 Load Libraries ----
# change back to individual loads
pacman::p_load(shiny,bslib,shinyjs,shinyWidgets,bsicons,plotly,DT,readr,
               tidytable,colourpicker,pheatmap,grid,ggnewscale,stringr,
               viridis,tibble,shinyFiles,readxl,writexl,yaml,here)


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
rootDir <<- c(Home = "~", "HPC Primary" = "~/../../primary", "HPC Secondary" = "~/../../secondary")
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
    navDownload("templateDownload", "Download a Template",
                tooltipText = "Required columns: Conditions, Sample ID, ..."),
    navUpload("sampleUpload", "Upload your Sample Sheet", "Single"),
    shinyDirButton("inputPathSelect","Select Fastq Input Folder",
                   "Please select a folder", viewtype = "icon"),
    shinyDirButton("outputPathSelect","Select Workflow Output Folder",
                   "Please select a folder", viewtype = "icon"),
    navButton("checkFiles", "Check Files and Folders"),
    navOutputText("errorText"),
    navOutputText("inputErrorText"),
    navOutputText("outputErrorText")
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
    # deactivateItems(c("compileConfig","compileConfig"))

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
  # Input folder
  shinyDirChoose(input, "inputPathSelect", roots = rootDir, session = session, 
                 allowDirCreate = F, hidden = F, restrictions = restrictDir)
  
  observeEvent(input$inputPathSelect,{
    inputDir <- parseDirPath(rootDir,input$inputPathSelect)
    
    
    # Check if selected directory is readable
    
    # If it is:
    output$inputErrorText <- renderText({ paste0("The selected input directory is: ",inputDir) })
    globals$checks$inputDirCheck <- T
    # If not:
    # output$inputErrorText <- renderText({ paste0("You do not have the correct permissions 
    #                                               for the following directory: ",inputDir) })
    
    # Check if workflow is runnable
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck & globals$checks$filesCheck){
      activateItems(c("compileConfig"))
    }
  })
  
  # Output folder
  shinyDirChoose(input, "outputPathSelect", roots = rootDir, session = session)
  observeEvent(input$outputPathSelect,{
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
    
    # Check if selected directory if writable
    
    # If it is:
    output$outputErrorText <- renderText({ paste0("The selected output directory is: ",outputDir) })
    globals$checks$outputDirCheck <- T
    # If not:
    # output$outputErrorText <- renderText({ paste0("You do not have the correct permissions 
    #                                               for the following directory: ",outputDir) })
    
    # Check if workflow is runnable
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck & globals$checks$filesCheck){
      activateItems(c("compileConfig"))
    }
  })
  
  
  ## 5.0 Check Files ----
  observeEvent(input$checkFiles, {
    startSection("Check files")
    
    ## Inputs
    inputFilePath <- input$sampleUpload$datapath
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
    
    
    ## Read in xlsx first page
    #inputFile <- read_xlsx(inputFilePath, sheet = 1)
    
    ## Function to pull apart input file
    
    # Function should result in condition list
    theConditions <- c("condition1","condition2","condition3")
    

    ## App interactions
    # activate downloads/buttons, set up downloads, deactivate downloads/buttons,
    # update inputs/outputs
    
    # Check if input folder, output folder, and fastq files in input folder are good
    # If not update the corresponding error messages
    
    # If everything is good, unlock the compileConfig button
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck & globals$checks$filesCheck){
      
      
      # Interact with command line here
      # Copy github folder to outputDir
      repo.url <- "https://github.com/vari-bbc/rnaseq_workflow.git"
      message('Downloading BBC rnaseq_workflow', repo.url)
      system2("git", args = c("clone", repo.url, outputDir))
      # Sym link fastq files to proper github folder
      
      
      activateItems(c("compileConfig"))
    }
    
    # By default, select all conditions
    updateSelectizeInput(session, "relevantComps", choices = theConditions, 
                         selected = theConditions)
    
    endSection("Check files")
  })
  
  
  ## 6.0 Create Workflow Files ----
  observeEvent(input$compileConfig, {
    startSection("Create workflow files")
    
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
      print(paste("Config option PE_or_SE",as.character(input$pairedSingle),"\n"))
      
      ## create the config.YAML
      build_YAML(
        ref_genome_version = as.character(refVersions),
        species_name       = as.character(speciesSelect),
        fdrCutoff          = as.numeric(fdrCutoff), # numeric
        PE_or_SE           = as.character(pairedSingle)
      )
      showNotification("Files created!", type = "message")
      
      
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

