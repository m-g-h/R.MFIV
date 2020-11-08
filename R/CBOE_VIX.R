#' Calculate the theoretical at-the-money forward \mjseqn{F_0} from the CBOE VIX calculation.
#' \loadmathjax
#'
#' @description Following the \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{VIX whitepaper} this function
#' calculates \mjseqn{F_0} as:
#'
#' \mjsdeqn{F_0 := Strike Price + e^{RT} (Call Price - Put Price)}
#'
#' The variable \mjseqn{R} is the risk-free-rate (in decimal) for the corresponding time-to-maturity
#' \mjseqn{T} (in years). The \mjseqn{Strike Price}, \mjseqn{Call Price} and \mjseqn{Put Price} are
#' those where the absolute difference of the latter two is smallest.
#'
#' @param option_quotes A \code{data.table} or "nest" of option quotes with three columns:
#' \itemize{
#'   \item {\strong{K} (\code{numeric})}{ - strike price in ascending order}
#'   \item {\strong{c} (\code{numeric})}{ - call option price}
#'   \item {\strong{p} (\code{numeric})}{ - put option price}
#' }
#' @param R \code{numeric scalar} giving the risk-free rate \mjseqn{R} corresponding to the
#' maturity \mjseqn{T} in decimal
#' @param maturity \code{numeric scalar} giving the time to maturity \mjseqn{T} in years
#'
#' @return Returns a \code{numeric scalar}, giving the theoretical at-the-money
#'  forward \mjseqn{F_0}
#' @export
#'
#' @examples
#'
#' library(R.MFIV)
#'
#' nest <- option_dataset$option_quotes[[1]]
#'
#' CBOE_F_0(option_quotes = nest,
#'          R = 0.005,
#'          maturity = 0.07)

CBOE_F_0 <- function(option_quotes, R, maturity){
  option_quotes[which.min(abs(c-p)), K + exp(R*maturity) * (c-p)]
}

#' Calculate the theoretical at-the-money forward \mjseqn{K_0} from the CBOE VIX
#' calculation.
#' \loadmathjax
#'
#' @description Following the \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{VIX whitepaper}
#' \mjseqn{K_0} is defined as the strike price directly smaller or equal to the
#' theoretical at-the-money forward price \mjseqn{F_0}
#'
#' @inheritParams CBOE_F_0
#' @param F_0 \code{numeric scalar}, giving the  theoretical at-the-money forward \mjseqn{F_0}
#' (see \code{\link{CBOE_F_0}})
#'
#' @return Returns a \code{numeric scalar}, giving the theoretical at-the-money
#'  strike \mjseqn{K_0}
#' @export
#'
#' @examples
#'
#' library(R.MFIV)
#'
#' nest <- option_dataset$option_quotes[[1]]
#'
#' F_0 <- CBOE_F_0(option_quotes = nest,
#'          R = 0.005,
#'          maturity = 0.07)
#'
#' K_0 <- CBOE_K_0(option_quotes = nest,
#'          F_0 = F_0)

CBOE_K_0 <- function(option_quotes, F_0){
  option_quotes[K <= F_0, K[.N]]
}

#' CBOE Option selection scheme
#'
#' \loadmathjax
#' This function performs the selection of out-of-the-money options as explained in the
#' \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{VIX whitepaper}:
#' \emph{"Select out-of-the-money put options with strike prices \mjseqn{< K_0}. Start with the put strike
#' immediately lower than K0 and move to successively lower strike prices. Exclude any put option
#' that has a bid price equal to zero (i.e., no bid). As shown below, once two puts with consecutive
#' strike prices are found to have zero bid prices, no puts with lower strikes are considered for inclusion."}
#' The same principle applies to call options in ascending direction.
#'
#' @inheritParams CBOE_F_0
#' @param K_0 \code{numeric scalar}, giving the theoretical at-the-money strike price
#' (see \code{\link{CBOE_K_0}})
#'
#' @return Returns a \code{data.table} with three columns:
#' \itemize{
#'   \item {\strong{K} (\code{numeric})}{ - strike price in ascending order}
#'   \item {\strong{c} (\code{numeric})}{ - call option price}
#'   \item {\strong{p} (\code{numeric})}{ - put option price}
#' } which is filtered according to the CBOE rules
#'
#' @importFrom utils tail head
#' @importFrom data.table shift fifelse
#' @export
#'
CBOE_option_selection <- function(option_quotes, K_0){
  option_quotes[1:.N %between% c(tail(c(1, which(is.na(shift(p, type = "lag"))  + is.na(p) == 2 & K <= K_0) + 1),      n = 1),
                                 head(c(   which(is.na(shift(c, type = "lead")) + is.na(c) == 2 & K  > K_0) - 1 , .N), n = 1)),
                .SD
  ][!is.na(c),
  ][!is.na(p),]
}

