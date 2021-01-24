#' Create a time-series plot of VIX data
#'
#' @param data A \code{data.table} with at least three columns:
#' \itemize{
#'  \item ticker (\code{character}, giving the name of the stock symbol)
#'  \item t (\code{datetime or numeric}, giving the time of observation for the x-axis.
#'  It is recommended to use a numeric index if multiple days should be displayed)
#'  \item \<values\> (\code{numeric}, a column with values to plot, e.g. the VIX)
#'  \item ... optional other \<value\> columns
#' }
#' @param index_var \code{Character scalar or vector} corresponding to the name of the
#' index columns in the input \code{data}. Defaults to \code{t}
#' @param VIX_vars \code{Character scalar or vector} corresponding to the names of the
#' value columns in the input \code{data} which should be plotted. Defaults to
#' \code{c("VIX_wk", "VIX_mn")}
#'
#' @return Returns a \code{ggplot}
#' @export
#'
#'
plot_VIX <- function(data, index_var = "t", VIX_vars = c("VIX_wk", "VIX_mn")){

  cols <- which(names(data) %in% c("ticker", index_var , VIX_vars))

  ggplot2::ggplot(data = data.table::melt(data[,..cols],
                                          id.vars = c("ticker", "t"),
                                          measury.vars = VIX_vars,
                                          variable.name = "Variable",
                                          value.name = "value"
  ),
  mapping = ggplot2::aes(x = t, y = value, color = Variable)) +
    ggplot2::geom_line() +
    ggplot2::labs(title = "VIX Time-Series Plots") +
    ggplot2::facet_wrap(~ticker,
                        ncol = 1)
}
#' Shiny applet to browse through figures of the VIX for different stock tickers
#' and VIX variables.
#'
#' @inheritParams plot_VIX
#'
#' @return Starts a \code{shiny} app that displays the VIX variables and allows to
#' browse through the different tickers
#'
#' @export
result_browser <- function(data, index_var = "t", VIX_vars = c("VIX_wk", "VIX_mn")){

  ## DEFINE SHINY UI AS FUNCTION
  ui <- function(){
    shiny::fluidPage(
      shiny::fluidRow(
        shiny::textOutput(outputId = "DEBUG"),
        shiny::column(width = 2,
                      shiny::uiOutput("ticker_selector"),
                      shiny::uiOutput("var_selector")
        ),
        shiny::column(10,
                      #shiny::plotOutput(outputId = "plot")
                      plotly::plotlyOutput(outputId = "plot")
        )
      )
    )
  }

  ## DEFINE SHINY SERVER AS FUNCTION
  server <- function(input, output, session){

    ## DROPDOWN TICKER SELECTOR
    output$ticker_selector <- shiny::renderUI({
      shiny::selectizeInput(inputId = "ticker_selector",
                            label = "Ticker",
                            multiple = T,
                            choices = unique(data[,ticker]),
                            selected = unique(data[,ticker])[1])
    })

    ## CHECKBOX VARIABLE SELECTOR
    output$var_selector <- shiny::renderUI({

          shiny::checkboxGroupInput(inputId = "var_selector",
                                label = "Variables",
                                selected = VIX_vars[1],
                                choices = VIX_vars)
    })

    output$plot <- plotly::renderPlotly({
      shiny::req(input$var_selector)
      shiny::req(input$ticker_selector)
      plot_VIX(data = data[ticker %in% input$ticker_selector,],
               VIX_vars = input$var_selector)
    })

    output$DEBUG <- shiny::renderText({
      as.character(input$ticker_selector)
    })
  }

  ## RUN SHINY APP
  shiny::shinyApp(ui, server)
}
