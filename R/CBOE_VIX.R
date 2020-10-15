# CBOE_VIX <- function(t, nest, R, T_n, Price){
#   ## Stop if there are two or less quotes
#   if(nrow(nest) < 2){
#     return(NA)
#   }
#   F_0 <- nest[which.min(abs(c-p)), .(F_0 = K + exp(R*T_n) * (c-p))][1, F_0]
#   K_0 <- nest[K <= F_0, K[.N]]
#   ## HELPERS
#   n_put_raw <- nest[K<K_0 &!is.na(p), .N]
#   n_call_raw <- nest[K>K_0 &!is.na(c), .N]
#   ## Stop if there are no puts or calls
#   if(n_put_raw == 0 | n_call_raw == 0){
#     return(NA)
#   }
#   ## ATM IV
#   SD <- fOptions::GBSVolatility(price = nest[K == K_0, c],
#                                 TypeFlag = "c",
#                                 S = Price,
#                                 X = K_0,
#                                 Time = T_n,
#                                 r = R/T_n,
#                                 b = 0)
#   ## OPTION SELECTION
#   nest_sel <- R.MFIV::CBOE_option_selection(nest, K_0)
#   ## DESCRIPTIVES
#   n_put <- nest_sel[K<K_0, .N]
#   n_call <- nest_sel[K>K_0, .N]
#   max_K <- nest_sel[which.max(K), K]
#   min_K <- nest_sel[which.min(K), K]
#   mean_delta_K <- nest_sel[, .(delta_K = mean(K - shift(K), na.rm = T))][1,delta_K]
#   n <- n_put + n_call +1
#   ## Stop if there are no puts or calls
#   if(n_put == 0 | n_call == 0){
#     return(NA)
#   }
#   ## sigma^2
#   sigma_sq <- R.MFIV::calc_sigma_sq(nest_sel, F_0, K_0, T_n, R)[1,sigma]
#   ## RETURN
#   list(F_0,
#        K_0,
#        n_put_raw,
#        n_call_raw,
#        SD,
#        n_put,
#        n_call,
#        max_K,
#        min_K,
#        mean_delta_K,
#        n,
#        sigma_sq)
# }

#' CBOE Option selection scheme
#' \loadmathjax
#' This function performs the selection of out-of-the-money options as explained in the
#' \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{VIX whitepaper}:
#' \emph{"Select out-of-the-money put options with strike prices \mjseqn{< K_0}. Start with the put strike
#' immediately lower than K0 and move to successively lower strike prices. Exclude any put option
#' that has a bid price equal to zero (i.e., no bid). As shown below, once two puts with consecutive
#' strike prices are found to have zero bid prices, no puts with lower strikes are considered for inclusion."}
#' The same principle applies to call options in ascending direction.
#'
#' @param option_quotes A \code{data.table} or "nest" of option quotes with three columns:
#' \itemize{
#'   \item {\strong{K} (\code{numeric})}{ - strike price in ascending order}
#'   \item {\strong{c} (\code{numeric})}{ - call option price}
#'   \item {\strong{p} (\code{numeric})}{ - put option price}
#' }
#' @param K_0 \code{numeric scalar}, giving the theoretical at-the-money strike price
#'
#' @return Returns a \code{data.table} with two columns:
#' \itemize{
#'   \item K (\code{numeric}, strike price in ascending order)
#'   \item c (\code{numeric}, out-of-the money option prices)
#' }
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

#' Calculate the theoretical at-the-money forward \mjseqn{F_0} from the CBOE VIX calculation.
#' \loadmathjax
#'
#' @description Following the \href{https://www.cboe.com/micro/vix/vixwhite.pdf}{VIX whitepaper} this function
#' calculates \mjseqn{F_0} as:
#'
#' \mjsdeqn{F_0 := Strike Price + e^{RT} (Call Price - Put Price)}
#'
#' \mjseqn{R}is the risk-free-rate (in decimal) for the corresponding time-to-maturity
#' \mjseqn{T} (in years). The \mjseqn{Call Price} and \mjseqn{Put Price} are those where their absolute
#' difference is smallest.
#'
#' @inheritParams CBOE_option_selection
#' @param R \code{numeric scalar or vector} giving the risk-free rate(s) \mjseqn{R}
#' @param maturity \code{numeric scalar or vector} giving the time(s) to maturity \mjseqn{T}
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
  data.table(option_quotes = list(option_quotes),
             R = R,
             maturity = maturity
  )[, option_quotes[[1]][which.min(abs(c-p)), .(F_0 = K + exp(R*maturity) * (c-p))]
    ][, F_0]
}