#' Calculate the average strike price distance variable \mjseqn{\Delta K_i} from the CBOE VIX calculation.
#'
#' Following the \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{VIX whitepaper} this function
#' calculates \mjseqn{\Delta K_i} as \emph{"half the difference between the strike prices on either side of
#' \mjseqn{K_i}"}:
#' \loadmathjax
#' \mjsdeqn{\Delta K_i := \begin{cases} K_1 - K_0 \qquad \; \; if \; i = 0 \\\\\
#'                                      K_N - K_{N-1} \; \; \; if \; i = N \\\\\
#'                                      \frac{K_{i+1} - K_{i-1}}{2} \qquad \; else
#'                        \end{cases}}
#'
#' @param K A \code{numeric vector} of strike prices
#'
#' @return Returns a \code{numeric vector} giving the \mjseqn{\Delta K_i} variable of the CBOE VIX calculation.
#' @export
#'
#' @importFrom data.table fifelse shift
#'
#' @examples
#'
#' library(R.MFIV)
#' strikes <- c(10, 12.5, c(1:10)*5 + 10, 62.5, 65)
#' CBOE_delta_K(K = strikes)

CBOE_delta_K <- function(K){

  N <- length(K)
  n <- 1:N

  ret <- try(fifelse(n==1,
                     (shift(K, type = "lead")-K),
                     fifelse(n==N,
                             (K-shift(K, type = "lag")),
                             (shift(K, type = "lead") - shift(K, type = "lag"))/2
                     )),silent = T)
  if(class(ret)== "try-error"){
    NA_real_
  } else {
    ret}
}

#' Calculate the CBOE VIX model free variance \mjseqn{\sigma^2}
#'
#' @description This function performs the CBOE VIX model-free implied variance calculation
#' according to the following formula from the \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{2019 VIX whitepaper}:
#' \loadmathjax
#' \mjsdeqn{\sigma^2 = \frac{2}{T} \left(\sum_i \frac{\Delta K_i}{K_i^2} Q(K_i) e^{rT} \right) - \frac{1}{T} \left( \frac{F_0}{K_0} - 1 \right)^2}
#' It uses \code{\link{CBOE_delta_K}} internally to derive the weights \mjseqn{\Delta K_i}
#'
#' @inheritParams CBOE_option_selection
#' @inheritParams CBOE_F_0
#' @inheritParams CBOE_K_0
#' @param sel_option_quotes A \code{data.table} or "nest" of option quotes as selected by
#' \code{\link{CBOE_option_selection}}
#'
#' @return Returns a \code{numeric scalar}: the model-free implied volatility \mjseqn{\sigma^2} as
#' per the CBOE formula above.
#' @export
#'
#' @importFrom data.table fcase
#'
#' @examples
#'
#' library(R.MFIV)
#' nest <- CBOE_option_selection(option_dataset$option_quotes[[1]],
#'                               147)
#' CBOE_sigma_sq(sel_option_quotes = nest,
#'              maturity = 0.06644802,
#'              K_0 = 147,
#'              R = 0.008769736,
#'              F_0 = 147.5697)

CBOE_sigma_sq <- function(sel_option_quotes, K_0, F_0, maturity, R){
  sel_option_quotes[, .(K = K,
                        Q = fcase(K < K_0, p,
                                  K > K_0, c,
                                  K == K_0, (c+p)/2
                        )
  )][, ( (2/maturity) *  sum((  CBOE_delta_K(K) / (K^2) ) * ( exp(R*maturity) ) * Q ) ) - ( (1/maturity) * (( (F_0/K_0) - 1 )^2) )
  ]
}

