#' CMT rate date obtained from the US Treasury
#'
#' @format A \code{data.table} with the following columns:
#' \itemize{
#'   \item{\strong{Date}   (\code{date})}{ - the day of the quoted CMT rates}
#'   \item{\strong{X1.mo}  (\code{numeric})}{ - \emph{decimal} one month CMT rate}
#'   \item{\strong{X2.mo}  (\code{numeric})}{ - \emph{decimal} two month CMT rate}
#'   \item{\strong{X3.mo}  (\code{numeric})}{ - \emph{decimal} three month CMT rate}
#'   \item{\strong{X6.mo}  (\code{numeric})}{ - \emph{decimal} six month CMT rate}
#'   \item{\strong{X1.yr}  (\code{numeric})}{ - \emph{decimal} one year CMT rate}
#'   \item{\strong{X2.yr}  (\code{numeric})}{ - \emph{decimal} two year CMT rate}
#'   \item{\strong{X3.yr}  (\code{numeric})}{ - \emph{decimal} three year CMT rate}
#'   \item{\strong{X5.yr}  (\code{numeric})}{ - \emph{decimal} five year CMT rate}
#'   \item{\strong{X7.yr}  (\code{numeric})}{ - \emph{decimal} seven year CMT rate}
#'   \item{\strong{X10.yr} (\code{numeric})}{ - \emph{decimal} ten year CMT rate}
#'   \item{\strong{X20.yr} (\code{numeric})}{ - \emph{decimal} twenty year CMT rate}
#'   \item{\strong{X30.yr} (\code{numeric})}{ - \emph{decimal} thirty year CMT rate}
#' }
#'
#' @source \href{https://www.treasury.gov/resource-center/data-chart-center/interest-rates/pages/TextView.aspx?data=yieldAll}{US Treasury website}
"cmt_dataset"

#' Example option quote dataset.
#'
#' @format A \code{data.table} with the following columns:
#' \itemize{
#'   \item{\strong{ticker}   (\code{character})}{ - the underlying stock ticker symbol}
#'   \item{\strong{t}  (\code{datetime})}{ - the time of quotation}
#'   \item{\strong{exp}  (\code{date})}{ - the expiration date}
#'   \item{\strong{price}  (\code{numeric})}{ - the underlying stock price}
#'   \item{\strong{option_quotes}  (\code{data.table})}{ - a "nest" of option quotes.
#'   Each cell in this column contains a \code{data.table} with the following columns:
#'     \itemize{
#'       \item{\strong{K}  (\code{numeric})}{ - the strike price}
#'       \item{\strong{c}  (\code{numeric})}{ - the corresponding call price}
#'       \item{\strong{p}  (\code{numeric})}{ - the corresponding put price}
#'     }
#'   }
#' }
#'
"option_dataset"
