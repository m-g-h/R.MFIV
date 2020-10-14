

#' Scrape the CMT data form the US Treasury website
#'
#' @description According to the \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{2019 VIX whitepaper},
#' \emph{"the risk-free interest rates, R1 and R2, are yields based on U.S. Treasury yield curve
#' rates (commonly referred to as "Constant Maturity Treasury" rates or CMTs), to which a
#' cubic spline is applied to derive yields on the expiration dates of relevant SPX options.
#' As such, the VIX Index calculation may use different risk-free interest rates for near- and
#' next-term options. Note in this example, T2 uses a value of 900 for Settlement day, which
#' reflects the 4:00 p.m. ET expiration time of the next-term SPX Weeklys options."}
#'
#' This data can be retrieved from the \href{https://www.treasury.gov/resource-center/data-chart-center/interest-rates/pages/TextView.aspx?data=yieldAll}{US Treasury website}
#' (link works as of 2020-10-14)
#'
#' @param url \code{character scalar} an URL to the US Treasury website. Defaults to the
#' \href{https://www.treasury.gov/resource-center/data-chart-center/interest-rates/pages/TextView.aspx?data=yieldAll}{complete dataset}.
#' Also accepts links from this website with other selections than "All", see e.g. the example.
#'
#' @return Returns a \code{data.table} containing the scraped CMT data:
#' \itemize{
#'   \item \strong{Date} (\code{date}, giving the day of the observation)
#'   \item \strong{maturity A} (\code{numeric}, giving the CMT rate for the respective maturity)
#'   \item \strong{maturity B} ...
#'   \item ...
#' }
#' @export
#'
#' @examples
#'
#' ## Scrape the CMT data for the current month:
#' scrape_cmt_data("https://bit.ly/33XxtDC")
#'
scrape_cmt_data <- function(url = NULL) {
  ## SCRAPE FULL DATASET IF NO URL IS PROVIDED
  if(is.null(url)){
    url <- "https://www.treasury.gov/resource-center/data-chart-center/interest-rates/pages/TextView.aspx?data=yieldAll"
  }
  message(crayon::blue(lubridate::now()),
          crayon::cyan(" DOWNLOADING AND PREPARING CMT DATA FROM "),
          crayon::silver(url))

  ## DOWNLOAD AND FORMAT RAW DATA
  table <- data.table::as.data.table(
    x = rvest::html_table(
      x = rvest::html_nodes(
        x = xml2::read_html(url),
        css = "table.t-chart")
    )
  )

  ## FUNCTION FOR CONVERSION TO NUMERIC WITHOUT WARNINGS
  numfun <- function(a){
    suppressWarnings(as.numeric(a))
  }

  ## CONVERSION TO NUMERIC AND OUTPUT
  cbind(table[,.(Date)], table[, lapply(X = .SD ,FUN = numfun),
        .SDcols =  names(table)[2:13]])
}

