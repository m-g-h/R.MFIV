#' Extend and fill in the option quotes using Jiang & Tian (2005, 2007)
#' Implied Volatility Curve Fitting
#' \loadmathjax
#'
#' Intrapolates and extrapolates the option_quotes over the strike price range using
#' the Jiang & Tian (2007) smoothing method. The given quotes are transformed into
#' Black & Scholes implied volatilities, on which intra/extrapolation takes place.
#'
#' Inside the given range of strike prices, (natural) cubic spline intrapolation takes
#' place.
#'
#' The tails are extrapolated linearly. For \code{flat} extrapolation, the "outer-most"
#' implied volatility is used, for \code{sloped} extrapolation the slope of the two
#' "outer-most" implied volatilities is used.
#'
#' After intra/extrapolation, the implied volatilities are transformed back into option
#' prices via Black&Scholes, i.e. out-of-the-money puts and calls.
#'
#' Jiang & Tian (2007) define the range and increment of the strike prices in \mjseqn{SD}
#' units. This \mjseqn{SD} is the Black & Scholes implied volatility of the at-the-money
#' option. As an example, the increment recommended by Jiang & Tian (2007) is mjseqn{0.35}
#' units: \mjseqn{SD \cdot \sqrt{maturity} \cdot price \cdot 0.35}
#'
#'
#' @inheritParams CBOE_F_0
#' @inheritParams CBOE_K_0
#' @inheritParams CBOE_option_selection
#' @inheritParams option_descriptives
#' @param tail_length \code{numeric scalar} giving the strike-price range of the
#' returned option quotes in \mjseqn{SD} units (see details). If the tail length
#' doesn't exceed the the range of the given option quotes, no extrapolation takes place.
#' @param flat_tails \code{logical scalar} determining whether the extrapolation in the
#' tails is sloped or flat (see details)
#' @param increment \code{character or numeric scalar} giving the strike-price increment
#' of the returned option quotes in \mjseqn{SD} units (see details). Options are:
#' \itemize{
#'   \item {\strong{x} (\code{numeric})}{ - any number giving the strike-price increment
#'   in price units}
#'   \item {\strong{"JT"} (\code{character})}{ - the increment from Jiang & Tian (2007)
#'   i.e. \mjseqn{SD \cdot \sqrt{maturity} \cdot price \cdot 0.35}}
#'   \item {\strong{"real"} (\code{character})}{ - the smallest increment found in the
#'   "real" data}
#'   \item {\strong{"min"} (\code{character})}{ - the smaller one of "JT" and "min"}
#' }
#' @return Returns a \code{data.table} of intra- and extrapolated option quotes with the
#' following columns:
#' \itemize{
#'   \item {\strong{K} (\code{numeric})}{ - evenly spaced strike price in ascending order}
#'   \item {\strong{Q} (\code{numeric})}{ - OTM option price}
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
#' @import data.table
#' @importFrom fOptions GBSVolatility GBSOption
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
#'                             maturity = 0.06644802,
#'                             K_0 = 147,
#'                             R = 0.008769736,
#'                             F_0 = 147.5697,
#'                             price = 147.39)

