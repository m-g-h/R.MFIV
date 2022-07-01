#' Scrape the CMT data form the US Treasury website
#'
#' @description According to the \href{https://cdn.cboe.com/resources/vix/vixwhite.pdf}{2019 VIX whitepaper},
#' \emph{"the risk-free interest rates, R1 and R2, are yields based on U.S. Treasury yield curve
#' rates (commonly referred to as "Constant Maturity Treasury", rates or CMTs), to which a
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
#' @return Returns a \code{data.table} containing the following columns:
#' \itemize{
#'   \item{Date (\code{date})}{ - the day of the observation}
#'   \item{maturity A (\code{numeric}, \emph{decimal})}{ - the CMT rate for the respective maturity in decimal}
#'   \item{...}
#' }
#' @export
#'
#' @examples
#'
#' ## Scrape the CMT data for the current month:
#' scrape_cmt_data()
#'
scrape_cmt_data <- function(url = NULL) {
  # SCRAPE FULL DATASET IF NO URL IS PROVIDED
  if(is.null(url)){
    url <- "https://home.treasury.gov/resource-center/data-chart-center/interest-rates/daily-treasury-rates.csv/2019/all?type=daily_treasury_yield_curve&field_tdr_date_value=2019&page&_format=csv"
  }
  # message(crayon::blue(lubridate::now()),
  #         crayon::cyan(", DOWNLOADING AND PREPARING CMT DATA FROM "),
  #         crayon::silver(url))
  #
  # ## DOWNLOAD AND FORMAT RAW DATA
  # table <- data.table::as.data.table(
  #   x = rvest::html_table(
  #     x = rvest::html_nodes(
  #       x = xml2::read_html(url),
  #       css = "table")
  #   )
  # )

  table = data.table::fread(url)

  ## FUNCTION FOR CONVERSION TO NUMERIC WITHOUT WARNINGS
  numfun <- function(a){
    suppressWarnings(as.numeric(a) / 100)
  }

  ## CONVERSION TO NUMERIC AND OUTPUT
  table = cbind(table[,.(Date = lubridate::mdy(Date))], table[, lapply(X = .SD ,FUN = numfun),
                                                      .SDcols =  names(table)[2:13]])

  names(table) = c("Date",  "X1.mo", "X2.mo", "X3.mo", "X6.mo", "X1.yr", "X2.yr", "X3.yr", "X5.yr", "X7.yr", "X10.yr","X20.yr","X30.yr")

  data.table::setorder(table, Date)

}

#' Calculate risk-free-rates through cubic-spline interpolation using constant maturity
#' treasury (CMT) rates data.
#'
#' @description According to the \href{https://cdn.cboe.com/resources/vix/vixwhite.pdf}{2019 VIX whitepaper},
#' \emph{"the risk-free interest rates, R1 and R2, are yields based on U.S. Treasury yield curve
#' rates (commonly referred to as "Constant Maturity Treasury", rates or CMTs), to which a
#' cubic spline is applied to derive yields on the expiration dates of relevant SPX options.
#' As such, the VIX Index calculation may use different risk-free interest rates for near- and
#' next-term options. Note in this example, T2 uses a value of 900 for Settlement day, which
#' reflects the 4:00 p.m. ET expiration time of the next-term SPX Weeklys options."}
#'
#'
#' @param cmt_data A \code{data.table} containing CMT quotes. See \code{\link{cmt_dataset}} for an example
#' and \code{\link{scrape_cmt_data}} for a way to obtain it.
#' @param date A \code{date vector} of starting dates.
#' @param exp A \code{date vector} of expiration dates.
#' @param ret_table \code{Logical scalar}, indicating whether to return only the risk free rate(s) or a
#' table with the original \code{date}, \code{exp} and the corresponding risk-free-rates
#'
#' @return Returns either a \code{numeric vector} of risk free rates or a \code{data.table} containing:
#' \itemize{
#'   \item{\strong{date}(\code{date})}{ - the provided starting dates}
#'   \item{\strong{exp} (\code{date})}{ - the provided expiration dates}
#'   \item{\strong{R}   (\code{numeric})}{ - the corresponding risk-free interest rates in \emph{decimal}}
#'}
#' @export
#'
#' @examples
#'
#' ## Using internal package data
#' library(lubridate)
#'
#' ## Single values
#' interpolate_rfr(date = ymd("2020-01-02"), exp = date("2020-03-02"))
#'
#'
#' ## Multiple values
#' dates <- ymd("2020-01-06") + days(1:4)
#' exps <-  ymd("2020-03-02") + days(1:4)
#'
#' interpolate_rfr(date = dates, exp = exps)
#'
#' ## With output table
#' interpolate_rfr(date = dates, exp = exps, ret_table = TRUE)
#'
interpolate_rfr <- function(cmt_data = NULL, date, exp,
                            ret_table = F){
  ## USE PPACKAGE DATA IF NONE IS PROVIDED
  if(is.null(cmt_data)){
    cmt <- R.MFIV::cmt_dataset
  } else {
    cmt <- cmt_data
  }

  ## CHECK IF cmt_data COVERS RANGE OF date
  if(mean(date %in% cmt$Date) != 1){
    stop(crayon::red("\n Dates provided in "),
         crayon::silver("`date` "),
         crayon::red("are not contained in "),
         ifelse(is.null(cmt_data),
                paste0(crayon::silver("internal `cmt_data`"),
                       crayon::red(".\n Use"),
                       crayon::blue("`R.MFIV::cmt_dataset` "),
                       crayon::red("to access the internal data. \n")),
                paste0(crayon::silver("provided `cmt_data`"),
                       crayon::red(".\n"))
                )
         )
  }

  ## MAKE data.table FROM SINGLE VECTORS
  data <- data.table::data.table(date, exp)


  ## PREPARE CMT DATA FOR THE SPLINE FUNCTION
  int_data <- data.table::melt(data = cmt[Date %in% date,],
                               id.vars = "Date",
                               measure.vars = patterns("X"),
                               variable.name = "maturity",
                               value.name = "rate"
  )[, maturity := data.table::fcase(grepl("1.mo", maturity), 1/12,
                                    grepl("2.mo", maturity), 2/12,
                                    grepl("3.mo", maturity), 3/12,
                                    grepl("6.mo", maturity), 6/12,
                                    grepl("1.yr", maturity), 1,
                                    grepl("2.yr", maturity), 2,
                                    grepl("3.yr", maturity), 3,
                                    grepl("5.yr", maturity), 5,
                                    grepl("7.yr", maturity), 7,
                                    grepl("10.yr", maturity), 10,
                                    grepl("20.yr", maturity), 20,
                                    grepl("30.yr", maturity), 30
  )]

  ## DERIVE RISK-FREE-RATE VIA CUBIC SPLINE
  intfun <- function(int_data, date, maturity){
    stats::spline(x = int_data[Date == date]$maturity,
           y = int_data[Date == date]$rate,
           xout = maturity)$y
  }

  ret <- data[, R := intfun(int_data, unique(date), lubridate::time_length(exp-date, "years")),
              by = .(date)]

  ## RETURN RESULTS
  if(ret_table){
    return(ret[])
  } else {
    return(ret$R)
  }
}

