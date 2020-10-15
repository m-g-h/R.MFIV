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
#' @param nested A \code{data.table} or "nest" with three columns:
#' \itemize{
#'   \item K (\code{numeric}, strike price in ascending order)
#'   \item c (\code{numeric}, call option price)
#'   \item p (\code{numeric}, put option price)
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
CBOE_option_selection <- function(nested, K_0){
  nested[1:.N %between% c(tail(c(1, which(is.na(shift(p, type = "lag"))  + is.na(p) == 2 & K <= K_0) + 1),      n = 1),
                                 head(c(   which(is.na(shift(c, type = "lead")) + is.na(c) == 2 & K  > K_0) - 1 , .N), n = 1)),
                .SD
  ][!is.na(c),
    ][!is.na(p),]
}