JandT_2007_smoothing_method <- function(option_quotes,
                                        K_0, price, R, maturity, F_0,
                                        tail_length = 15, flat_tails = T,
                                        increment = "min"){

  ## Select OTM option quotes and calculate corresponding B&S IV
  IV_set <- option_quotes[, .(K = K,
                              Q = fcase(K <= K_0, p,
                                        K > K_0, c))
  ][!is.na(Q)
  ][, TypeFlag := fifelse(K <= K_0,
                          "p",
                          "c")
  ][, IV := mapply(GBSVolatility,
                   Q, TypeFlag, price, K, maturity, R/maturity,
                   MoreArgs = list(b = 0)
  )]


  ## ATM IMPLIED STANDARD DEVIATION
  SD <- as.numeric(IV_set[K == K_0]$IV)

  ## GIVEN INCREMENT NUMBER
  if(is.numeric(increment)){
    inc <- increment
    ## STRIKE PRICE INCREMENT ACCORDING TO JIANG & TIAN 2005
  } else if(increment == "JT"){
    inc <- floor(SD * sqrt(maturity) * price * 0.35)
    ## SMALLEST INCREMENT IN REAL DATA
  } else if(increment == "real"){
    inc <- min(option_quotes$K - shift(option_quotes$K), na.rm = T)
    ## SMALLER OF "JT" AND "real"
  } else if(increment == "min"){
    inc <- floor(SD * sqrt(maturity) * price * 0.35)
    inc_real <- min(option_quotes$K - shift(option_quotes$K), na.rm = T)

    inc <- min(inc, inc_real)
  }

  # CREATE CENTRAL PART OF THE OPTION_QUOTES
  center <- as.data.table(
    spline(x = IV_set$K, y = IV_set$IV,
           method = "natural",
           xout = seq(from = IV_set[1, K],
                      to = IV_set[.N, K],
                      by = inc)))

  ## DETERMINE BOUNDS OF THE OPTION QUOTES SET
  K_1 <- exp(SD * sqrt(maturity) * -tail_length) * F_0
  K_2 <- center[1, x]

  K_N1 <- center[.N, x]
  K_N <- exp(SD * sqrt(maturity) * tail_length) * F_0


  ## CALCULATE SLOPES IF NEEDED
  if(!flat_tails){
    left_slope <- (center[1, y] - center[2, y]) / inc
    right_slope <- (center[.N, y] - center[.N-1, y]) / inc
  } else {
    left_slope <- 0
    right_slope <- 0
  }

  ## CREATE EMPTY TAILS
  left_tail <- data.table()
  right_tail <- data.table()

  ## EXTRAPOLATE LEFT TAIL IF NEEDED
  if(K_1 < (K_2-inc)){
    left_tail <- data.table(x = seq(from = K_2 - inc,
                                    to = K_1,
                                    by = -inc))[,
                                                y := center[1, y] + ((K_2 - x)*left_slope)
                                    ]
  }
  ## EXTRAPOLATE RIGHT TAIL IF NEEDED
  if(K_N > (K_N1 + inc)){
    right_tail <- data.table(x = seq(from = K_N1 + inc,
                                     to = K_N,
                                     by = inc))[,
                                                y := center[.N, y] + ((x - K_N1)*right_slope)
                                     ]
  }
  ## BIND CENTRAL PART AND TAILS
  IV_EX_set <- rbind(left_tail, center, right_tail)

  setkey(IV_EX_set, x)
  setnames(IV_EX_set, c("K", "IV"))

  ## FUNCTION FOR INSIDE THE MAPPLY CALL
  pricefun <- function(TypeFlag, price, K, maturity, R, IV, b){
    res <- GBSOption(TypeFlag = TypeFlag,
                     S = price,
                     X = K,
                     Time = maturity,
                     r =  R/maturity,
                     sigma = IV,
                     b = b)@price
    fifelse(res < 1e-15,
            0, res)
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

#' Calculate the MFIV according to the Jiang & Tian (2007) paper
#'
#' @description This function performs the model-free implied variance calculation
#' according to the following formula from Jiang & Tian (2007):
#' \loadmathjax
#' \mjsdeqn{V = \frac{2}{T} \exp(R T) (A + B)  }
#' \mjsdeqn{A = \sum_{i \leq 0} \frac{\Delta \hat{K}_i}{2} \left( \frac{P^{EX} (\hat{K}_i, T)}{\hat{K}^2_i} + \frac{P^{EX} (\hat{K}_j, T)}{\hat{K}^2_j}  \right)  }
#'
#' \mjsdeqn{B = \sum_{i \leq 0} \frac{\Delta \hat{K}_i}{2} \left( \frac{C^{EX} (\hat{K}_i, T)}{\hat{K}^2_i} + \frac{C^{EX} (\hat{K}_j, T)}{\hat{K}^2_j}  \right)  }
#' \mjsdeqn{ \Delta \hat{K}_i = \hat{K}_i - \hat{K}_j }
#' \mjsdeqn{j = i-1}
#'
#' @inheritParams CBOE_option_selection
#' @inheritParams CBOE_F_0
#' @inheritParams CBOE_K_0
#' @param smooth_option_quotes A \code{data.table} or "nest" of option quotes as retured
#' from \code{\link{JandT_2007_smoothing_method}}
#'
#' @return Returns a \code{numeric scalar}: the model-free implied volatility \mjseqn{\sigma^2} as
#' per the CBOE formula above.
#' @export
#'
#' @references
#'
#' \href{https://doi.org/10.3905/jod.2007.681813}{Jiang & Tian (2007) -
#'  Extracting Model-Free Volatility}
#'
#' @importFrom data.table shift fcase
#'
#' @examples
#'
#' library(R.MFIV)
#'
#' ## LOAD EXAMPLE OPTION_QUOTES
#' nest <- option_dataset$option_quotes[[1]]
#'
#' ## EXTRAPOLATE DATA
#' smooth_nest <- JandT_2007_smoothing_method(option_quotes = nest,
#'                                            maturity = 0.008953152,
#'                                            K_0 = 147,
#'                                            price = 147.39,
#'                                            R = 0.008325593,
#'                                            F_0 = 147.405)
#' ## CALCULATE MFIV
#' sigma_sq <- JandT_2007_sigma_sq(smooth_option_quotes = smooth_nest,
#'                                 K_0 = 147,
#'                                 maturity = 0.008953152,
#'                                 R = 0.008325593)

JandT_2007_sigma_sq <- function(smooth_option_quotes,K_0, maturity, R){
  ## DETERMINE STRIKE SPACING (delta_K / 2)
  delta_K <- unique((smooth_option_quotes$K - shift(smooth_option_quotes$K))[-1]) / 2

  ## TRAPEZOIDAL INTEGRATION
  sum <- smooth_option_quotes[.(K = K,
                                QK = Q/(K^2))
  ][, sum(QK + shift(QK),na.rm = T)]

  ## RETURN FULL MFIV
  (2 / maturity) * exp(R * maturity) * delta_K * (sum)
}