#' Calculate all variables needed for the calculation of the CBOE VIX
#'
#' @description This is a wrapper around the \code{CBOE_...} functions that performs the calculation
#' of all variables required for the calculation of the squared model free implied volatility (\mjseqn{\sigma^2})
#' as per the \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{VIX whitepaper}:
#'
#' \loadmathjax
#' \mjsdeqn{\sigma^2 = \frac{2}{T} \left(\sum_i \frac{\Delta K_i}{K_i^2} Q(K_i) e^{rT} \right) - \frac{1}{T} \left( \frac{F_0}{K_0} - 1 \right)^2}
#'
#' @inheritParams CBOE_F_0
#' @param ret_vars A \code{logical scalar} - if true, all VIX variables are returned, else only \mjseqn{\sigma^2}
#' is returned.
#'
#' @return Returns either a \code{numeric scalar} giving \mjseqn{\sigma^2} or a \code{list} with all variables
#' involved in the calculation:
#' \itemize{
#'   \item {\strong{F_0} (\code{numeric})}{ - theoretical at-the money forward \mjseqn{F_0}
#'    (see \code{\link{CBOE_F_0}})}
#'   \item {\strong{K_0} (\code{numeric})}{ - theoretical at-the money strike \mjseqn{K_0}
#'    (see \code{\link{CBOE_K_0}})}
#'   \item {\strong{n_put_raw} (\code{numeric})}{ - number of put options before option selection
#'    (see \code{\link{CBOE_option_selection}})}
#'   \item {\strong{n_call_raw} (\code{numeric})}{ - number of call options before option selection
#'    (see \code{\link{CBOE_option_selection}})}
#'   \item {\strong{n_put} (\code{numeric})}{ - number of put options after option selection}
#'   \item {\strong{n_call} (\code{numeric})}{ - number of call options after option selection}
#'   \item {\strong{sigma_sq} (\code{numeric})}{ - squared model free implied volatility \mjseqn{\sigma^2}
#'    (see \code{\link{CBOE_sigma_sq}})}
#' }
#' @export
#'
#' @examples
#'
#' library(R.MFIV)
#'
#' nest <- option_dataset$option_quotes[[1]]
#' CBOE_VIX_vars(option_quotes = nest,
#'               R = 0.005,
#'               maturity = 0.07,
#'               ret_vars = TRUE)
#'
CBOE_VIX_vars <- function(option_quotes, R, maturity,
                          ret_vars = F){
  ## Stop if there are two or less quotes
  if(nrow(option_quotes) < 2){
    warning(crayon::silver("NA "),
            "returned. There were less than two quotes in ",
            crayon::silver("`option_quotes`"),
            ".")
    return(NA)
  }
  ## CALCULATE FIRST TWO VARIABLES
  F_0 <- CBOE_F_0(option_quotes = option_quotes,
                  R = R,
                  maturity = maturity)

  K_0 <- CBOE_K_0(option_quotes = option_quotes,
                  F_0 = F_0)
  ## HELPERS
  n_put_raw <- option_quotes[K<K_0 &!is.na(p), .N]
  n_call_raw <- option_quotes[K>K_0 &!is.na(c), .N]
  ## Stop if there are no puts or calls
  if(n_put_raw == 0 | n_call_raw == 0){
    warning(crayon::silver("NA "),
            "returned. There were no put / call quotes in ",
            crayon::silver("`option_quotes`"),
            ".")
    return(NA)
  }

  ## OPTION SELECTION
  option_quotes_sel <- CBOE_option_selection(option_quotes = option_quotes,
                                             K_0 = K_0)
  ## HELPERS 2
  n_put <- option_quotes_sel[K<K_0, .N]
  n_call <- option_quotes_sel[K>K_0, .N]
  ## Stop if there are no puts or calls
  if(n_put == 0 | n_call == 0){
    warning(crayon::silver("NA "),
            "returned. There were no put / call quotes left in ",
            crayon::silver("`option_quotes`"),
            " after selecting by the CBOE rule.")
    return(NA)
  }
  ## sigma^2
  sigma_sq <- CBOE_sigma_sq(sel_option_quotes = option_quotes_sel,
                            K_0 =  K_0,
                            F_0 = F_0,
                            maturity = maturity,
                            R = R)
  ## RETURN
  if(ret_vars){
    list("F_0" = F_0,
         "K_0" = K_0,
         "n_put_raw" = n_put_raw,
         "n_call_raw" = n_call_raw,
         "n_put" = n_put,
         "n_call" = n_call,
         "sigma_sq" = sigma_sq)
  } else {
    sigma_sq
  }
}

