# ___________________ ----
# App Startup ----

if (!require("pacman", quietly = TRUE))
    install.packages("pacman")


## 1.0 Load Libraries ----
# change back to individual loads
pacman::p_load(shiny,bslib,shinyjs,shinyWidgets,bsicons,plotly,DT,readr,
               tidytable,colourpicker,pheatmap,grid,ggnewscale,stringr,
               viridis,tibble,shinyFiles,readxl)


## 2.0 Load Basics ----
functionFolderPath <<- "Functions"
source(here::here(paste0(functionFolderPath,"/Updated Shiny RMD Standards.R")))
sourceFunctions(functionFolderPath)


## 3.0 Universal Vars ----
# App Name here:
appName <<- "RNA Seq Workflow Starter"
# Necessary Files here:
template <<- read_excel("Necessary Files/SampleTemplate.xlsx", sheet = 1)
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
    navButton("uploadButton", "Load the Samples"),
    navOutputText("errorText")
  ),
  
  ## 2.0 Input ----
  singleTab("Options",
    navSelect("refVersions", "Reference Version", "Single", "Locked", 
              theChoices = c("2026-02-12_15.29.54_v23","2025-12-18_22.42.45_v22")),
    navSelect("speciesSelect","Select the Species", "Single", "Locked",
              theChoices = c("hg38_gencode","mm10_gencode","mm39_gencode")),
    navNumeric("fdrCutoff","FDR Cutoff", 0.01, tooltipText = "Default: 0.01"),
    navCheckbox("pairedSingle","Single End", "False", 
                tooltipText = "Default is Paired End, switch on to select Single End"),
    navCheckbox("visBigWig","Run VisBigWig", "True"),
    navCheckbox("rSeqC","Run rSeqC", "True"),
    navSelect("relevantComps", "Select Comparisons", "Multi", "Locked"),
    navButton("createFiles","Create Files for Workflow"),
    hr(),
    navDownload("workflowFiles","Download a Zip of the Workflow Files")
  ),
  
  ## 3.0 Run Workflow ----
  singleTab("Run Workflow",
    shinyDirButton("inputPathSelect","Select Fastq Input Folder",
                   "Please select a folder", viewtype = "icon"),
    shinyDirButton("outputPathSelect","Select Workflow Output Folder",
                   "Please select a folder", viewtype = "icon"),
    navButton("runWorkflow","Run the Whole Workflow", 
              tooltipText = "You will receive an email once it is done with a 
              link to the output location"),
    navOutputText("inputErrorText"),
    navOutputText("outputErrorText"),
    navOutputText("notificationText")
  )

)


# ___________________ ----
# Server ----

server <- function(session, input, output) {
  
  ## 1.0 Global Vars ----
  # Any variables here that need to carry across app sections, but should be local to the user
  # Keep all variables inside a list to help with debugging later
  globals <- reactiveValues(
    datasets = list(
      configSettings = data.frame(
        ref_genome_version = NULL,
        speciec_name = NULL
        # And so on for every part we want changable
      ),
      unitsTSV = NULL,
      comparisonsTSV = NULL
    ),
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
    deactivateItems(c("createFiles","runWorkflow"))

    # Deactivate downloads that need other things to function
    deactivateItems(c("workflowFiles"))
    
    #Unnecessary for final app, actually used elsewhere
    output$errorText <- renderText({ "Text here will display if selected file path is inaccessible" })
    
    endSection("Run on Start")
  })
  
  
  ## 3.0 File Imports ----
  output$templateDownload <- downloadHandler(
    filename = function() {
      paste("sampleTemplate.xlsx")
    },
    content = function(file) {
      write_xlsx(template, file)
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
      activateItems(c("runWorkflow"))
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
      activateItems(c("runWorkflow"))
    }
  })
  
  
  ## 5.0 Initial Sample Upload ----
  observeEvent(input$uploadButton, {
    startSection("Initial sample upload")
    
    ## Inputs
    inputFilePath <- input$sampleUpload$datapath
    
    
    ## Read in xlsx first page
    inputFile <- read_xlsx(inputFilePath, sheet = 1)
    
    # Function to pull apart file
    
    # Should get all conditions
    theConditions <- c("condition1","condition2","condition3")
    

    ## App interactions
    # activate downloads/buttons, set up downloads, deactivate downloads/buttons,
    # update inputs/outputs
    
    activateItems(c("createFiles"))
    
    # By default, select all conditions
    updateSelectizeInput(session, "relevantComps", choices = theConditions, 
                         selected = theConditions)
    
    endSection("Initial sample upload")
  })
  
  
  ## 6.0 Update Config Options ----
  # All user inputs to config saved here (also any checks we want for inputs should be here)
  observeEvent(input$refVersions,{
    globals$dataframes$configOptions$ref_genome_version <- input$refVersions
  })
  
  
  ## 7.0 Create Workflow Files ----
  observeEvent(input$createFiles, {
    startSection("Create workflow files")
    
    ## Load globals
    configSettings <- globals$dataframes$configSettings
    
    
    ## Inputs
    # Load all non config user inputs here
    
    
    ## Check that there are a minimum of 2 conditions selected first!
    
    ## Create comparisons dataframe from selections
    
    ## Create units dataframe from selections

    ## App interactions
    
    globals$checks$filesCheck <- T
    
    # Check if workflow is runnable
    if (globals$checks$inputDirCheck & globals$checks$outputDirCheck & globals$checks$filesCheck){
      activateItems(c("runWorkflow"))
    }
    
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

    ## Save globals
    # Save all files here for use in running actual workflow
    globals$dataframes$unitsTSV <- unitsTSV
    globals$dataframes$comparisionsTSV <- comparisionsTSV 
    
    
    endSection("Create workflow files")
  })
  
  
  ## 8.0 Run Workflow ----
  observeEvent(input$runWorkflow, {
    startSection("Run workflow")
    
    ## Load globals
    configSettings <- globals$dataframes$configSettings
    unitsTSV <- globals$dataframes$unitsTSV
    comparisionsTSV <- globals$dataframes$comparisionsTSV
    
    
    ## Inputs
    inputDir <- parseDirPath(rootDir,input$inputPathSelect)
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)
    
    
    ## Make and save config file to input dir
    
    ## Make and save units to input dir
    
    ## Make and save comparisons to input dir
    
    ## Check proper fastq files are in input dir
    
    ## Run command line prompt to do the workflow
    
    ## update notificationText
    output$notificationText <- renderText({ "The workflow has started running. You will recieve an email when it is donw." })
    
    endSection("Run workflow")
  })
  
}


# ___________________ ----
# Run App ----
shinyApp(ui = ui, server = server)

