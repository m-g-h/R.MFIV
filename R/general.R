#' Calculate descriptive variables for a nest of option quotes
#' @inheritParams CBOE_F_0
#' @inheritParams CBOE_option_selection
#' @param price \code{numeric scalar} giving the underlying stock price.
#'
#' @return Returns a \code{list} with the following variables:
#' \itemize{
#'   \item {\strong{SD} (\code{numeric})}- the Black Merton Scholes implied volatility for the at-the money call
#'   (using \code{GBSVolatility} from \code{fOptions})
#'   \item {\strong{max_K} (\code{numeric})} - highest strike price for out-of-the-money calls
#'   \item {\strong{min_K} (\code{numeric})} - lowest strike price for out-of-the-money puts
#'   \item {\strong{mean_delta_K} (\code{numeric})} - average distance between strike prices
#'   \item {\strong{n_put} (\code{numeric})} - number of out-of-the money puts
#'   \item {\strong{n_call} (\code{numeric})} - number of out-of-the money calls
#' }
#' @export
#'
#' @examples
#'
#' library(R.MFIV)
#'
#' nest <- option_dataset$option_quotes[[1]]
#'
#' option_descriptives(option_quotes = nest,
#'                    K_0 = 147,
#'                    R = 0.005,
#'                    price = 147,
#'                    maturity = 0.07)
#'
option_descriptives <- function(option_quotes, K_0, R, price,  maturity){
  ## ATM IV
  SD <- GBSVolatility(price = option_quotes[K == K_0, c],
                                TypeFlag = "c",
                                S = price,
                                X = K_0,
                                Time = maturity,
                                r = R/maturity,
                                b = 0)
  ## REMOVE MISSING VALUES
  option_quotes <- option_quotes[!is.na(p) & K <= K_0
                                 | !is.na(c) & K > K_0,]
  ## RANGE OF STRIKE PRICES
  max_K <- option_quotes[which.max(K), K]
  min_K <- option_quotes[which.min(K), K]
  ## SPACING OF STRIKE PRICES
  mean_delta_K <- option_quotes[, .(delta_K = mean(K - shift(K), na.rm = T))][1,delta_K]
  ## NUMBER OF OPTIONS
  n_put <- option_quotes[K<K_0, .N]
  n_call <- option_quotes[K>K_0, .N]

  ## RETURN
  list("SD" = SD,
       "max_K" = max_K,
       "min_K" = min_K,
       "mean_delta_K" = mean_delta_K,
       "n_put" = n_put,
       "n_call" = n_call)
}

#' List third fridays in the months of the period given by \code{start} and \code{end}
#'
#' The 2003 VIX (see the \href{https://web.archive.org/web/20091231021416/https://www.cboe.com/micro/vix/vixwhite.pdf}{2009 CBOE Whitepaper})
#' is based on monthly option contracts, which expire on every third friday of a month.
#' This function identifies monthly third fridays in order to select the correct monthly options.
#'
#' @param start \code{Date scalar}, giving the start date
#' @param end  \code{Date scalar}, giving the end date
#'
#' @return Returns a \code{date vector} with all third fridays of the respective period.
#' @export
#'
#' @importFrom lubridate floor_date ceiling_date days
#' @importFrom data.table data.table wday year
#'
#' @examples
#'
#' start <- lubridate::ymd("2020-01-01")
#' end <- lubridate::ymd("2020-06-01")
#'
#' third_fridays(start, end)

third_fridays <- function(start, end){
  ## ROUND DATES TO START AND END OF MONTHS RESPECTIVELY
  alpha <- floor_date(start, "months")
  omega <- ceiling_date(end, "months")

  ## GENERATE SEQUENCE OF ALL SINGLE DAYS AND FILTER OUT THE THIRD FRIDAYS
  data.table(all_days = alpha + days(1:as.numeric(omega - alpha))
  )[wday(all_days) == 6,
  ][,my := paste(year(all_days), month(all_days))
  ][, ind := 1:.N, by = my
  ][ind == 3, all_days]
}
