rm(list = ls())


####Read in Libraries####
library(shiny)
library(tidyverse)
library(shinythemes)
library(rsconnect)
library(shinyWidgets)
library(lubridate)
library(scales)
library(shinyjs)
library(shinyalert)
library(shiny.i18n)
library(googleLanguageR)
library(here)


####Initialize Translator for Automatic Translation####
i18n <- Translator$new(translation_json_path = here("json", "translation.json"))

##Set default language
i18n$set_translation_language("en")


####Write Decision Tree####
decision_tree <- 
  list(
    list(
      intro = TRUE, 
      content_above_buttons = 
        tags$div(
          tags$p(strong("Welcome to REFORM Alliance's Florida Early Termination Tool.")),
          tags$p("This tool is designed to help users understand whether they may be eligible for early termination of probation or community control supervision in Florida. It applies only to people on probation or community control, not people on parole. While this tool will help you understand whether you are eligible for early termination, you should speak with your lawyer or probation officer directly about your specific case."), 
          tags$p("This tool can be used by anyone but is specifically designed to be used by people on probation or community control. To begin using the tool, please click on the START button below.")
        ),
      next_question = "initial_question", 
      question_id = "intro_page"
    ),
    list(
      question = 
        tags$div(
          tags$p(strong("First we need to ask you a few basic questions about your supervision to determine what you are eligible for."))
        ),
      question_list = 
        list("q1" = tags$p("Are you supervised by the Florida Department of Corrections (DOC)? If you were sentenced to ",
                           strong("felony"), " probation or community control, you are supervised by the DOC. If you were sentenced to a ", 
                           strong("misdemeanor"), " probation, you are probably not supervised by the DOC. Please ask your supervision officer if you are not sure about the answer to this question."),
             "q2" = tags$p("Are you on probation or community control? If you are under “house arrest,” you are probably under community control. Please ask your supervision officer if you are not sure about the answer to this question.")),
      choices = 
        list(
          "q1" = c("Yes", "No"),
          "q2" = c("Probation", "Community Control")
        ),
      question_id = "initial_question",
      route_key = "q1", 
      next_question = list(
        "Yes" = "education_question", 
        "No" = "sentencing_date_question"
      )
    ),
    list(
      question = 
        tags$div(
          tags$p("While under supervision, did you obtain a high school equivalency degree (GED), an academic degree, or a vocational certificate?")
        ),
      choices = c("Yes", "No"),
      question_id = "education_question", 
      next_question = list(
        "Yes" = "60_day_reduction_message", 
        "No" = "employment_question"
      )
    ),
    list(
      question = 
        tags$div(
          tags$p("Were you sentenced on or after October 1, 2019?")
        ),
      choices = c("Yes", "No"),
      question_id = "sentencing_date_question",
      next_question = list(
        "Yes" = "probation_status_questions", 
        "No" = "violation_of_probation_question"
      )
    ),
    list(
      question = 
        tags$div(
          tags$p("You are legally required to receive a 60-day reduction in your probation or community control sentence! You earn a 60-day reduction for ", 
                 strong("each"), " degree or vocational certificate you achieve, a court is " , 
                 strong("not"), " required to approve this reduction, and it ", 
                 strong("must"), " be granted to you by the DOC as long as you can prove this achievement. Please contact your supervision officer if you have completed this type of educational achievement but have not received the reduction."),
          tags$p("Please be aware that this 60-day credit can be taken away if you violate probation or community control in the future."), 
          tags$p("Please click below to continue using this tool.")
        ),
      question_id = "60_day_reduction_message",
      next_question = "employment_question"
    ),
    list(
      question = 
        tags$div(
          tags$p("While under supervision, did you work continuously for at least 30 hours per week over at least a 6-month period of time and earn a wage for that work?")
        ),
      choices = c("Yes", "No"),
      question_id = "employment_question", 
      next_question = list(
        "Yes" = "30_day_reduction_message", 
        "No" = "sentencing_date_question"
      )
    ),
    list(
      question = 
        tags$div(
          tags$p("You are legally required to receive a 30-day reduction in your probation or community control sentence! You earn a 30-day reduction for every 6 months that you work continuously for at least 30 hours per week and earn a wage for that work. A court is not required to approve this reduction, and it must be granted to you by the DOC as long as you can prove this achievement (see below). However, you should be aware that this 30-day credit can be taken away if you violate probation or community control in the future."),
          tags$p("The DOC is required to verify your employment through paperwork such as a record, letter, pay stub, or contract. Please discuss with your supervision officer exactly what they require to verify your employment."),
          tags$p("Please click below to continue learning more about your oppportunities for early termination.")
        ),
      question_id = "30_day_reduction_message", 
      next_question = list(
        "Probation" = "sentencing_date_question", 
        "Community Control" = "no_early_termination_result"
      )
    ),
    list(
      result = 
        tags$div(
          tags$p("Unfortunately, Florida law does not give you any opportunity for early termination of your community control sentence. Please consult with your attorney or supervision officer to discuss your options. If you would like to learn more about how to get involved with advocating for changes to Florida law, please ", 
                 tags$a(href='https://reformalliance.com/take-action/', target='_blank', class='external-link', "CLICK HERE"), ".")
        ),
      question_id = "no_early_termination_result"
    ),
    list(
      question = 
        tags$div(
          tags$p("Has a court found you in violation of probation at any time?")
        ),
      choices = c("Yes", "No"),
      question_id = "violation_of_probation_question", 
      next_question = list(
        "Yes" = "no_early_termination_result", 
        "No" = "fines_fees_question"
      )
    ),
    list(
      question_list = 
        list(
          "q1" = tags$p("Have you successfully completed the conditions of your probation? If you do not know the answer to this question, please discuss it with your probation officer."), 
          "q2" = tags$p("Has a court found you in violation of probation at any point?"),
          "q3" = tags$p("Did you agree to exclude the possibility of early termination as part of a plea bargain?"), 
          "q4" = tags$p('Are you classified as a “violent felony offender of special concern” under section ', 
                        tags$a(href='https://www.leg.state.fl.us/statutes/index.cfm?App_mode=Display_Statute&Search_String=&URL=0900-0999/0948/Sections/0948.06.html', target='_blank', class='external-link', "948.06(8)(b)"), "?")
        ),
      choices = c("Yes", "No"),
      question_id = "probation_status_questions", 
      route_fn = function(r){
        if(r$q2 == "Yes"){
          "Yes2"
        }else if(r$q1 == "Yes" && r$q3 == "No" && r$q4 == "No"){
          "Yes1"
        }else{
          "No"
        }
      },
      next_question = list(
        "Yes1" = "half_early_termination_result", 
        "Yes2" = "no_early_termination_result", 
        "No" = "fines_fees_question"
      )
    ),
    list(
      question = 
        tags$div(
          tags$p("Have you paid all the money you owe the court, including fines, court costs, and restitution?")
        ),
      choices = c("Yes", "No"),
      question_id = "fines_fees_question", 
      next_question = list(
        "Yes" = "early_termination_result", 
        "No" = "no_early_termination_result"
      )
    ),
    list(
      result = 
        tags$div(
          tags$p("You or your probation officer are permitted to apply for early termination once you finish ", 
                 strong("half"), " of your probation sentence. Please note that any time you spent on community control does not count for this purpose, only time spent on probation."),
          tags$p("The judge is required to grant this application, and either terminate your probation or place you on administrative probation. Administrative probation is ",
                 tags$a(href='https://www.leg.state.fl.us/statutes/index.cfm?App_mode=Display_Statute&Search_String=&URL=0900-0999/0948/Sections/0948.001.html', target='_blank', class='external-link', "defined by law"), 
                 " as no-contact, nonreporting supervision."),
          tags$p("However, if the judge makes a written finding that continuing probation is necessary to protect the community or the interests of justice, then the judge may decline this application. Please talk to your probation officer or your attorney about your options."),
          tags$p("Thank you for using this REFORM Alliance tool, please click ", 
                 tags$a(href='https://reformalliance.com/take-action/', target='_blank', class='external-link', "HERE"), 
                 " to learn about how to get more involved with REFORM Alliance!")
        ),
      question_id = "half_early_termination_result"
    ),
    list(
      result = 
        tags$div(
          tags$p("At any time while on probation, your probation officer may recommend you for early termination if they believe that you have “performed satisfactorily.” Please discuss this option with your probation officer. If they recommend you, the case then goes to the judge to make a final determination. The judge has the discretion to grant early termination, deny it, or place you on administrative probation. Administrative probation is ",
                 tags$a(href='https://www.leg.state.fl.us/statutes/index.cfm?App_mode=Display_Statute&Search_String=&URL=0900-0999/0948/Sections/0948.001.html', target='_blank', class='external-link', "defined by law"), 
                 " as no-contact, nonreporting supervision."),
          tags$p("Please discuss your case with your attorney or probation officer if you have any questions about this process."),
          tags$p("Thank you for using this REFORM Alliance tool, please click ", 
                 tags$a(href='https://reformalliance.com/take-action/', target='_blank', class='external-link', "HERE"), 
                 " to learn about how to get more involved with REFORM Alliance!")
        ),
      question_id = "early_termination_result"
    )
  )


