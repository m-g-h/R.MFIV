#' Extend and fill in the option quotes using Jiang & Tian (2007) Implied Volatility Curve Fitting
#' \loadmathjax
#'
#' \mjseqn{test}
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
#' extra_data <- JandT_2007_smoothing_method(option_quotes = nest,
#'                                           maturity = 0.008953152,
#'                                           K_0 = 147,
#'                                           price = 147.39,
#'                                           R = 0.008325593,
#'                                           F_0 = 147.405)
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
  K_2 <- IV_set[1, K]
  K_N1 <- IV_set[.N, K]
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
