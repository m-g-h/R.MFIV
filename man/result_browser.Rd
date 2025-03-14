% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vIsualisations.R
\name{result_browser}
\alias{result_browser}
\title{Shiny applet to browse through figures of the VIX for different stock tickers
and VIX variables.}
\usage{
result_browser(data, index_var = "t", VIX_vars = c("VIX_wk", "VIX_mn"))
}
\arguments{
\item{data}{A \code{data.table} with at least three columns:
\itemize{
 \item ticker (\code{character}, giving the name of the stock symbol)
 \item t (\code{datetime or numeric}, giving the time of observation for the x-axis.
 It is recommended to use a numeric index if multiple days should be displayed)
 \item \<values\> (\code{numeric}, a column with values to plot, e.g. the VIX)
 \item ... optional other \<value\> columns
}}

\item{index_var}{\code{Character scalar or vector} corresponding to the name of the
index columns in the input \code{data}. Defaults to \code{t}}

\item{VIX_vars}{\code{Character scalar or vector} corresponding to the names of the
value columns in the input \code{data} which should be plotted. Defaults to
\code{c("VIX_wk", "VIX_mn")}}
}
\value{
Starts a \code{shiny} app that displays the VIX variables and allows to
browse through the different tickers
}
\description{
Shiny applet to browse through figures of the VIX for different stock tickers
and VIX variables.
}
