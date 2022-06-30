#' Internal function
#' @noRd

NDF =  function(x) {
  # A function implemented by Diethelm Wuertz

  # Description:
  #   Calculate the normal distribution function.

  # FUNCTION:

  # Compute:
  result = exp(-x*x/2)/sqrt(8*atan(1))

  # Return Value:
  result
}

#' Internal function
#' @noRd

CND =  function(x) {

  # A function implemented by Diethelm Wuertz

  # Description:
  #   Calculate the cumulated normal distribution function.

  # References:
  #   Haug E.G., The Complete Guide to Option Pricing Formulas

  # FUNCTION:

  # Compute:
  k  = 1 / ( 1 + 0.2316419 * abs(x) )
  a1 =  0.319381530; a2 = -0.356563782; a3 =  1.781477937
  a4 = -1.821255978; a5 =  1.330274429
  result = NDF(x) * (a1*k + a2*k^2 + a3*k^3 + a4*k^4 + a5*k^5) - 0.5
  result = 0.5 - result*sign(x)

  # Return Value:
  result
}

#' Internal function
#' @noRd

GBSOption = function(TypeFlag = c("c", "p"), S, X, Time, r, b, sigma){
  # A function implemented by Diethelm Wuertz

  # Description:
  #   Calculate the Generalized Black-Scholes option
  #   price either for a call or a put option.

  # References:
  #   Haug E.G., The Complete Guide to Option Pricing Formulas

  # FUNCTION:

  # Compute:
  TypeFlag = TypeFlag[1]
  d1 = ( log(S/X) + (b+sigma*sigma/2)*Time ) / (sigma*sqrt(Time))
  d2 = d1 - sigma*sqrt(Time)
  if (TypeFlag == "c")
    result = S*exp((b-r)*Time)*CND(d1) - X*exp(-r*Time)*CND(d2)
  if (TypeFlag == "p")
    result = X*exp(-r*Time)*CND(-d2) - S*exp((b-r)*Time)*CND(-d1)

  return(result)
}

#' Internal function
#' @noRd

GBSVolatility = function(price, TypeFlag = c("c", "p"), S, X, Time, r, b,
                         tol = .Machine$double.eps, maxiter = 10000) {
  # A function implemented by Diethelm Wuertz

  # Description:
  #   Compute implied volatility

  # Example:
  #   sigma = GBSVolatility(price=10.2, "c", S=100, X=90, Time=1/12, r=0, b=0)
  #   sigma
  #   GBSOption("c", S=100, X=90, Time=1/12, r=0, b=0, sigma=sigma)

  # FUNCTION:

  # Option Type:
  TypeFlag = TypeFlag[1]

  # Search for Root:
  volatility = uniroot(.fGBSVolatility, interval = c(-10,10), price = price,
                       TypeFlag = TypeFlag, S = S, X = X, Time = Time, r = r, b = b,
                       tol = tol, maxiter = maxiter)$root

  # Return Value:
  volatility
}


#' Internal function
#' @noRd

.fGBSVolatility <- function(x, price, TypeFlag, S, X, Time, r, b, ...) {
  GBS = GBSOption(TypeFlag = TypeFlag, S = S, X = X, Time = Time,
                  r = r, b = b, sigma = x)
  price - GBS
}

