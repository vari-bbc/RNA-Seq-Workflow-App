# ___________________ ----
# App Startup ----

if (!require("pacman", quietly = TRUE))
    install.packages("pacman", repos = "https://cloud.r-project.org")

testing <- 1
## 1.0 Load Libraries ----
# change back to individual loads
pacman::p_load(shiny,bslib,shinyjs,shinyWidgets,bsicons,plotly,DT,readr,
               tidytable,colourpicker,pheatmap,grid,ggnewscale,stringr,
               viridis,tibble,shinyFiles,readxl,writexl,yaml,here,shinyjs,shinyalert,shinyFiles)


## 2.0 Load Basics ----
functionFolderPath <<- "Functions"
source(paste0(functionFolderPath,"/Updated Shiny RMD Standards.R"))
sourceFunctions(functionFolderPath)

refVersionChoices <- c("latest","2026-02-12_15.29.54_v23","2025-12-18_22.42.45_v22")
speciesSelectChoices <- c("human_hg38_gencode","mouse_mm10_gencode","mouse_mm39_gencode","worm_c.elegans-WBcel235","fly_dm6_BDGP6.28.100", "zebrafish_GRCz11")
## 3.0 Universal Vars ----fr
# App Name here:
appName <<- "BBC RNAseq App"
cardHeight <<- '65vh'
# Necessary Files here:
# template <<- read_excel(paste0("Necessary Files/SampleTemplate.xlsx"), sheet = 1)
# Root Dir for Folder Selection:
rootDir <<- c('HPC Home Directory' = file.path("/home",Sys.getenv("USER")),
              'Local Home Directory' = "~",
              "HPC Lab Folders" = "/varidata/research/projects/",
              "HPC Temp Folder" = "/varidata/researchtemp/hpctmp/"
)
restrictDir <<- c("afs","bin","cloudstorage","cm","dev","etc","legacy","lib",
                  "lib64","localdisk","media","mnt","opt","proc","root","run",
                  "sbin","srv","sys","tmp","usr")