#' Determine the expiration "term" used in the linear interpolation of the CBOE VIX
#'
#' @description Provide either \code{maturity} or \code{date_t} and \code{date_exp}
#'
#' This function determines the interpolation terms used for the VIX.
#' It provides terms for the two different interpolation techniques used by the CBOE:
#' \itemize{
#'   \item {\strong{2003 VIX} (monthly):} {using monthly options (see the \href{https://web.archive.org/web/20091231021416/https://www.cboe.com/micro/vix/vixwhite.pdf}{2009 CBOE Whitepaper})}
#'   \item {\strong{2014 VIX} (weekly):} {using weekly  options (see the \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{2019 VIX whitepaper})}
#' }
#'
#' Both methods rely on a "near-term" and a "next-term" contract.
#'
#' @inheritParams CBOE_F_0
#' @param date_t (For the monthly method) \code{date scalar} giving the date of the option quotation
#' @param date_exp (For the monthly method) \code{date scalar} giving the date of the option expiration
#' @param method A \code{string scalar}, either \code{"weekly"} or \code{"monthly"} for the
#' respective method.
#'
#' @return Returns a \code{numeric scalar}: \code{1} for the "near-term" and \code{2} for the "next-term".
#' If the maturity doesn't fall inside either category, \code{NA} is returned.
#' @export
#'
#' @examples
#'
#' library(R.MFIV)
#'
#' ## Weekly method
#' CBOE_interpolation_terms(25/365, method = "weekly")
#'
#' ## Monthly method
#' t <- lubridate::ymd("2020-01-02")
#' exp <- lubridate::ymd("2020-02-21")
#' CBOE_interpolation_terms(date_t = t, date_exp = exp, method = "monthly")
#'
CBOE_interpolation_terms <- function(maturity, date_t, date_exp, method){
  ## WEEKLY METHOD
  if(method == "weekly"){
    fcase(maturity > 23/365  & maturity <= 30/365, 1,
          maturity > 30/365  & maturity <= 37/365, 2,
          TRUE , NA_real_)
    ## MONTHLY METHOD
  } else if(method == "monthly"){
    valid_days <- third_fridays(date_t , date_exp + months(3))
    valid_days <- valid_days[valid_days-date_t > 7]
    fcase(date_exp == valid_days[1], 1,
          date_exp == valid_days[2], 2,
          TRUE , NA_real_)
  }
}


#' Calculates the linear VIX interpolation and returns the
#' annualised VIX index in percentage points
#'
#' \loadmathjax
#' Following the \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{VIX whitepaper}, the VIX index is
#' calculated as a linear interpolation. This function uses the following formula:
#' \mjsdeqn{\sigma_{VIX} =  100 \sqrt{ \big( \omega T_1 \sigma_1^2 + (1- \omega) T_2 \sigma_2^2 \big) \frac{525,600}{43,200} }}
#' where the subscripts \mjseqn{1} and \mjseqn{2} indicate the near-and next-term options, \mjseqn{T_\cdot}
#' to the time to expiration in years and the \mjseqn{\omega} to the linear interpolation weights.
#'
#' @param maturity \code{numeric vector of length two} giving the time to maturity of the
#' "near-term" and "next-term" options in years (\mjseqn{T_1} and \mjseqn{T_2} respectively)
#' @param sigma_sq \code{numeric vector of length two} giving the CBOE model-free implied volatility
#' of the "near-term" and "next-term" options(\mjseqn{\sigma^2_1} and \mjseqn{\sigma^2_2} respectively).
#'  Also see \code{\link{CBOE_sigma_sq}}
#'
#' @return Returns a \code{numeric scalar} giving the VIX index value
#' @export
#'
#' @examples
#'
#' library(R.MFIV)
#'
#' CBOE_VIX_index(maturity = c(0.074, 0.09),
#'                sigma_sq = c(0.3, 0.5))
#'
#'
CBOE_VIX_index <- function(maturity, sigma_sq){
  if(length(maturity) != 2
     |length(sigma_sq) != 2){
    stop(crayon::red("the provided arguments "),
         crayon::silver("`maturity` "),
         crayon::red("and "),
         crayon::silver("`sigma_sq` "),
         crayon::red("are not of length "),
         crayon::silver("2"),
         crayon::red(". See "),
         crayon::blue("`help(CBOE_VIX_interpolation)`"))
  }
  ## LINEAR INTERPOLATION / Extrapolation

  omega <- (maturity[2] - (30/365))/(maturity[2]- maturity[1])
  sigma_sq_30 <- (omega * maturity[1] * sigma_sq[1]) + ((1-omega) * maturity[2] * sigma_sq[2])

  ## approx doesn't support extrapolation!
  # sigma_sq_30 <- stats::approx(x = maturity,
  #               y = sigma_sq*maturity,
  #               xout = 30/365)$y

  ## CALCULATE ANNUALISED STANDARD DEVIATION IN PERCENTAGE POINTS
  100 * sqrt(sigma_sq_30 * (365*24*60) / (30*24*60))
}
