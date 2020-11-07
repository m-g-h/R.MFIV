#' Extend and fill in the option quotes using Jiang & Tian (2005, 2007)
#' Implied Volatility Curve Fitting
#' \loadmathjax
#'
#' @details
#' The CBOE VIX calculation method relies on a wide option quotes over the range of
#' strike prices. However, the actual data might not yield enough option quotes. If
#' the quotes are spaced apart too far and have a limited range over the strike prices,
#' this introduces errors (see Jiang & Tian (2005, 2007)).
#'
#' Jiang & Tian (2005, 2007) also propose a smoothing method: option quotes are
#' transformed in to Black \& Scholes implied volatilities, intra- and extrapolated,
#' an then transformed back into option prices. This methodology is provided by this
#' function.
#'
#' After application of this method, the returned option_quotes are spaced apart by
#' \mjseqn{0.35} "SD Units", which translates into option price increments of
#' \mjseqn{SD \cdot \sqrt{maturity} \cdot price \cdot 0.35}, where \mjseqn{SD}
#' refers to a B&S implied volatility of the at-the-money option. The range of the
#' returned data spans \mjseqn{\pm 15} SD units.
#'
#' @inheritParams CBOE_F_0
#' @inheritParams CBOE_K_0
#' @inheritParams CBOE_option_selection
#' @inheritParams option_descriptives
#'
#' @return Returns a \code{data.table} of intra- and extrapolated option quotes with the
#' following columns:
#' \itemize{
#'   \item {\strong{K} (\code{numeric})}{ - strike price in ascending order}
#'   \item {\strong{Q} (\code{numeric})}{ - OTM option}
#' }
#'
#' @references
#' \href{https://doi.org/10.1093/RFS%2FHHI027}{Jiang & Tian (2005) -
#' The Model-Free Implied Volatility and Its Information Content}
#'
#' \href{https://doi.org/10.3905/jod.2007.681813}{Jiang & Tian (2007) -
#'  Extracting Model-Free Volatility
#' from Option Prices: An Examination of the VIX Index}
#'
#' @export
#'
#' @examples
#'
#' library(R.MFIV)
#'
#' ## LOAD EXAMPLE OPTION_QUOTES
#' nest <- option_dataset$option_quotes[[1]]
#'
#' ## EXTRAPOLATE DATA
#' JandT_2007_smoothing_method(option_quotes = nest,
#'                             maturity = 0.008953152,
#'                             K_0 = 147,
#'                             price = 147.39,
#'                             R = 0.008325593,
#'                             F_0 = 147.405)
#'
JandT_2007_smoothing_method <- function(option_quotes,
                                        K_0, price, R, maturity, F_0){

  ## Select OTM option quotes and calculate corresponding B&S IV
  IV_set <- option_quotes[, .(K = K,
                              Q = data.table::fcase(K < K_0, p,
                                                    K > K_0, c,
                                                    K == K_0, (c+p)/2))
  ][!is.na(Q)
  ][, TypeFlag := data.table::fifelse(K <= K_0,
                                      "p",
                                      "c")
  ][, IV := mapply(fOptions::GBSVolatility,
                   Q, TypeFlag, price, K, maturity, R/maturity,
                   MoreArgs = list(b = 0)
  )]


  ## ATM IMPLIED STANDARD DEVIATION
  SD <- as.numeric(IV_set[K == K_0]$IV)

  ## STRIKE PRICE INCREMENT ACCORDING TO JIANG & TIAN 2005
  inc <- floor(SD * sqrt(maturity) * price * 0.35)

  # CREATE CENTRAL PART OF THE OPTION_QUOTES
  center <- data.table::as.data.table(
    spline(x = IV_set$K, y = IV_set$IV,
           method = "natural",
           xout = seq(from = IV_set[1, K],
                      to = IV_set[.N, K],
                      by = inc)))

  ## DETERMINE BOUNDS OF THE OPTION QUOTES SET
  K_1 <- exp(SD * sqrt(maturity) * -15) * F_0
  K_2 <- center[1, x]
  K_N1 <- center[.N, x]
  K_N <- exp(SD * sqrt(maturity) * 15) * F_0

  ## CALCULATE LEFT SLOPE
  left_slope <- (center[1, y] - center[2, y]) / inc

  ## EXTRAPOLATE LEFT TAIL
  left_tail <- data.table::data.table(x = seq(from = K_2 - inc,
                                              to = K_1,
                                              by = -inc))[,
                                                          y := center[1, y] + (K_2 - x)*left_slope
                                              ]
  ## CALCULATE RIGHT SLOPE
  right_slope <- (center[.N, y] - center[.N-1, y]) / inc
  ## EXTRAPOLATE RIGHT TAIL
  right_tail <- data.table::data.table(x = seq(from = K_N1 + inc,
                                               to = K_N,
                                               by = inc))[,
                                                          y := center[.N, y] + (x - K_N1)*right_slope
                                               ]

  ## BIND CENTRAL PART AND TAILS
  IV_EX_set <- rbind(left_tail, center, right_tail)

  data.table::setkey(IV_EX_set, x)
  data.table::setnames(IV_EX_set, c("K", "IV"))

  ## FUNCTION FOR INSIDE THE MAPPLY CALL
  pricefun <- function(TypeFlag, price, K, maturity, R, IV, b){
    fOptions::GBSOption(TypeFlag = TypeFlag,
                        S = price,
                        X = K,
                        Time = maturity,
                        r =  R/maturity,
                        sigma = IV,
                        b = b)@price
  }

  ## CALCULATE OPTION PRICES USING B&S AND INTERPOLATED IV
  IV_EX_set[, TypeFlag := ifelse(K <= K_0,
                                 "p",
                                 "c")
  ][, Q := mapply(pricefun,
                  TypeFlag, price, K, maturity, R, IV,
                  MoreArgs = list(b = 0))
  ]


  ## RETURN INTERPOLATED OPTION_QUOTES
  IV_EX_set[,-c(2:3)]

}