####Create App####
ui <- fluidPage(
  usei18n(i18n),
  # title = uiOutput("app_title"),
  title = "Florida Early Termination Tool",
  useShinyjs(),
  theme = shinytheme("flatly"),
  tags$head(
    tags$style(HTML(
      "
      .question-text{ font-size: 20px; margin-bottom: 30px; margin-top: 30px}
      .result-text{ font-size: 20px; font-weight: bold; color: #28a745; margin-top: 20px; }
      .shiny-input-container{ margin-bottom: 10px; }
      .btn-container{ margin-top: 20px; }
      .logo-container{ text-align: center; margin-bottom: 40px; margin-top: 10px;}
      .logo{ max-width: 200px; height: auto; }
      
      .language-picker-container {
        min-height: 90px;
        display: flex;
        flex-direction: column;
        justify-content: flex-start;
      }
      .language-picker-container .bootstrap-select .dropdown-toggle {
        white-space: nowrap;
        min-height: 34px;
      }
      /* Custom button styling */
      #violation-buttons .btn{
        margin-right: 10px;
        margin-bottom: 10px; /* Add bottom margin for spacing */
        border: 1px solid #ccc;
        padding: 10px 15px;
        font-size: 16px;
        min-width: 200px; /* Adjust as needed */
        text-align: center;
      }
      #violation-buttons .btn.active{
        border-color: #007bff;
        box-shadow: 0 0 5px rgba(0, 123, 255, 0.5);
      }
      #violation-buttons .btn-danger{
        background-color: #dc3545;
        color: white;
      }
      #violation-buttons .btn-success{
        background-color: #28a745;
        color: white;
        min-width: 250px;
        height: 60px;
        padding: 0 20px;     /* Horizontal padding only */
        font-size: 18px;
        line-height: 60px;
        text-align: center;
      }

      #start_button{
        font-size: 24px; /* Increase font size */
        padding: 15px 30px; /* Increase padding */
        min-width: 280px; /* Adjust width as needed */
        height: 70px;    /* Adjust height as needed */
        display: flex;        /* Enable flexbox */
        justify-content: center; /* Center horizontally */
        align-items: center;    /* Center vertically */
      }
      "
    )),
    
    tags$script(HTML("
    $(document).on('click', 'a.external-link', function(e){
      e.preventDefault();
      var $this = $(this);
      var href = $this.attr('href');
      $this.data('href-backup', href); // Backup the href
      Shiny.setInputValue('js_href', href);
    });
    Shiny.addCustomMessageHandler('open_url', function(message){
      window.open(message, '_blank');
      // No need to restore here, navigation happens
    });
    Shiny.addCustomMessageHandler('remove_href', function(href){
      $('a.external-link[data-href-backup=\"' + href + '\"]').each(function(){
        $(this).removeAttr('href'); // Temporarily remove href
      });
    });
    Shiny.addCustomMessageHandler('restore_href', function(href){
      $('a.external-link[data-href-backup=\"' + href + '\"]').each(function(){
        $(this).attr('href', $(this).data('href-backup'));
        $(this).removeData('href-backup');
      });
    });
    ")),
    
    tags$script(HTML("
    Shiny.addCustomMessageHandler('update-title', function(message){
      document.title = message;
    });
    "))
  ),
  
  div(class = "logo-container",
      img(src = "reform-logo-charcoal.png", class = "logo")
  ),
  
  div(strong(uiOutput("main_app_title")),
      style = "font-size: 40px; margin-top: 60px; margin-bottom: 40px; text-align: center;"
  ),
  
  div(
    class = "language-picker-container",
    pickerInput(
      inputId = "selected_language",
      label = "Change Language",
      choices = c("en", "es"),
      selected = i18n$get_translation_language(),
      choicesOpt = list(
        content = c(
          paste0("<i class='flag-icon flag-icon-us'></i> ", i18n$t("English")),
          paste0("<i class='flag-icon flag-icon-es'></i> ", i18n$t("Español"))
        )
      ),
      options = list(
        style = "btn-primary", 
        `live-search` = FALSE, 
        `selected-text-format` = "count > 2", 
        width = "180px"
      )
    )
  ),
  
  uiOutput("quiz_ui"),
  div(class = "btn-container",
      uiOutput("button_ui")
  )
)


####Server####
server <- function(input, output, session){
  i18n_r <- reactive({
    selected <- input$selected_language
    if(length(selected) > 0 && selected %in% i18n$get_languages()){
      i18n$set_translation_language(selected)
    }
    i18n
  })
  
  get_english_key <- function(translated_answer_from_input, current_lang_code){
    if(is.null(translated_answer_from_input) ||
       length(translated_answer_from_input) == 0 ||
       nchar(translated_answer_from_input) == 0){
      return(NULL)
    }
    
    if(current_lang_code == "en"){
      return(translated_answer_from_input)
    }else if(current_lang_code == "es"){
      translation <- 
        as.data.frame(i18n_r()$get_translations()) %>% 
        rownames_to_column("en") %>% 
        filter(es == translated_answer_from_input) %>% 
        pull(en)
      if(length(translation) == 0) return(NULL)
      return(translation[1])
    }
  }
  
  output$app_title <- renderText({
    i18n_r()$t("Florida Early Termination Tool")
  })
  
  output$main_app_title <- renderText({
    i18n_r()$t("Florida Early Termination Tool")
  })
  
  history <- reactiveVal(c(1))
  selected_answer <- reactiveVal(NULL)
  answer_selected <- reactiveVal(FALSE)
  stored_answers <- reactiveValues()
  
  observeEvent(input$js_href, {
    href <- input$js_href
    
    shinyalert(
      title = i18n_r()$t("Leaving Application"),
      text = i18n_r()$t("This will take you to a new website."),
      type = "info",
      showCancelButton = TRUE,
      confirmButtonText = i18n_r()$t("Continue"),
      callbackR = function(x){
        if(isTRUE(x)){
          session$sendCustomMessage("open_url", href)
          session$sendCustomMessage("remove_href", href)
        }else{
          session$sendCustomMessage("restore_href", href)
        }
      }
    )
  }, ignoreInit = TRUE)
  
  translate_ui_recursive <- function(element, translator_reactive){
    
    if(is.character(element)){
      return(translator_reactive()$t(element))
    }
    
    if(inherits(element, "shiny.tag") || inherits(element, "htmltools.tag")){
      
      if(!is.null(element$children)){
        element$children <- lapply(
          element$children,
          function(child){
            translate_ui_recursive(child, translator_reactive)
          }
        )
      }
      
      return(element)
    }
    
    if(is.list(element)){
      return(
        lapply(
          element,
          function(child){
            translate_ui_recursive(child, translator_reactive)
          }
        )
      )
    }
    
    return(element)
  }
  
  ##Quiz UI
  output$quiz_ui <- renderUI({
    current_index <- tail(history(), 1)
    current_question <- decision_tree[[current_index]]
    
    if(length(current_question$intro) > 0){
      tagList(
        translate_ui_recursive(current_question$content_above_buttons, i18n_r),
        uiOutput("intro_buttons"),
        translate_ui_recursive(current_question$content_below_buttons, i18n_r)
      )
    }else if("question" %in% names(current_question) &&
             length(current_question$question_list) == 0){
      tagList(
        translate_ui_recursive(current_question$question, i18n_r),
        if("choices" %in% names(current_question) &&
           length(current_question$choices) > 0){
          stored <- isolate(stored_answers[[current_question$question_id]])
          radioButtons("answer", NULL,
                       selected = if(!is.null(stored)) i18n_r()$t(stored) else character(0),
                       choices = lapply(current_question$choices, function(x) i18n_r()$t(x)))
        }
      )
    }else if(("question" %in% names(current_question) | "question_list" %in% names(current_question)) &&
             length(current_question$question_list) > 0){
      if(is.list(current_question$choices) == FALSE){
        tagList(
          translate_ui_recursive(current_question$question, i18n_r),
          current_question %>%
            pluck("question_list") %>%
            enframe() %>%
            pmap(
              ~tagList(
                div(tags$div(tags$p(translate_ui_recursive(.y, i18n_r)))), 
                radioButtons(
                  inputId = paste0("answer_", .x),
                  selected = {
                    stored <- isolate(stored_answers[[paste0(current_question$question_id, "___answer_", .x)]])
                    if(!is.null(stored)) i18n_r()$t(stored) else character(0)
                  },
                  label = NULL,
                  choices = lapply(c("Yes", "No"), function(x) i18n_r()$t(x)) 
                )
              )
            ),
          if(!is.null(current_question$note_text)){
            translate_ui_recursive(current_question$note_text, i18n_r)
          }
        )
      }else if(is.list(current_question$choices) == TRUE){
        question_items <- enframe(
          current_question$question_list,
          name = "key",
          value = "text"
        )
        
        tagList(
          translate_ui_recursive(current_question$question, i18n_r),
          
          pmap(question_items, function(key, text) {
            question_choices <- current_question$choices[[key]]
            # Retrieve previously stored answer
            stored_key <- paste0(
              current_question$question_id,
              "___answer_",
              key
            )
            
            stored <- isolate(stored_answers[[stored_key]])
            translated_choices <- unname(
              vapply(
                question_choices,
                function(x) i18n_r()$t(x),
                character(1)
              )
            )
            selected_choice <- if (!is.null(stored)) {
              i18n_r()$t(stored)
            } else {
              character(0)
            }
            tagList(
              div(
                tags$div(
                  tags$p(translate_ui_recursive(text, i18n_r))
                )
              ),
              radioButtons(
                inputId = paste0("answer_", key),
                selected = selected_choice,
                label = NULL,
                choices = translated_choices
              )
            )
          }),
          
          if (!is.null(current_question$note_text)) {
            translate_ui_recursive(current_question$note_text, i18n_r)
          }
        )
      }
    }else if("result" %in% names(current_question)){
      translate_ui_recursive(current_question$result, i18n_r)
    }
  })
  
  output$intro_buttons <- renderUI({
    div(
      actionButton("start_button", i18n_r()$t("Start"), class = "btn btn-success")
    )
  })
  
  output$button_ui <- renderUI({
    current_index <- tail(history(), 1)
    current_question <- decision_tree[[current_index]]
    buttons <- list()
    
    if(current_question$question_id == "resource_question"){
      buttons <- list(actionButton("back_button", i18n_r()$t("Go Back to Previous Question"), class = "btn btn-warning"))
    }else{
      if(length(history()) > 1 & current_question$question_id != "intro_page"){
        buttons <- append(buttons, list(actionButton("back_button", i18n_r()$t("Back"), class = "btn btn-warning")))
      }
      
      if(current_question$question_id == "finished_page"){
        buttons <- append(buttons, list(actionButton("start_over_button", i18n_r()$t("Start Over"), class = "btn btn-success")))
      }else if(is.null(current_question$next_question)){
        # buttons <- append(buttons, list(actionButton("finish_button", i18n_r()$t("Finish"), class = "btn btn-danger")))
        buttons <- append(buttons, list(actionButton("start_over_button", i18n_r()$t("Start Over"), class = "btn btn-success")))
      }else if(length(current_question$intro) == 0){
        buttons <- append(buttons, list(actionButton("next_button", i18n_r()$t("Next"), class = "btn btn-primary")))
      }
    }
    
    do.call(fluidRow, buttons)
  })
  
  observeEvent(input$answer, {
    current_index <- tail(history(), 1)
    current_question <- decision_tree[[current_index]]
    
    # list-style questions are handled by the observe() in FIX 4
    req(length(current_question$question_list) == 0,
        "choices" %in% names(current_question))
    
    english_key <- get_english_key(input$answer, input$selected_language)
    
    # only accept answers that are actually a route out of this question
    if(!is.null(english_key) && english_key %in% names(current_question$next_question)){
      answer_selected(TRUE)
      selected_answer(english_key)
      stored_answers[[current_question$question_id]] <- english_key
    }else{
      answer_selected(FALSE)
      selected_answer(NULL)
    }
  })
  
  observe({
    answer_selected_val = answer_selected()
    if(!is.null(answer_selected_val) & answer_selected_val == TRUE){
      shinyjs::enable("next_button")
    }else{
      shinyjs::disable("next_button")
    }
  })
  
  # observe({
  #   current_index <- tail(history(), 1)
  #   current_question <- decision_tree[[current_index]]
  #   
  #   req(length(current_question$question_list) > 0)
  #   
  #   current_lang_code <- input$selected_language
  #   answer_ids <- paste0("answer_", names(current_question$question_list))
  #   
  #   # "Yes"/"No" in English, or NULL if unanswered / not a recognised answer
  #   get_yes_no <- function(id){
  #     val <- get_english_key(input[[id]], current_lang_code)
  #     if(length(val) == 1 && val %in% c("Yes", "No")) val else NULL
  #   }
  #   
  #   responses <- lapply(answer_ids, get_yes_no)
  #   names(responses) <- answer_ids
  #   
  #   # remember what has been answered so far (restored if the person goes Back)
  #   for(id in answer_ids){
  #     if(!is.null(responses[[id]])){
  #       stored_answers[[paste0(current_question$question_id, "___", id)]] <- responses[[id]]
  #     }
  #   }
  #   
  #   if(any(vapply(responses, is.null, logical(1)))){
  #     # not every sub-question answered yet
  #     answer_selected(FALSE)
  #     selected_answer(NULL)
  #   }else{
  #     responses <- unlist(responses)
  #     answer_selected(TRUE)
  #     
  #     selected_answer(if("Yes" %in% responses) "Yes" else "No")
  #   }
  # })
  
  observe({
    current_index <- tail(history(), 1)
    current_question <- decision_tree[[current_index]]
    
    req(length(current_question$question_list) > 0)
    
    current_lang_code <- input$selected_language
    keys <- names(current_question$question_list)
    
    # English answer for one sub-question, or NULL if unanswered / not a valid choice for it
    get_answer <- function(key){
      val <- get_english_key(input[[paste0("answer_", key)]], current_lang_code)
      valid <- if(is.list(current_question$choices)) current_question$choices[[key]] else current_question$choices
      if(length(val) == 1 && val %in% valid) val else NULL
    }
    
    responses <- setNames(lapply(keys, get_answer), keys)
    
    # remember answers so far (restored if the person goes Back)
    for(key in keys){
      if(!is.null(responses[[key]])){
        stored_answers[[paste0(current_question$question_id, "___answer_", key)]] <- responses[[key]]
      }
    }
    
    if(any(vapply(responses, is.null, logical(1)))){
      answer_selected(FALSE)
      selected_answer(NULL)
    # }else{
    #   answer_selected(TRUE)
    #   route_key <- current_question[["route_key"]]
    #   selected_answer(
    #     if(!is.null(route_key)) responses[[route_key]]
    #     else if("Yes" %in% unlist(responses)) "Yes" else "No"
    #   )
    # }
    }else{
      answer_selected(TRUE)
      route_key <- current_question[["route_key"]]
      route_fn <- current_question[["route_fn"]]
      
      selected_answer(
        if(!is.null(route_fn)) route_fn(responses)
        else if(!is.null(route_key)) responses[[route_key]]
        else if("Yes" %in% unlist(responses)) "Yes" else "No"
      )
    }
  })
  
  observeEvent(input$go_to_resource, {
    resource_index <- which(map_chr(decision_tree, "question_id") == "resource_question")
    history(c(history(), resource_index))
  })
  
  observeEvent(input$start_button, {
    current_question <- decision_tree[[1]]
    next_id <- current_question$next_question
    next_index <- which(map_chr(decision_tree, "question_id") == next_id)
    history(c(history(), next_index))
  })
  
  # observeEvent(input$next_button, {
  #   current_index <- tail(history(), 1)
  #   current_question <- decision_tree[[current_index]]
  #   answer_selected_val <- answer_selected()
  #   if(answer_selected_val == FALSE && !("result" %in% names(current_question)) && !(length(current_question$next_question) == 1 && !("choices" %in% names(current_question)))){
  #     shinyalert(
  #       title = i18n_r()$t("Missing answer"),
  #       text = i18n_r()$t("Please select an answer before clicking Next"),
  #       type = "warning"
  #     )
  #     return()
  #   }
  #   
  #   if("choices" %in% names(current_question)){
  #     req(selected_answer())
  #     next_id <- current_question$next_question[[selected_answer()]]
  #   }else{
  #     next_id <- current_question$next_question
  #   }
  #   
  #   req(next_id)
  #   
  #   next_index <- which(map_chr(decision_tree, "question_id") == next_id)
  #   history(c(history(), next_index))
  #   answer_selected(FALSE) 
  #   selected_answer(NULL) 
  # })
  
  observeEvent(input$next_button, {
    current_index <- tail(history(), 1)
    current_question <- decision_tree[[current_index]]
    
    has_choices <- "choices" %in% names(current_question)
    
    # only screens with choices require an answer
    if(has_choices && !isTRUE(answer_selected())){
      shinyalert(
        title = i18n_r()$t("Missing answer"),
        text = i18n_r()$t("Please select an answer before clicking Next"),
        type = "warning"
      )
      return()
    }
    
    if(has_choices){
      req(selected_answer())
      next_id <- current_question$next_question[[selected_answer()]]
    }else{
      next_id <- current_question$next_question
      
      # message screens that branch on probation vs. community control (q2 on the first screen)
      if(is.list(next_id)){
        supervision_type <- stored_answers[["initial_question___answer_q2"]]
        req(supervision_type)
        next_id <- next_id[[supervision_type]]
      }
    }
    
    req(next_id)
    
    next_index <- which(map_chr(decision_tree, "question_id") == next_id)
    history(c(history(), next_index))
    answer_selected(FALSE) 
    selected_answer(NULL) 
  })
  
  observeEvent(input$back_button, {
    answer_selected(FALSE)
    selected_answer(NULL)
    if(length(history()) > 1){
      history(history()[1:(length(history()) - 1)])
      answer_selected(FALSE)
      selected_answer(NULL)
    }
  })
  
  observeEvent(input$start_over_button, {
    history(c(1))
    answer_selected(FALSE)
    selected_answer(NULL)
    for(nm in names(reactiveValuesToList(stored_answers))){
      stored_answers[[nm]] <- NULL
    }
  })
  
  # observeEvent(input$finish_button, {
  #   finished_page_index <- which(map_chr(decision_tree, "question_id") == "finished_page")
  #   history(c(history(), finished_page_index))
  # })
  
  observeEvent(input$selected_language, {
    current_i18n <- i18n_r()
    
    updatePickerInput(
      session,
      inputId = "selected_language",
      label = current_i18n$t("Change Language"),
      choices = c("en", "es"),
      selected = input$selected_language,
      choicesOpt = list(
        content = c(
          paste0("<i class='flag-icon flag-icon-us'></i> ", current_i18n$t("English")),
          paste0("<i class='flag-icon flag-icon-es'></i> ", current_i18n$t("Español"))
        )
      )
    )
  }, ignoreInit = FALSE)
}

##Deploy App
shinyApp(ui = ui, server = server)