# ___________________ ----
# UI ----
# Ensure use of document outline and preloading as many inputs as possible
# Tool tips are last in nav item and should be specified with tooltipText = "..."
ui <- UINav2(
  # useShinyjs(), # already called in UINav
  uiOutput("tab_buttons"),
  progressBar(id = "workflow_progress", value = 1, total = 1, display_pct = FALSE),
  navset_hidden(
    id = "main_tabs",
    nav_panel("step1",
      card( height = cardHeight,
        layout_sidebar( sidebar = sidebar(position = "right",
          navOutputText("sampleUploadText"),
          navOutputText("showUnitsTSV_Message"),
          textOutput("showUnitsTSV_Message2", inline = FALSE) |>
            tagAppendAttributes(style = "font-size: 15px;")
        ),
          navUpload(
            "sampleUpload",
            tagList(
              bsicons::bs_icon("table", size = "1.5em"),
              tags$span("Select Samplesheet", style = "font-size: 1.4rem; vertical-align: middle;")
            ),
            "Single",
            tooltipText = 'The samplesheet must include two columns: \"sample\" & \"group\". The group column designates sample groups to be compared during the differential expression workflow. Columns named \"fq1\" and \"fq2\" designate the input fastq file names. These columns are needed for the workflow, but optional here; if they are not included, an attempt to find the FASTQ files will be made after a FASTQ folder is selected (next tab). Input file must have a .tsv (tab-separated values) or .csv (comma-separated values) extension.'
          ),
          DTOutput("showUnitsTSV")
        )
      )
    ),
    nav_panel("step2",
      card( height = cardHeight,
        layout_sidebar( sidebar = sidebar(position = "right",
          navButton("showSampleSheet2","Show/edit Sample Sheet"),
          navOutputText("fastqDirText"),
          navOutputText("fq1Found"),
          navOutputText("fq2Found"),
          navOutputText("unitsTitle")
        ),
          tooltip(
            shinyDirButton(
              id    = "fastqPathSelect",
              label = "Select folder with FASTQ files",
              title = "Select folder with FASTQ files",
              icon  = bsicons::bs_icon("folder-plus", size = "1.5em"),
              class = "btn-default",
              style = "font-size: 1.5rem; padding: 0.75rem 1.5rem;"
            ),
            # 'If fq[12] columns missing, then FASTQs are searched using the following regex\n paste0("^", sample, ".*_R?[12].*\\.(fastq|fq)\\.gz$$")'
            'If fq1 and fq2 columns are missing from the samplesheet,  then an attempt is made to associate samples to files in the selected folder. To be found, FASTQ files MUST start with the sample name followed by an underscore; end in fastq.gz or fq.gz; and have a _1 or _R1 to designate fq1 and _2/_R2 for fq2.)'
          ),
          tableOutput("showUnitsFastqStep")
        )
      ),
    ),
    nav_panel("step3",
      card( height = cardHeight,
        layout_sidebar(
          sidebar = sidebar(position = "right",
            navButton("showSampleSheet3","Show/edit Sample Sheet"),
            navOutputText("outputErrorText"),
            navOutputText("outputErrorText2"),
            navOutputText("gitCloneMessage"),
            navOutputText("symLinkFastq"),
            navOutputText("wroteUnitsTSV")
          ),
          div(
            style = "display: flex; flex-direction: column; gap: 2rem;",
            shinyDirButton(
              id    = "outputPathSelect",
              label = "Please select a folder to run the analysis",
              title = "Please select a folder to run the analysis",
              icon  = bsicons::bs_icon("folder-plus", size = "1.5em"),
              class = "btn-default",
              style = "font-size: 1.5rem; padding: 0.75rem 1.5rem; width: 100%;"
            ),
            actionButton("downloadRepo",  tagList(
                bsicons::bs_icon("cloud-download", size = "1.5em"),
                tags$span("Download Snakemake workflow from github",
                          style = "font-size: 1.5rem; vertical-align: middle;")
              ), width = "100%"
            )
          )
        )
      ),
    ),
    nav_panel("step4",card( height = cardHeight,
        layout_sidebar(
          sidebar = sidebar(position = "right",
            navButton("showSampleSheet4","Show/edit Sample Sheet"),
            p("Choose the reference, species, and analysis settings before saving the config file.")
          ),
          navSelect("refVersions", "Reference Version", "Single", "Locked",
                    theChoices = refVersionChoices),
          navSelect("speciesSelect","Select the Species & Annotation", "Single", "Locked",
                    theChoices = speciesSelectChoices),
          navNumeric("fdrCutoff","False discover rate", 0.01, tooltipText = "Default: 0.01",min=0,max=1),
          navSelect("pairedSingle","Paired-end or single-end genomics library", "Single", "Locked",
                    theChoices = c("Paired End","Single End")),
          navCheckbox("visBigWig","Run VisBigWig", "True"),
          navCheckbox("rSeqC","Run rSeqC", "True"),
          actionButton("compileConfig",  tagList(
              bsicons::bs_icon("save", size = "1.5em"),
              tags$span("Save Settings", style = "font-size: 1.4rem; vertical-align: middle;")
            )
          ),
          hr()
        )
      ),
    ),
    nav_panel("step5",card( height = cardHeight,
        layout_sidebar(
          sidebar = sidebar(position = "right",
            navButton("showSampleSheet5","Show/edit Sample Sheet"),
            navButton("showComparisonsSheet1","Show/edit Comparisons Sheet"),
            navOutputText("contrastsInfo1"),
            navOutputText("contrastsInfo2"),
            verbatimTextOutput("filepath"),
            # p("We are working to build more options. For now, contact bbc@vai.org for help building more complicated comparisons.")
          ),
          div(
            # --- Contrast definition group ---
            wellPanel(
              tags$h5("Build a contrast", style = "margin-top: 0; font-weight: 600;"),
              tags$p("Comparisons are constructed as 'relative_group' vs 'baseline group'. Genes with expression higher in relative_group than baseline_group have fold change greater than 0. Set wildtype/untreated/control as baseline group",
                     style = "margin-top: -8px; margin-bottom: 10px; color: #777; font-size: 13px;"),

              navSelect("columnsToContrast", "Select the samplesheet column to contrast", "Single", "Locked",
                        theChoices = NULL),
              actionButton("do_all_pairwise", label=NULL, class = "btn-danger"),
              navSelect("relativeGrpContrast", "Select the relative group", "Single", "Locked",
                        theChoices = NULL),
              navSelect("baselineGrpContrast", "Select the baseline group", "Single", "Locked",
                        theChoices = NULL),
              navSelect("covariateColumn", "(Optional) Select a covariate column", "Single", "Locked",
                        theChoices = NULL)
            ),

            # --- Filtering group ---
            wellPanel(
              tags$h5("(Optional) Filter samples for contrast", style = "margin-top: 0; font-weight: 600;"),
              tags$p("If you want to compare only a subset of samples. For example if you want to contrast treated vs. untreated only in WT samples, then select 'genotype' as the column to filter and 'WT' as what the value of genotype should be.",
                     style = "margin-top: -8px; margin-bottom: 10px; color: #777; font-size: 13px;"),
              navSelect("columnsToFilterOn", "Select a column to filter", "Single", "Locked",
                        theChoices = NULL),
              navSelect("filterColumnLevel", "First select a column to filter", "Single", "Locked",
                        theChoices = NULL)
            ),
            actionButton("buildContrasts",
                         tagList(
                           bsicons::bs_icon("cart-plus", size = "1.5em"),
                           tags$span("Add this differential comparison", style = "font-size: 1.4rem; vertical-align: middle;")
                         ),
                         style = "width: 100%; display: block; margin-bottom: 10px;"
            ),
            # DTOutput("contrastsTableOutput"),
            DTOutput("comparisonsSheet"),
            actionButton("delete_btn", "Delete Selected Row(s)", class = "btn-danger"),
            # actionButton("editComparisons", "Optional: directly edit comparisons")
          )
        )
      ),
    ),
    nav_panel('step6',card( height = cardHeight,
        layout_sidebar(
          sidebar = sidebar(position = "right",width = '66.67vw',
            navOutputText("workflowStarted"),
            verbatimTextOutput("job_status"),
            navOutputText("errorFilesEmail"),
            verbatimTextOutput("job_status_refresh0"),
            verbatimTextOutput("openLogSTDOUTMessage0"),
            verbatimTextOutput("openLogSTDOUTContent0"),
            verbatimTextOutput("openLogSTDERRMessage0"),
            verbatimTextOutput("openLogSTDERRContent0")
          ),
          actionButton("runWorkflow",tagList(
              bsicons::bs_icon("bar-chart-line", size = "2em"),
              tags$span("Start Snakemake RNAseq Workflow", style = "font-size: 1.6rem; vertical-align: left;")
            )
          ),
          actionButton("checkStatus","Click here to refresh job status"),
          actionButton("printLogSTDOUT","Display Snakemake log (STDOUT) file"),
          actionButton("printLogSTDERR","Display Snakemake error (STDERR) file"),
          actionButton("openResults","Open the results folder"),
          actionButton("openLogSTDOUT","Open Snakemake log (STDOUT) file"),
          actionButton("openLogSTDERR","Open the Snakemake error (STDERR) file"),
          downloadButton("downLoadFinalReport", "Download Results")
        )
      )
    ),
    nav_panel("stepb1",
      card( height = cardHeight,
        layout_sidebar(
          sidebar = sidebar(position = "right",
            verbatimTextOutput("chosenExistingDirText")
          ),
          div(
            shinyDirButton(
              id    = "selectExistingWorkflow",
              label = "Select an existing workflow",
              title = "Select an existing workflow",
              icon  = bsicons::bs_icon("folder-plus", size = "1.5em"),
              class = "btn-default",
              style = "font-size: 1.5rem; padding: 0.75rem 1.5rem;"
            )
          )
        )
      )
    ),
    nav_panel('stepb2',
      card( height = cardHeight,
        layout_sidebar(
          sidebar = sidebar(position = "right",
            verbatimTextOutput("job_status_refresh"),
            verbatimTextOutput("openLogSTDOUTMessage"),
            verbatimTextOutput("openLogSTDOUTContent"),
            verbatimTextOutput("openLogSTDERRMessage"),
            verbatimTextOutput("openLogSTDERRContent")
          ),
          actionButton("checkStatus2","Click here to refresh job status"),
          actionButton("printLogSTDOUT","Display Snakemake log (STDOUT) file"),
          actionButton("printLogSTDERR","Display Snakemake error (STDERR) file"),
          actionButton("openResults","Open the results folder"),
          actionButton("openLogSTDOUT","Open Snakemake log (STDOUT) file"),
          actionButton("openLogSTDERR","Open the Snakemake error (STDERR) file"),
          downloadButton("downLoadFinalReport", "Download Report") #|> shinyjs::disabled()
        )
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
      fastqFilesFound = FALSE, #
      outputDirCheck = FALSE, #
      sampleSheetCheck = FALSE, #
      gitCheck = F
    ),
    samplesheet_path = NULL,
    units = NULL, # workflow repo
    repoPath = NULL,
    tab_order = NULL, # for dynamic tabs
    current_index = 1, # for dynamic tabs
    yaml_path_job_id = NULL,
    logSTDOUT = 'rnaseq_workflow_app_run.o',
    logSTDERR = 'rnaseq_workflow_app_run.e',
    fastqDir = NULL
  )

  dt_samplesheet <- reactiveVal(NULL)
  dt_comparisons <- reactiveVal(NULL)

  # Render the table
  output$sampleSheet <- renderDT({
    datatable(dt_samplesheet(), editable = "cell")
  })
  # Render the table
  output$comparisonsSheet <- renderDT({
    datatable(dt_comparisons(), editable = "cell",selection = "multiple",rownames = TRUE)
  })

  # Trigger the sample sheet popup
  observeEvent(input$showSampleSheet2, {
    showModal(modalDialog(
      title = "Sample Sheet",
      DTOutput("sampleSheet"),
      easyClose = TRUE,
      size = "xl",
      footer = modalButton("Close")
    ))
  })

  observeEvent(input$showSampleSheet3, {
    showModal(modalDialog(
      title = "Sample Sheet",
      DTOutput("sampleSheet"),
      easyClose = TRUE,
      size = "xl",
      footer = modalButton("Close")
    ))
  })

  observeEvent(input$showSampleSheet4, {
    showModal(modalDialog(
      title = "Sample Sheet",
      DTOutput("sampleSheet"),
      easyClose = TRUE,
      size = "xl",
      footer = modalButton("Close")
    ))
  })

  observeEvent(input$showSampleSheet5, {
    showModal(modalDialog(
      title = "Sample Sheet",
      DTOutput("sampleSheet"),
      easyClose = TRUE,
      size = "xl",
      footer = modalButton("Close")
    ))
  })

   observeEvent(input$showComparisonsSheet1, {
    showModal(modalDialog(
      title = "Comparisons",
      DTOutput("comparisonsSheet"),
      easyClose = TRUE,
      size = "xl",
      footer = modalButton("Close")
    ))
  })

  observe({
    # Deactivate buttons that need other things to function
    if(!testing){
      deactivateItems(
        c(
          "fastqPathSelect",
          "outputPathSelect",
          "compileConfig",
          "buildContrasts",
          "editComparisons",
          "downloadRepo",
          "runWorkflow",
          "checkStatus",
          "printLogSTDOUT",
          "printLogSTDERR",
          "openLogSTDERR",
          "openLogSTDOUT",
          "downLoadFinalReport",
          "openResults",
          'filterColumnLevel',
          #
          "btn_next",
          "btn_prev"
        )
      )
    }
  })

  ## 0.1.2 Modals ----
  # --- Modal ---
  showModal(
    modalDialog(
      title = "Welcome to the VAI BBC RNAseq App",
      "Would you like to launch a workflow or check an existing one?",
      footer = tagList(
        actionButton("btn_new", "Start New", class = "btn-primary"),
        actionButton("btn_existing", "Already Exists")
      ),
      easyClose = FALSE
    )
  )

  observeEvent(input$btn_new, {
    message('Modal new')
    removeModal()
    # rv$path <- "new"
    globals$tab_order <- c("step1", "step2", "step3", "step4", "step5", "step6")
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
    message('Modal existing')
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
    selected_tab <- globals$tab_order[globals$current_index]
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

    # if (selected_tab == 'step5') { # so this is if you clicked NEXT on step4, compileConfig tab
    #   message('shinyjs::click(compileConfig) -- going to next ...')
    #   shinyjs::click("compileConfig")
    # }

    if(!testing){deactivateItems("btn_next")}
    # if(selected_tab == 'step4'){activateItems("btn_next")} # if you are on step4, option to click next and save
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
    message('globals$checks$sampleSheetCheck ',globals$checks$sampleSheetCheck)

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
          title = "File Read Error",
          text  = paste("Could not read",file$name,"\n\n", e$message),
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
    message <- NULL
    # ==  Create the repoPath/config/samplesheet/units.tsv file
    tryCatch({
      message('inputFile=',file$name)
      message('df=',class(df))
      build_units_TSV_output <- build_units_TSV(
        inputFileName = file$name,
        df = df
      )
      globals$checks$sampleSheetCheck <- TRUE
      globals$units <- build_units_TSV_output[['units']] # saves the original, but dt_samplesheet() has any edits & should be used

      message <- build_units_TSV_output[['message']]

      message('samplesheet imported ...')
      output$sampleUploadText <- renderText({ paste('Loaded',file$name,"\n") })
      output$showUnitsTSV_Message <- renderText({ message })
      output$showUnitsTSV_Message2 <- renderText({ 'Click on any cell to directly edit! Changes will be saved.' })

      message('class units ',class(build_units_TSV_output[['units']]))
      message('dim units ',dim(build_units_TSV_output[['units']]))
      dt_samplesheet(as.data.frame(build_units_TSV_output[['units']]))
      message('class dt_samplesheet ',class(dt_samplesheet))
      output$showUnitsTSV <- renderDT({ datatable(dt_samplesheet(), editable = "cell") })

    }, error = function(e) {
      showNotification(e$message, type = "error")
      shinyalert(
        title = "Problem with the samplesheet!",
        text  = paste(e$message,"\n\n","Please contact bbc@vai.org with questions"),
        type  = "error",
        closeOnClickOutside = TRUE
      )
      globals$checks$sampleSheetCheck <- FALSE
    })

    message('globals$checks$sampleSheetCheck ',globals$checks$sampleSheetCheck)

    if(globals$checks$sampleSheetCheck){

      activateItems(c('fastqPathSelect','btn_next'))
      message('activating fastqPathSelect')
    }
  })

  ## 2.0 Select FASTQ Folder ----
    shinyDirChoose(input, "fastqPathSelect", roots = rootDir, session = session, filetypes = character(0),
                   allowDirCreate = FALSE, hidden = FALSE, restrictions = restrictDir)

    observeEvent(input$fastqPathSelect,{
      message('observed input$fastqPathSelect')
      fastqDir <- parseDirPath(rootDir,input$fastqPathSelect)

      req(parseDirPath(rootDir, input$fastqPathSelect) != "") # this stops code being run until a dir is selected

      # Check if selected directory is readable
      # Returns TRUE if readable, FALSE otherwise
      is_readable <- file.access(fastqDir, mode = 4) == 0
      warning("is_readable: ",is_readable)
      if(is_readable == TRUE){
        output$fastqDirText <- renderText({ paste0("FASTQ directory: ",fastqDir) })
      }else{
        shinyalert(
          title = "Selected FASTQ Directory Not Readable",
          text = paste("The selected directory is not readable:\n\n", fastqDir,
                       "\n\nPlease select a different directory with read permissions."),
          type = "error",
          closeOnClickOutside = TRUE
        )
        return()
      }

      # check that FASTQs exist in fastqDir
      check_FASTQs_result <- check_FASTQs(
        units = dt_samplesheet(),
        fastqDir = fastqDir
      )
      # reset dt_samplesheet() with any FASTQ information
      dt_samplesheet(as.data.frame(check_FASTQs_result[['units']]))

      missing_fq1 <- check_FASTQs_result[['missing_fq1']]
      missing_fq2 <- check_FASTQs_result[['missing_fq2']]


      if(check_FASTQs_result[['all_fq1_found']]==FALSE){
        shinyalert(
          title = "fq1 files missing!",
          text  = paste0("Not all read 1 FASTQs from samplesheet fq1 column were found in ",fastqDir,"."),
          type  = "warning"
        )
        globals$checks$fastqFilesFound <- FALSE
        output$fq1Found <- renderText({
            paste(
              paste0(length(missing_fq1)," of ",nrow(dt_samplesheet()),
                   " FASTQs from column fq1 NOT FOUND:\n"),
              paste(missing_fq1,collapse="\n"),
              sep="\n"
            )
        })
      }else{
        output$fq1Found <- renderText({''}) # no message needed
      }
      if(check_FASTQs_result[['all_fq2_found']]==FALSE){
        shinyalert(
          title = "fq2 files missing!",
          text  = paste0("Not all read 2 FASTQs from samplesheet fq2 column  were found in ",fastqDir,"."),
          type  = "warning",
          closeOnClickOutside = TRUE
        )
        globals$checks$fastqFilesFound <- FALSE
        output$fq2Found <- renderText({
          paste(
            paste0(length(missing_fq2)," of ",nrow(dt_samplesheet()),
                   " FASTQs from column fq1 NOT FOUND:\n"),
            paste(missing_fq2,collapse="\n"),
            sep="\n"
          )
        })
      }else{
        output$fq2Found <- renderText({''}) # no message needed
      }
      if(check_FASTQs_result[['all_fq2_found']]==TRUE & check_FASTQs_result[['all_fq1_found']]==TRUE){
        globals$checks$fastqFilesFound <- TRUE
        n <- nrow(dt_samplesheet())
        output$fqFound <- renderText({ paste0("FASTQs for all ",n," samples found.\n") })

        output$showUnitsFastqStep <- renderTable({  dt_samplesheet() })
        shinyalert(
          title = "All samples FASTQ files found!",
          text  = paste0("Go to next"),
          type  = "success",
          closeOnClickOutside = TRUE
        )
        output$unitsTitle <- renderText({''}) # no message needed
      }else{
        # finish up error messages and print table for when not found
        # output$unitsTitle <- renderText({'units.tsv'})
        # render the table only for samples with missing data
        # get index of dt_samplesheet() missing
        output$unitsTitle <- renderText({'To continute, fix FASTQ and sample names discrepancies. Samples with problems are shown in the table! Change the FASTQ file names to match the samplesheet or edit the samplesheet (click "Show Sample Sheet" and directly edit). Then reselect a folder with FASTQ files.'})

        output$showUnitsFastqStep <- renderTable({  check_FASTQs_result[['units_missing']] })
      }

      # Check if 'Check Files and Folders' runnable
      if (globals$checks$fastqFilesFound){
        activateItems(c("outputPathSelect","btn_next"))
        globals$fastqDir <- fastqDir
      }
    })

  ## 3.1 Select Output Folder ----
  shinyDirChoose(input, "outputPathSelect", roots = rootDir, session = session, filetypes = character(0),
                 allowDirCreate = TRUE)
  observeEvent(input$outputPathSelect,{
    message('observeEvent outputPathSelect')
    message('fastqDir ',globals$fastqDir)
    outputDir <- parseDirPath(rootDir,input$outputPathSelect)

    req(parseDirPath(rootDir, input$outputPathSelect) != "") # this stops code being run until a dir is selected

    # Check if selected directory is writable
    # Returns TRUE if writable, FALSE otherwise
    is_writable <- file.access(outputDir, mode = 2) == 0
    # warning("is_writable: ",is_writable)
    if (! is_writable){
      shinyalert(
        title = "Selected Output Directory Not Writable",
        text = paste("The selected directory is not writable:\n\n", outputDir,
                     "\n\nPlease select a different directory with write permissions."),
        type = "error",
        closeOnClickOutside = TRUE
      )
      return()
    }else{
      globals$checks$outputDirCheck <- TRUE
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
        type  = "warning",
        closeOnClickOutside = TRUE
      )
      globals$checks$outputDirCheck <- FALSE # disable if already exists
      return()
    }


    if (globals$checks$fastqFilesFound & globals$checks$outputDirCheck){
      activateItems(c("downloadRepo"))
      output$outputErrorText <- renderText({ paste0('Selected directory: ',outputDir,"\n") })
      output$outputErrorText2 <- renderText({ 'You can now download the workflow!' })
      deactivateItems(c("sampleUpload","fastqPathSelect","outputPathSelect"))
    }
  })

  ## 3.2 download repo, ln -s .fq, write units.tsv ----
  observeEvent(input$downloadRepo, {
    deactivateItems('downloadRepo') # disable double clicking
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
    globals$resultsFolder <- file.path(repoPath,"results/make_final_report/BBC_RNAseq_Report")
    tryCatch({
      message('Downloading BBC rnaseq_workflow ', repo.url, " into ", repoPath)
      result <- system2("git", args = c("clone", repo.url, shQuote(repoPath)), stderr = TRUE)
      exitCode <- attr(result, "status")
      # exitCode=0 # debugging
      if (!is.null(exitCode) && exitCode != 0) {
        stop(paste("git clone failed:", paste(result, collapse = "\n"),
                   "\nDestination path may already exist:", repoPath))
      }

      # modify bin/run_snake.sh
      script <- readLines(file.path(repoPath,"bin/run_snake.sh"))
      script <- gsub("cd \\$SLURM_SUBMIT_DIR", paste("cd", repoPath), script)
      # script <- gsub("cd \\$SLURM_SUBMIT_DIR", 'sleep 10; exit 1;', script)
      writeLines(script, file.path(repoPath,"bin/run_snake_APP.sh"))

      output$gitCloneMessage <- renderText({ paste("Cloned", repoName, "into", repoPath) })
      globals$checks$gitCheck <- TRUE
    }, error = function(e) {
      showNotification(e$message, type = "error")
      shinyalert(
        title = "Problem with downloading the workflow!",
        text  = paste(e$message, "\n\n", "Please contact bbc@vai.org with further questions"),
        type  = "error",
        closeOnClickOutside = TRUE
      )
      globals$checks$gitCheck <- FALSE
    })

    # == Link the fastqDir FASTQs to repoPath/raw_data ==
    source_files <- file.path(fastqDir, list.files(fastqDir, pattern = "\\.fastq\\.gz$|\\.fq\\.gz$"))
    target_dir   <- file.path(repoPath, 'raw_data')

    system2("ln", args = c(
      "-s",
      shQuote(source_files),
      shQuote(target_dir)
    ))
    # system2("ln", args = c(
    #   "-s",
    #   file.path(fastqDir, list.files(fastqDir, pattern = "\\.fastq\\.gz$|\\.fq\\.gz$")),
    #   file.path(shQuote(repoPath),'raw_data')
    # ))
    output$symLinkFastq <- renderText({ paste0("FASTQ files linked from ",fastqDir," into ",repoPath,"/raw_data/") })

    # write units.tsv
    readr::write_delim(dt_samplesheet(),file=file.path(repoPath,'config/samplesheet/units.tsv'),
    delim="\t",quote="none")
    output$wroteUnitsTSV <- renderText({ "units.tsv saved" })


    if (globals$checks$gitCheck){
      shinyalert::shinyalert(
        title = "Success!",
        text  = "Go to next\n\nPlease contact bbc@vai.org for help.",
        type  = "success",
        closeOnClickOutside = TRUE
      )
      activateItems(c("compileConfig",'btn_next'))
      deactivateItems(c("downloadRepo"))
    }else{
      shinyalert::shinyalert(
        title = "Failure!",
        text  = "Redo Step 1 following any warnings/errors.\n\nPlease contact bbc@vai.org for help.",
        type  = "info",
        closeOnClickOutside = TRUE
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
      repoDir            = as.character(globals$repoPath),
      ref_genome_version = as.character(refVersions),
      species_name       = as.character(speciesSelect),
      fdrCutoff          = as.numeric(fdrCutoff), # numeric
      PE_or_SE           = as.character(pairedSingle),
      run_rseqc          = as.logical(rSeqC),
      run_vis_bigwig          = as.logical(visBigWig)
    )
    showNotification(paste0("YAML created in ",outputDir,'/rnaseq_workflow/config/config.yaml'), type = "message")

    shinyalert::shinyalert(
      title = "Saved!",
      text  = paste0("\n\nPlease contact bbc@vai.org for help."),
      type  = "success",
      closeOnClickOutside = TRUE
    )

    activateItems(c("buildContrasts",'btn_next'))

    endSection("End create config files")
  })


  ## 5.1 Select Comparisons ----
  observeEvent(input$buildContrasts, {
    if(testing){repoPath <- '/fake/path/because/testing/1/'}
    # only run if input$columnsToContrast, input$baselineGrpContrast and input$relavtiveGrpContrast have values != ''
    req(input$columnsToContrast, input$baselineGrpContrast, input$relavtiveGrpContrast)

    output$contrastsInfo1 <- renderText({ paste0("Added comparison to ",repoPath,"/config/samplesheet/comparisons.tsv") })
    output$contrastsInfo2 <- renderText({
      paste(
        'columnsToContrast', input$columnsToContrast, '<br>',
        'baselineGrpContrast', input$baselineGrpContrast, '<br>',
        'relavtiveGrpContrast', input$relavtiveGrpContrast, '<br>',
        'covariateColumn', input$covariateColumn, '<br>',
        'columnsToFilterOn', input$columnsToFilterOn, '<br>',
        'filterColumnLevel', input$filterColumnLevel
      )
    })


    comparisons <- build_comparisons_TSV(
      units = dt_samplesheet(),
      comparisons = dt_comparisons(), # add it to this
      columnsToContrast = input$columnsToContrast,
      baselineGrpContrast = input$baselineGrpContrast,
      relavtiveGrpContrast = input$relativeGrpContrast,
      covariateColumn = input$covariateColumn,
      columnsToFilterOn = input$columnsToFilterOn,
      filterColumnLevel = input$filterColumnLevel,
      repoPath = repoPath
    )
    message('class comparions',class(comparisons))
    message('class comparisons[[datatable]]',class(comparisons[['datatable']]))
    dt_comparisons((comparisons[['datatable']]))
    message('added with build_comparisons',class(comparisons[['datatable']]),dim(comparisons[['datatable']]))
    # output$contrastsTableOutput <- renderTable({ dt_comparisons() })
    # output$contrastsTableOutput <- renderDT({ datatable(dt_comparisons(), editable = "cell" ,selection = "multiple") })
    activateItems(c("runWorkflow",'btn_next'))

  })

  observeEvent(input$do_all_pairwise, {
    req(input$columnsToContrast)

    comparisons <- build_all_pairwise_comparisons_TSV(
      units = dt_samplesheet(),
      comparisons = dt_comparisons(), # add it to this
      columnsToContrast = input$columnsToContrast,
      repoPath = repoPath
    )
    message('do_all_pairwise dt_comparisons dim: ', paste(dim(dt_comparisons()), collapse = "x"))
    message('class comparisons[[datatable]]',class(comparisons[['datatable']]))

    dt_comparisons((comparisons[['datatable']]))

    # output$contrastsTableOutput <- renderDT({ datatable(dt_comparisons(), editable = "cell" ,selection = "multiple") })

    deactivateItems("do_all_pairwise")

    activateItems(c("runWorkflow", "btn_next"))

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
          "-o", shQuote(file.path(repoPath, globals$logSTDOUT)),
          "-e", shQuote(file.path(repoPath, globals$logSTDERR)),
          shQuote(script)
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
      output$errorFilesEmail <- renderText({ paste0('An email will be sent to ',email,' when JOBID ',job_id,' is finished.\nSLURM output and error files are ',globals$logSTDOUT,' and ',globals$logSTDERR,' in ',repoPath) })
      deactivateItems("runWorkflow") # don't let user run again if already launched
      activateItems(c("checkStatus","printLogSTDERR","printLogSTDOUT","openLogSTDERR","openLogSTDOUT","downLoadFinalReport","openResults"))
      shinyalert(
        title = "Workflow Launched!",
        text  = paste("\n\n","Please contact bbc@vai.org with questions"),
        type  = "info",
        closeOnClickOutside = TRUE
      )

      # save YAML with job id for later
      write_yaml(file = file.path(repoPath,'app.yaml'),x = list('job_id'=job_id))
      globals$yaml_path_job_id = file.path(repoPath,'app.yaml')

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
  observeEvent(list(input$checkStatus, input$checkStatus2), {
    # Poll status
    message("observeEvent checkStatus ... ")
    message("job_id ",globals$job_id)
    message("repoPath ",globals$repoPath)
       # Run squeue and check if job is still queued/running
    squeue_output <- system2(
      "squeue",
      args = c("-j", globals$job_id, "--noheader"),
      stdout = TRUE,
      stderr = TRUE
    )

    exit_code <- attr(squeue_output, "status")
    cmd_failed <- !is.null(exit_code) && exit_code != 0
    job_finished <- (length(squeue_output) == 0) && !cmd_failed

    job_finished_success <- file.exists(file.path(globals$repoPath,'results/multiqc/multiqc.html'))

    message("squeue exit_code: ", if (is.null(exit_code)) 0 else exit_code)
    # 2. Determine the precise status message
    status_msg <- if (cmd_failed) {
      paste0("Error checking job status. Slurm error code: ", exit_code)

    } else if (job_finished_success) {
      paste0(
        "Job complete. Could not find JOB ID ", globals$job_id,
        ". Workflow finished successfully. ",
        "Check log and error files carefully!"
      )
    } else if (job_finished) {
      paste0(
        "Job complete. Could not find JOB ID ", globals$job_id,
        ". Workflow had errors/did not run to complettion! ",
        "Check log and error files carefully!"
      )
    } else {
      # Clean up the output string (e.g., "PENDING" or "RUNNING")
      job_state <- trimws(squeue_output[1])

      if (job_state == "PENDING") {
        paste0("Job is PENDING (waiting in the queue for resources).")
      } else if (job_state == "RUNNING") {
        paste0("Job is actively RUNNING.")
      } else {
        # Catches states like COMPLETING, SUSPENDED, etc.
        paste0("Job status: ", job_state)
      }
    }

    # 3. Assign to your Shiny outputs
    output$job_status_refresh  <- renderText({ status_msg })
    output$job_status_refresh0 <- renderText({ status_msg })
  },ignoreInit = TRUE)

  ## 6.3 Open Results Folder ----
  observeEvent(input$openResults, {
    baseName <- 'https://ondemand1.vai.zone/pun/sys/dashboard/files/fs/'
    path <- file.path(baseName, globals$repoPath, 'results')
    message('path: ', path)
    # req(path)
    runjs(paste0("window.open('", path, "', '_blank');"))
  })

  ## Open log STDOUT  ----
  observeEvent(input$openLogSTDOUT, {
    baseName <- 'https://ondemand1.vai.zone/pun/sys/dashboard/files/fs/'
    path0 <- file.path(baseName, globals$repoPath, globals$logSTDOUT)
    # req(path0)
    message('path0: ', path0)
    runjs(paste0("window.open('", path0, "', '_blank');"))
  })

  ## Open log STDERR  ----
  observeEvent(input$openLogSTDERR, {
    baseName <- 'https://ondemand1.vai.zone/pun/sys/dashboard/files/fs/'
    path0 <- file.path(baseName, globals$repoPath, globals$logSTDERR)
    # req(path0)
    message('path0: ', path0)
    runjs(paste0("window.open('", path0, "', '_blank');"))
  })

  ## Print log STDOUT  ----
  observeEvent(input$printLogSTDOUT, {
    path1 <- file.path(globals$repoPath, globals$logSTDOUT)
    req(file.exists(path1))
    message('STDOUT path1: ', path1)
    lines <- readLines(path1, warn = FALSE)
    tail_lines <- tail(lines, 15)
    output$openLogSTDOUTMessage <- renderText({ 'Showing last 15 lines of STDOUT log'})
    output$openLogSTDOUTContent <- renderText({ paste(tail_lines, collapse = "\n") })
    output$openLogSTDOUTMessage0 <- renderText({ 'Showing last 15 lines of STDOUT log'})
    output$openLogSTDOUTContent0 <- renderText({ paste(tail_lines, collapse = "\n") })
  })

  ## Print log STDERR  ----
  observeEvent(input$printLogSTDERR, {
    path1 <- file.path(globals$repoPath, globals$logSTDERR)
    req(file.exists(path1))
    message('STDERR path1: ', path1)
    lines <- readLines(path1, warn = FALSE)
    tail_lines <- tail(lines, 15)
    output$openLogSTDERRMessage <- renderText({ 'Showing last 15 lines of STDERR log'})
    output$openLogSTDERRContent <- renderText({ paste(tail_lines, collapse = "\n") })
    output$openLogSTDERRMessage0 <- renderText({ 'Showing last 15 lines of STDERR log'})
    output$openLogSTDERRContent0 <- renderText({ paste(tail_lines, collapse = "\n") })
  })


  ## Select Existing Output Folder ----
  shinyDirChoose(input, "selectExistingWorkflow", roots = rootDir, session = session, filetypes = character(0),
                 allowDirCreate = TRUE)
  observeEvent(input$selectExistingWorkflow,{
    outputDir <- parseDirPath(rootDir,input$selectExistingWorkflow)
    message('outputDir ',outputDir)
    req(parseDirPath(rootDir, input$selectExistingWorkflow) != "") # this stops code being run until a dir is selected

    # do checks if it not a repo named rnaseq_workflow
    if (basename(outputDir) != "rnaseq_workflow") {
      warning(paste(outputDir," is not the rnaseq_workflow repo ... "))
      # check if rnaseq_workflow exists in selected directory
      if("rnaseq_workflow" %in% list.files(outputDir) &&
         "app.yaml" %in% list.files(file.path(outputDir, "rnaseq_workflow"))
      ){
        message(paste("Found an rnaseq_workflow directory in ",outputDir," ... using that ..."))
        globals$repoPath <- file.path(outputDir,'rnaseq_workflow')
        output$chosenExistingDirText <- renderText({ paste('Selected workflow folder:',globals$repoPath,"\n")  })
        globals$job_id <- read_yaml(file.path(globals$repoPath,'app.yaml'))$job_id
        globals$resultsFolder <- file.path(outputDir,"rnaseq_workflow/results/make_final_report/BBC_RNAseq_Report")
        activateItems(c('btn_next'))
      }else{
        # couldn't be found
        shinyalert(
          title = paste0("Could not identify an app-generated rnaseq_workflow folder in ",outputDir,"!"),
          text  = paste("\n\n","Please contact bbc@vai.org with questions"),
          type  = "error"
        )
      }


    }else{
      # checks out because folder matches rnaseq_workflow exactly
      globals$repoPath <- outputDir
      globals$resultsFolder <- file.path(outputDir,"results/make_final_report/BBC_RNAseq_Report")
      output$chosenExistingDirText <- renderText({ paste('Selected workflow folder:',globals$repoPath,"\n")  })
      globals$job_id <- read_yaml(file.path(globals$selectExistingWorkflow,'app.yaml'))$job_id
      activateItems(c('btn_next'))
    }

    message('value of globals$job_id ',globals$job_id)
    message('value of globals$repoPath ',globals$repoPath)
  })


  ## 6.2 Download Final Report ----
  output$downLoadFinalReport <- downloadHandler(
    filename = function() {
      "BBC_RNAseq_Report.zip"
    },
    content = function(file) {
      zip(
        zipfile = file,
        files = globals$resultsFolder,
        flags = "-r"   # recursive
      )
    }
  )
  ## Edit DTtable(s) ----
  # Capture edits and update the data
  # observeEvent(input$showUnitsTSV_cell_edit, {
  #   message('manual input ',input$showUnitsTSV_cell_edit)
  #   info <- input$showUnitsTSV_cell_edit
  #
  #   df <- dt_samplesheet()
  #   message('df is: ', class(df), ' | nrow: ', nrow(df))
  #   req(!is.null(df))   # stop here if still NULL
  #
  #   df[info$row, info$col] <- info$value  # apply the edit directly
  #   dt_samplesheet(df) # write back
  #   # if units.tsv has been written, overwrite with any edits
  #   if (globals$checks$gitCheck) {
  #     message('writing edited units.tsv to disk from showUnitsTSV_cell_edit')
  #     readr::write_delim(dt_samplesheet(),file=file.path(globals$repoPath,'config/samplesheet/units.tsv'))
  #   }
  # })

  # Capture cell edits and update the reactive data
  observeEvent(input$sampleSheet_cell_edit, {
    message('manual input ',input$sampleSheet_cell_edit)
    info <- input$sampleSheet_cell_edit

    df <- dt_samplesheet()
    message('df is: ', class(df), ' | nrow: ', nrow(df))
    req(!is.null(df))   # stop here if still NULL

    df[info$row, info$col] <- info$value  # apply the edit directly
    dt_samplesheet(df) # write back
    # if units.tsv has been written, overwrite with any edits
    if (globals$checks$gitCheck) {
      message('writing edited units.tsv to disk from sampleSheet_cell_edit')
      readr::write_delim(dt_samplesheet(),file=file.path(globals$repoPath,'config/samplesheet/units.tsv'))
    }
  })

  observeEvent(input$comparisonsSheet_cell_edit, {
    message('manual input ',input$comparisonsSheet_cell_edit)
    info <- input$comparisonsSheet_cell_edit

    df <- dt_comparisons()
    message('df is: ', class(df), ' | nrow: ', nrow(df))
    req(!is.null(df))   # stop here if still NULL

    df[info$row, info$col] <- info$value  # apply the edit directly
    dt_comparisons(df) # write back
    # if units.tsv has been written, overwrite with any edits
    if (globals$checks$gitCheck) {
      message('writing edited comparisons.tsv to disk from comparisonsSheet_cell_edit')
      readr::write_delim(dt_comparisons(),file=file.path(globals$repoPath,'config/samplesheet/comparisons.tsv'))
    }
  })

  # this is for reactive values of comparisons selection - update them with samplesheet changes
  observeEvent(dt_samplesheet(), {
    req(dt_samplesheet())
    i <- which(colnames(dt_samplesheet())%in%c('sample','fq1','fq2','RG'))
    updateSelectizeInput(
      session, "columnsToContrast",
      choices  = sort(colnames(dt_samplesheet()[-i])),
      selected = isolate(input$columnsToContrast)
    )
    updateSelectizeInput(
      session, "covariateColumn",
      choices = c("", sort(colnames(dt_samplesheet()[-i]))),
      selected = "",
      options = list(
        allowEmptyOption = TRUE,   # <- lets "" show up as a selectable item
        placeholder = "None"       # optional: nicer label than a blank row
      )
    )
    updateSelectizeInput(
      session, "columnsToFilterOn",
      choices = c("", sort(colnames(dt_samplesheet()[-i]))),
      selected = "",
      options = list(
        allowEmptyOption = TRUE,   # <- lets "" show up as a selectable item
        placeholder = "None"       # optional: nicer label than a blank row
      )
    )
  })

  observeEvent(input$columnsToContrast, {
    req(input$columnsToContrast, dt_samplesheet())

    vals <- sort(unique(na.omit(dt_samplesheet()[[input$columnsToContrast]])))

    updateSelectizeInput(session, "baselineGrpContrast",
                         choices = vals,
                         label    = paste0("Select the baseline '", input$columnsToContrast, "'"),
                         selected = character(0))

    updateSelectizeInput(session, "do_all_pairwise",
                         label    = paste0("Autogenerate pairwise comparisons for '", input$columnsToContrast, "'"),
                         selected = character(0))

    updateSelectizeInput(session, "relativeGrpContrast",
                         choices = vals,
                         label    = paste0("Select the relative '", input$columnsToContrast, "'"),
                         selected = character(0))
    activateItems("do_all_pairwise")

  })

  observeEvent(input$columnsToFilterOn, {
    # req(input$columnsToContrast, dt_samplesheet())

    vals <- sort(unique(na.omit(dt_samplesheet()[[input$columnsToFilterOn]])))
    activateItems('filterColumnLevel')
    updateSelectizeInput(session, "filterColumnLevel",
                         choices = c("Not selected" = "", vals),
                         label    = paste0("I want this contrast to include only samples where '", input$columnsToFilterOn, "' is equal to"),
                         selected = character(0))
  }, ignoreInit = TRUE)

  observeEvent(input$delete_btn, {
    selected_rows <- input$comparisonsSheet_rows_selected
    req(selected_rows)

    current_data <- dt_comparisons()
    dt_comparisons(current_data[-selected_rows, , drop = FALSE])
  })

}


# Functions ----
## build_comparisons
build_comparisons_TSV <- function(
    units = NULL,
    comparisons = NULL,
    columnsToContrast = NULL,
    baselineGrpContrast = NULL,
    relavtiveGrpContrast = NULL,
    covariateColumn = NULL,
    columnsToFilterOn = NULL,
    filterColumnLevel = NULL,
    repoPath = NULL
) {

  # these are the current columns for rnaseq_workflow
  # comparison_name	group_test	group_reference	group_reg_formula	filterColumn	filterColumnLevel
  formula1 <- NULL
  name <- NULL
  is_empty <- function(x) {
    is.null(x) || length(x) == 0 || (length(x) == 1 && is.character(x) && x == "") || (length(x) == 1 && is.na(x))
  }
  if(!is_empty(covariateColumn) & !is_empty(filterColumnLevel)){
    message('comparisons func: yes covariate, yes filter')
    formula1 <- paste0('~',columnsToContrast,'+',covariateColumn)
    name <- paste0(columnsToContrast,'_',relavtiveGrpContrast,'_vs_',baselineGrpContrast,'_covariate_',covariateColumn,'_',columnsToFilterOn,'_',filterColumnLevel)
  }else if(!is_empty(covariateColumn)){
    message('comparisons func: yes covariate, no filter')
    formula1 <- paste0('~',columnsToContrast,'+',covariateColumn)
    name <- paste0(columnsToContrast,'_',relavtiveGrpContrast,'_vs_',baselineGrpContrast,'_covariate_',covariateColumn)
  }else if(!is_empty(filterColumnLevel)){
    message('comparisons func: no covariate, yes filter')
    formula1 <- paste0('~',columnsToContrast)
    name <- paste0(columnsToContrast,'_',relavtiveGrpContrast,'_vs_',baselineGrpContrast,'_',columnsToFilterOn,'_',filterColumnLevel)
  }else{
    message('comparisons func: no covariate, no filter')
    formula1 <- paste0('~',columnsToContrast)
    name <- paste0(columnsToContrast,'_',relavtiveGrpContrast,'_vs_',baselineGrpContrast)
  }

  safe1 <- function(x) if (is.null(x) || length(x) == 0) NA_character_ else x

  message(' lengths: name=', length(name),
          ' group_test=', length(relavtiveGrpContrast),
          ' group_reference=', length(baselineGrpContrast),
          ' formula=', length(formula1),
          ' filterColumn=', length(columnsToFilterOn),
          ' filterColumnLevel=', length(filterColumnLevel))

  tmp <- data.frame(
    comparison_name = safe1(name),
    group_test = safe1(relavtiveGrpContrast),
    group_reference = safe1(baselineGrpContrast),
    group_reg_formula = safe1(formula1),
    filterColumn = safe1(columnsToFilterOn),
    filterColumnLevel = safe1(filterColumnLevel),
    stringsAsFactors = FALSE
  )

  # do checks that filtering won't result in <2 samples per group


  message('comparisons dim',dim(tmp))
  message('comparisons class',class(tmp))
  if (is.null(comparisons)) {
    message('comparisons is.null')
    comparisons <- tmp
  } else {
    message('comparisons ! is.null')
    # sanity check that column names match before rbinding
    if (!identical(names(comparisons), names(tmp))) {
      stop("Column names don't match between comparisons and new comparison: ",
           paste(setdiff(union(names(comparisons), names(tmp)),
                         intersect(names(comparisons), names(tmp))),
                 collapse = ", "))
    }
    if(!tmp$comparison_name %in% comparisons$comparison_name){
      comparisons <- rbind(comparisons, tmp)
    }else{
      comparisons <- comparisons
    }
  }

    # not needed because reactive is populated with function return & written then
  # if(!testing){
  #   readr::write_delim(comparisons,file=file.path(repoPath,'config/samplesheet/comparisons.tsv'),
  #             delim="\t",quote="none")
  # }

  return(
    list(
      'datatable' = comparisons
    )
  )
}


build_all_pairwise_comparisons_TSV <- function(
    units = NULL,
    comparisons = NULL,
    columnsToContrast = NULL,
    repoPath = NULL
) {

  tmp <- lapply(columnsToContrast, function(col) {
    warning(paste("on Column", col))
    group_levels <- unique(units[[col]])
    message('class group_levels',class(group_levels))
    message('str group_levels',str(group_levels))
    message('group_levels',paste(group_levels,sep="|"))
    if(length(group_levels)<2){stop(paste("Less than 2 group levels"))}
    as.data.frame(t(combn(group_levels, 2))) |>
      setNames(c("group_test", "group_reference")) |>
      mutate(
        column   = col,
        comparison_name = paste0(col,'_',group_test, "_vs_", group_reference),
        group_reg_formula = paste0('~',col),
        filterColumn = NA_character_,
        filterColumnLevel = NA_character_,
      ) |>
      select(comparison_name, group_test, group_reference, group_reg_formula,filterColumn,filterColumnLevel)
  }) |>
    bind_rows()

  if (is.null(comparisons)) {
    message('comparisons is.null')
    comparisons <- tmp
  } else {
    message('comparisons ! is.null')
    # sanity check that column names match before rbinding
    if (!identical(names(comparisons), names(tmp))) {
      stop("Column names don't match between comparisons and new comparison: ",
           paste(setdiff(union(names(comparisons), names(tmp)),
                         intersect(names(comparisons), names(tmp))),
                 collapse = ", "))
    }
    comparisons <- rbind(comparisons, tmp)
  }

  return(
    list(
      'datatable' = comparisons
    )
  )
}

# ___________________ ----
# Run App ----
shinyApp(ui = ui, server = server)

