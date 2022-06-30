
<!-- README.md is generated from README.Rmd. Please edit that file -->

# R.MFIV <img src="man/figures/hex_small.svg" align="right" />

<!-- badges: start -->

[![Codecov test
coverage](https://codecov.io/gh/m-g-h/R.MFIV/branch/master/graph/badge.svg)](https://codecov.io/gh/m-g-h/R.MFIV?branch=master)
[![R-CMD-check](https://github.com/m-g-h/R.MFIV/workflows/R-CMD-check/badge.svg)](https://github.com/m-g-h/R.MFIV/actions)
<!-- badges: end -->

R.MFIV can be installed via:

``` r
remotes::install_github("m-g-h/R.MFIV")
```

## Package Functionality

The VIX is defined as:

<img src="man/figures/VIX_formulas.PNG" width="45%" style="display: block; margin: auto;" />

where the term in brackets under the square root is a linear
interpolation of two Implied Variances, which are given by the second
formula. The CBOE approach of the VIX calculation is explained in the
[CBOE VIX Whitepaper](http://www.cboe.com/micro/vix/vixwhite.pdf).

In order to calculate the VIX and its individual variables, this package
provides the following functionality as explained in the following
sections

**1. Short Walkthrough**

-   Calculate the *Risk-Free-Rate R* `interpolate_rfr()`
-   Calculate the *At-The-Money Forward Price F<sub>0</sub>*
    `CBOE_F_O()`
-   Calculate the *At-The-Money Strike Price K<sub>0</sub>* `CBOE_K_0()`
-   *Select* the Option Quotes Q(K<sub>i</sub>) according to the CBOE
    Rule `CBOE_option_selection()`
-   Calculate the *Implied Variance σ<sup>2</sup>* `CBOE_sigma_sq()`
-   Do all of the above in one function `CBOE_VIX_variables()`
-   Interpolate the **VIX** using two Implied Variances
    `CBOE_VIX_index()`
-   Calculate *Option Descriptives* `option_descriptives()`

**2. Processing a whole dataset (using data.table)**

-   Automatically determine the *Expiration Terms* (“near-” and
    “next-term”) `CBOE_interpolation_terms()`
-   Create the implied Variance (and VIX variables) for a whole dataset
-   Interpolate the weekly or monthly VIX index

**3. Visualise the VIX-Index**

-   As single plot `plot_VIX()`
-   Browse through plots of multiple tickers with an *interactive Shiny
    App* `result_browser()`

**4. Analyse the Option-Data Quality**

-   Calculate Option Descriptives for the whole
    dataset`option_descriptives()`
-   Visualise the option data quality \[to be done\]

**5. Improve Option-Data Quality using Smooting Methods**

-   Intra- and Extrapolate option quotes `JandT_2007_smoothing_method()`
-   Calculate the Jiang & Tian MFIV `JandT_2007_sigma_sq()`

## 1. Short Walkthrough

Load exemplary package data

``` r
library(R.MFIV)
data(option_dataset)
option_dataset
#>        ticker                   t        exp   price       option_quotes
#>     1:   AAAA 2017-06-13 09:31:00 2017-06-16 147.390  <data.table[96x3]>
#>     2:   AAAA 2017-06-13 09:31:00 2017-06-23 147.390  <data.table[60x3]>
#>     3:   AAAA 2017-06-13 09:31:00 2017-06-30 147.390  <data.table[53x3]>
#>     4:   AAAA 2017-06-13 09:31:00 2017-07-07 147.390  <data.table[51x3]>
#>     5:   AAAA 2017-06-13 09:31:00 2017-07-14 147.390  <data.table[40x3]>
#>    ---                                                                  
#> 12866:   BBBB 2017-06-13 16:00:00 2017-12-15 980.805  <data.table[91x3]>
#> 12867:   BBBB 2017-06-13 16:00:00 2018-01-19 980.805 <data.table[139x3]>
#> 12868:   BBBB 2017-06-13 16:00:00 2018-06-15 980.805  <data.table[71x3]>
#> 12869:   BBBB 2017-06-13 16:00:00 2018-09-21 980.805  <data.table[65x3]>
#> 12870:   BBBB 2017-06-13 16:00:00 2019-01-18 980.805 <data.table[117x3]>
```

We select an exemplary entry for the calculation. This observation will
be our “near-term” contract. Also note that `option_quotes` is a
“nested” data.table itself

``` r
t <- option_dataset$t[2]
exp <- option_dataset$exp[2]
option_quotes <- option_dataset$option_quotes[[2]]

option_quotes
#>         K      c      p
#>  1:  90.0 57.450     NA
#>  2:  95.0 52.475     NA
#>  3: 100.0 47.400     NA
#>  4: 105.0 42.450     NA
#>  5: 110.0 37.450     NA
#>  6: 115.0 32.500  0.025
#>  7: 116.0 31.500  0.035
#>  8: 117.0 30.500  0.035
#>  9: 118.0 29.500  0.035
#> 10: 119.0 28.500  0.040
#> 11: 120.0 27.500  0.040
#> 12: 121.0 26.500  0.040
#> 13: 122.0 25.525  0.050
#> 14: 123.0 24.525  0.050
#> 15: 124.0 23.525  0.060
#> 16: 125.0 22.525  0.070
#> 17: 126.0 21.550  0.070
#> 18: 127.0 20.525  0.080
#> 19: 128.0 19.575  0.090
#> 20: 129.0 18.425  0.095
#> 21: 130.0 17.525  0.110
#> 22: 131.0 16.500  0.130
#> 23: 132.0 15.500  0.150
#> 24: 133.0 14.550  0.170
#> 25: 134.0 13.575  0.195
#> 26: 135.0 12.625  0.230
#> 27: 136.0 11.625  0.270
#> 28: 137.0 10.700  0.315
#> 29: 138.0  9.775  0.380
#> 30: 139.0  8.850  0.460
#> 31: 140.0  7.925  0.555
#> 32: 141.0  7.050  0.665
#> 33: 142.0  6.200  0.815
#> 34: 143.0  5.400  0.990
#> 35: 144.0  4.625  1.215
#> 36: 145.0  3.875  1.480
#> 37: 146.0  3.225  1.810
#> 38: 147.0  2.655  2.230
#> 39: 148.0  2.110  2.700
#> 40: 149.0  1.675  3.275
#> 41: 150.0  1.295  3.900
#> 42: 152.5  0.620  5.800
#> 43: 155.0  0.300  7.925
#> 44: 157.5  0.150 10.300
#> 45: 160.0  0.090 12.725
#> 46: 162.5  0.060 15.150
#> 47: 165.0  0.040 17.600
#> 48: 167.5  0.025 20.200
#> 49: 170.0     NA 22.650
#> 50: 172.5     NA 25.150
#> 51: 175.0     NA 27.650
#> 52: 177.5     NA 30.150
#> 53: 180.0     NA 32.650
#> 54: 182.5     NA 35.150
#> 55: 185.0     NA 37.650
#> 56: 187.5     NA 40.150
#> 57: 190.0     NA 42.650
#> 58: 195.0     NA 47.650
#> 59: 200.0     NA 52.650
#> 60: 210.0     NA 62.575
#>         K      c      p
```

Next we calculate the Risk-Free-Rate R

``` r
library(lubridate)
#> 
#> Attache Paket: 'lubridate'
#> Die folgenden Objekte sind maskiert von 'package:base':
#> 
#>     date, intersect, setdiff, union
R <- interpolate_rfr(date = as_date(t),
                     exp = exp,
                     ret_table = F)
R
#> [1] 0.008476933
```

Calculate At-The-Money Forward Price F<sub>0</sub>

``` r
## Set expiration time to 4 PM
exp <- exp + hours(16)
## Calculate maturity in years
maturity <- time_length(exp-t,
                        unit = "years")
## Calculate ATM Forward
F_0 <- CBOE_F_0(option_quotes = option_quotes,
                R = R,
                maturity = maturity)
F_0
#> [1] 147.4251
```

Calculate At-The-Money Strike price K<sub>0</sub>

``` r
K_0 <- CBOE_K_0(option_quotes = option_quotes,
                F_0 = F_0)
K_0
#> [1] 147
```

Select option quotes per CBOE rule

``` r
option_quotes <- CBOE_option_selection(option_quotes = option_quotes,
                                       K_0 = K_0)
option_quotes
#>         K      c      p
#>  1: 115.0 32.500  0.025
#>  2: 116.0 31.500  0.035
#>  3: 117.0 30.500  0.035
#>  4: 118.0 29.500  0.035
#>  5: 119.0 28.500  0.040
#>  6: 120.0 27.500  0.040
#>  7: 121.0 26.500  0.040
#>  8: 122.0 25.525  0.050
#>  9: 123.0 24.525  0.050
#> 10: 124.0 23.525  0.060
#> 11: 125.0 22.525  0.070
#> 12: 126.0 21.550  0.070
#> 13: 127.0 20.525  0.080
#> 14: 128.0 19.575  0.090
#> 15: 129.0 18.425  0.095
#> 16: 130.0 17.525  0.110
#> 17: 131.0 16.500  0.130
#> 18: 132.0 15.500  0.150
#> 19: 133.0 14.550  0.170
#> 20: 134.0 13.575  0.195
#> 21: 135.0 12.625  0.230
#> 22: 136.0 11.625  0.270
#> 23: 137.0 10.700  0.315
#> 24: 138.0  9.775  0.380
#> 25: 139.0  8.850  0.460
#> 26: 140.0  7.925  0.555
#> 27: 141.0  7.050  0.665
#> 28: 142.0  6.200  0.815
#> 29: 143.0  5.400  0.990
#> 30: 144.0  4.625  1.215
#> 31: 145.0  3.875  1.480
#> 32: 146.0  3.225  1.810
#> 33: 147.0  2.655  2.230
#> 34: 148.0  2.110  2.700
#> 35: 149.0  1.675  3.275
#> 36: 150.0  1.295  3.900
#> 37: 152.5  0.620  5.800
#> 38: 155.0  0.300  7.925
#> 39: 157.5  0.150 10.300
#> 40: 160.0  0.090 12.725
#> 41: 162.5  0.060 15.150
#> 42: 165.0  0.040 17.600
#> 43: 167.5  0.025 20.200
#>         K      c      p
```

Calculate the Implied Variance σ<sup>2</sup>

``` r
sigma_sq <- CBOE_sigma_sq(sel_option_quotes = option_quotes,
                          K_0 = K_0,
                          F_0 = F_0,
                          maturity = maturity,
                          R = R)
sigma_sq
#> [1] 0.07567317
```

Do the same for a second maturity, this time all at once. This
observation will be our “next-term” contract.

``` r
## Select observation 5
t2 <- option_dataset$t[3]
exp2 <- option_dataset$exp[3]
option_quotes2 <- option_dataset$option_quotes[[3]]

## Risk free rate
R2 <- interpolate_rfr(date = as_date(t2),
                      exp = exp2,
                      ret_table = F)

## Set expiration time to 4 PM
exp2 <- exp2 + hours(16)
## Calculate maturity in years
maturity2 <- time_length(exp2-t2,unit = "years")

## Calculate all VIX vars at once
VIX_vars <- CBOE_VIX_vars(option_quotes = option_quotes2,
                          R = R2,
                          maturity = maturity2,
                          ret_vars = T)

VIX_vars
#> $F_0
#> [1] 147.4852
#> 
#> $K_0
#> [1] 147
#> 
#> $n_put_raw
#> [1] 31
#> 
#> $n_call_raw
#> [1] 11
#> 
#> $n_put
#> [1] 31
#> 
#> $n_call
#> [1] 11
#> 
#> $sigma_sq
#> [1] 0.06428081
```

Calculate and interpolate the VIX index from both maturities

``` r
CBOE_VIX_index(maturity = c(maturity, maturity2),
               sigma_sq = c(sigma_sq,VIX_vars$sigma_sq))
#> [1] 23.91272
```

Optionally calculate Option Descriptives, i.e. the strike price range
and spacing in standard-deviation (SD) units of the used option quotes:

``` r
price <- option_dataset$price[2]
option_descriptives(option_quotes = option_quotes,
                    K_0 = K_0,
                    R = R,
                    price = price,
                    maturity = maturity)
#> $SD
#> [1] 0.2516449
#> 
#> $max_K
#> [1] 167.5
#> 
#> $min_K
#> [1] 115
#> 
#> $mean_delta_K
#> [1] 1.25
#> 
#> $n_put
#> [1] 32
#> 
#> $n_call
#> [1] 10
```

## 2. Processing a whole dataset (using `data.table` and `future.apply`)

To speed up the calculations, we employ parallelised versions of the
`apply` family. However, you can still use the standard ones.

``` r
library(future.apply)
#> Lade nötiges Paket: future
plan(multisession, workers = 4) ## Parallelize using four cores
```

Determine the expiration terms for the interpolation. 1 indicates the
near-term, 2 the next-term option. We only keep those observations which
are relevant for the weekly and monthly VIX calculation.

``` r
## Determine maturity
option_dataset[, maturity := time_length((exp + hours(16) - t),unit = "years")]

## Weekly and monthly expiration terms
option_dataset[, `:=`(term_wk = future_sapply(maturity, CBOE_interpolation_terms,
                                              method = "weekly",
                                              future.seed = 1337),
                      term_mn = future_mapply(CBOE_interpolation_terms,
                                              maturity, as_date(t), as_date(exp),
                                              MoreArgs = list(method = "monthly"),
                                              future.seed = 1337)
)]
## Select only options needed for the weekly and monthly VIX
option_dataset <- option_dataset[!is.na(term_wk)
                                 | !is.na(term_mn)]

option_dataset
#>       ticker                   t        exp   price       option_quotes
#>    1:   AAAA 2017-06-13 09:31:00 2017-07-07 147.390  <data.table[51x3]>
#>    2:   AAAA 2017-06-13 09:31:00 2017-07-14 147.390  <data.table[40x3]>
#>    3:   AAAA 2017-06-13 09:31:00 2017-07-21 147.390  <data.table[42x3]>
#>    4:   AAAA 2017-06-13 09:31:00 2017-08-18 147.390  <data.table[61x3]>
#>    5:   AAAA 2017-06-13 09:32:00 2017-07-07 147.130  <data.table[51x3]>
#>   ---                                                                  
#> 3116:   BBBB 2017-06-13 15:59:00 2017-08-18 979.755  <data.table[92x3]>
#> 3117:   BBBB 2017-06-13 16:00:00 2017-07-07 980.805  <data.table[99x3]>
#> 3118:   BBBB 2017-06-13 16:00:00 2017-07-14 980.805  <data.table[65x3]>
#> 3119:   BBBB 2017-06-13 16:00:00 2017-07-21 980.805 <data.table[121x3]>
#> 3120:   BBBB 2017-06-13 16:00:00 2017-08-18 980.805  <data.table[92x3]>
#>         maturity term_wk term_mn
#>    1: 0.06644802       1      NA
#>    2: 0.08561297       2      NA
#>    3: 0.10477793      NA       1
#>    4: 0.18143775      NA       2
#>    5: 0.06644612       1      NA
#>   ---                           
#> 3116: 0.18070005      NA       2
#> 3117: 0.06570842       1      NA
#> 3118: 0.08487337       2      NA
#> 3119: 0.10403833      NA       1
#> 3120: 0.18069815      NA       2
```

Calculate the Implied Variances for a complete dataset

``` r
## Calculate risk-free-rate and maturity
option_dataset[, `:=`(R = interpolate_rfr(date = as_date(t),
                                          exp = exp))]

## Calculate CBOE MFIV for the whole dataset
option_dataset[, sigma_sq := future_mapply(CBOE_VIX_vars, option_quotes, R, maturity, future.seed = 1337)
               ]
option_dataset
#>       ticker                   t        exp   price       option_quotes
#>    1:   AAAA 2017-06-13 09:31:00 2017-07-07 147.390  <data.table[51x3]>
#>    2:   AAAA 2017-06-13 09:31:00 2017-07-14 147.390  <data.table[40x3]>
#>    3:   AAAA 2017-06-13 09:31:00 2017-07-21 147.390  <data.table[42x3]>
#>    4:   AAAA 2017-06-13 09:31:00 2017-08-18 147.390  <data.table[61x3]>
#>    5:   AAAA 2017-06-13 09:32:00 2017-07-07 147.130  <data.table[51x3]>
#>   ---                                                                  
#> 3116:   BBBB 2017-06-13 15:59:00 2017-08-18 979.755  <data.table[92x3]>
#> 3117:   BBBB 2017-06-13 16:00:00 2017-07-07 980.805  <data.table[99x3]>
#> 3118:   BBBB 2017-06-13 16:00:00 2017-07-14 980.805  <data.table[65x3]>
#> 3119:   BBBB 2017-06-13 16:00:00 2017-07-21 980.805 <data.table[121x3]>
#> 3120:   BBBB 2017-06-13 16:00:00 2017-08-18 980.805  <data.table[92x3]>
#>         maturity term_wk term_mn           R   sigma_sq
#>    1: 0.06644802       1      NA 0.008769736 0.05416683
#>    2: 0.08561297       2      NA 0.008911253 0.05222205
#>    3: 0.10477793      NA       1 0.009049549 0.05213150
#>    4: 0.18143775      NA       2 0.009571069 0.06150820
#>    5: 0.06644612       1      NA 0.008769736 0.05362052
#>   ---                                                  
#> 3116: 0.18070005      NA       2 0.009571069 0.07185948
#> 3117: 0.06570842       1      NA 0.008769736 0.04598859
#> 3118: 0.08487337       2      NA 0.008911253 0.04675662
#> 3119: 0.10403833      NA       1 0.009049549 0.04784626
#> 3120: 0.18069815      NA       2 0.009571069 0.07206823
```

Optionally, if you want to keep the intermediate variables:

``` r
## This function converts the mapply results below to a data.table
multicols <- function(matrix){
  data.table::as.data.table(t(matrix))[, lapply(.SD, unlist)]
}
```

``` r
## Calculate VIX for the whole dataset, including intermediate variables
option_dataset[, c("F_0", "K_0", "n_put_raw", "n_call_raw", "n_put", "n_call", "sigma_sq") := 
                 multicols(future_mapply(CBOE_VIX_vars,
                                         option_quotes, R, maturity,
                                         MoreArgs = list(ret_vars = T),
                                         future.seed = 1337)
                 )]
option_dataset
#>       ticker                   t        exp   price       option_quotes
#>    1:   AAAA 2017-06-13 09:31:00 2017-07-07 147.390  <data.table[51x3]>
#>    2:   AAAA 2017-06-13 09:31:00 2017-07-14 147.390  <data.table[40x3]>
#>    3:   AAAA 2017-06-13 09:31:00 2017-07-21 147.390  <data.table[42x3]>
#>    4:   AAAA 2017-06-13 09:31:00 2017-08-18 147.390  <data.table[61x3]>
#>    5:   AAAA 2017-06-13 09:32:00 2017-07-07 147.130  <data.table[51x3]>
#>   ---                                                                  
#> 3116:   BBBB 2017-06-13 15:59:00 2017-08-18 979.755  <data.table[92x3]>
#> 3117:   BBBB 2017-06-13 16:00:00 2017-07-07 980.805  <data.table[99x3]>
#> 3118:   BBBB 2017-06-13 16:00:00 2017-07-14 980.805  <data.table[65x3]>
#> 3119:   BBBB 2017-06-13 16:00:00 2017-07-21 980.805 <data.table[121x3]>
#> 3120:   BBBB 2017-06-13 16:00:00 2017-08-18 980.805  <data.table[92x3]>
#>         maturity term_wk term_mn           R   sigma_sq      F_0 K_0 n_put_raw
#>    1: 0.06644802       1      NA 0.008769736 0.05416683 147.5697 147        24
#>    2: 0.08561297       2      NA 0.008911253 0.05222205 147.5497 147        15
#>    3: 0.10477793      NA       1 0.009049549 0.05213150 147.5927 145         8
#>    4: 0.18143775      NA       2 0.009571069 0.06150820 147.4042 145         9
#>    5: 0.06644612       1      NA 0.008769736 0.05362052 147.2551 147        24
#>   ---                                                                         
#> 3116: 0.18070005      NA       2 0.009571069 0.07185948 982.6045 980        52
#> 3117: 0.06570842       1      NA 0.008769736 0.04598859 981.3243 980        43
#> 3118: 0.08487337       2      NA 0.008911253 0.04675662 982.0747 980        25
#> 3119: 0.10403833      NA       1 0.009049549 0.04784626 982.4523 980        50
#> 3120: 0.18069815      NA       2 0.009571069 0.07206823 983.2470 980        52
#>       n_call_raw n_put n_call
#>    1:         10    24     10
#>    2:         14    15     14
#>    3:          9     8      9
#>    4:         11     9     11
#>    5:         10    24     10
#>   ---                        
#> 3116:         38    52     38
#> 3117:         52    43     52
#> 3118:         34    25     34
#> 3119:         22    47     22
#> 3120:         38    52     38
```

Calculate the VIX indices

``` r
## Weekly VIX
weekly <- option_dataset[!is.na(term_wk)][, .(VIX_wk = CBOE_VIX_index(maturity = maturity,
                                                                      sigma_sq = sigma_sq)),
                                          by = .(ticker, t)]

## Monthly VIX
monthly <- option_dataset[!is.na(term_mn)][, .(VIX_mn = CBOE_VIX_index(maturity = maturity,
                                                                       sigma_sq = sigma_sq)),
                                           by = .(ticker, t)]

VIX_data <- weekly[monthly, on = .(ticker, t)]

VIX_data
#>      ticker                   t   VIX_wk   VIX_mn
#>   1:   AAAA 2017-06-13 09:31:00 22.91347 21.45530
#>   2:   AAAA 2017-06-13 09:32:00 22.84365 21.17519
#>   3:   AAAA 2017-06-13 09:33:00 22.78820 21.13499
#>   4:   AAAA 2017-06-13 09:34:00 22.75515 21.11951
#>   5:   AAAA 2017-06-13 09:35:00 22.75988 21.05913
#>  ---                                             
#> 776:   BBBB 2017-06-13 15:56:00 21.46799 18.35661
#> 777:   BBBB 2017-06-13 15:57:00 21.45854 18.36722
#> 778:   BBBB 2017-06-13 15:58:00 21.44498 18.38045
#> 779:   BBBB 2017-06-13 15:59:00 21.50976 18.45417
#> 780:   BBBB 2017-06-13 16:00:00 21.60340 18.07499
```

## 3. Visualise the VIX-Index

Display the data

``` r
plot_VIX(VIX_data)
```

<img src="man/figures/README-unnamed-chunk-18-1.png" width="100%" />

**You can use `result_browser(VIX_data)` to display an interactive Shiny
App that allows to browse through the results**

## 4. Analyse the Option-Data Quality

Calculate descriptive variables for the option-data quality

``` r
## Calculate the option descriptives using the `multicols()` function from above
option_dataset[, c("SD", "max_K", "min_K", "mean_delta_K", "n_put", "n_call") := 
                 multicols(future_mapply(option_descriptives,
                                         option_quotes, K_0, R, price, maturity)
                 )]
option_dataset
#>       ticker                   t        exp   price       option_quotes
#>    1:   AAAA 2017-06-13 09:31:00 2017-07-07 147.390  <data.table[51x3]>
#>    2:   AAAA 2017-06-13 09:31:00 2017-07-14 147.390  <data.table[40x3]>
#>    3:   AAAA 2017-06-13 09:31:00 2017-07-21 147.390  <data.table[42x3]>
#>    4:   AAAA 2017-06-13 09:31:00 2017-08-18 147.390  <data.table[61x3]>
#>    5:   AAAA 2017-06-13 09:32:00 2017-07-07 147.130  <data.table[51x3]>
#>   ---                                                                  
#> 3116:   BBBB 2017-06-13 15:59:00 2017-08-18 979.755  <data.table[92x3]>
#> 3117:   BBBB 2017-06-13 16:00:00 2017-07-07 980.805  <data.table[99x3]>
#> 3118:   BBBB 2017-06-13 16:00:00 2017-07-14 980.805  <data.table[65x3]>
#> 3119:   BBBB 2017-06-13 16:00:00 2017-07-21 980.805 <data.table[121x3]>
#> 3120:   BBBB 2017-06-13 16:00:00 2017-08-18 980.805  <data.table[92x3]>
#>         maturity term_wk term_mn           R   sigma_sq      F_0 K_0 n_put_raw
#>    1: 0.06644802       1      NA 0.008769736 0.05416683 147.5697 147        24
#>    2: 0.08561297       2      NA 0.008911253 0.05222205 147.5497 147        15
#>    3: 0.10477793      NA       1 0.009049549 0.05213150 147.5927 145         8
#>    4: 0.18143775      NA       2 0.009571069 0.06150820 147.4042 145         9
#>    5: 0.06644612       1      NA 0.008769736 0.05362052 147.2551 147        24
#>   ---                                                                         
#> 3116: 0.18070005      NA       2 0.009571069 0.07185948 982.6045 980        52
#> 3117: 0.06570842       1      NA 0.008769736 0.04598859 981.3243 980        43
#> 3118: 0.08487337       2      NA 0.008911253 0.04675662 982.0747 980        25
#> 3119: 0.10403833      NA       1 0.009049549 0.04784626 982.4523 980        50
#> 3120: 0.18069815      NA       2 0.009571069 0.07206823 983.2470 980        52
#>       n_call_raw n_put n_call        SD  max_K min_K mean_delta_K
#>    1:         10    24     10 0.2218317  167.5   123     1.308824
#>    2:         14    15     14 0.2189827  177.5   115     2.155172
#>    3:          9     8      9 0.2196033  190.0   100     5.294118
#>    4:         11     9     11 0.2395117  200.0   100     5.000000
#>    5:         10    24     10 0.2208317  167.5   123     1.308824
#>   ---                                                            
#> 3116:         38    52     38 0.2695806 1400.0   720     7.555556
#> 3117:         52    43     52 0.2037625 1140.0   790     3.684211
#> 3118:         34    25     34 0.2050042 1130.0   800     5.593220
#> 3119:         22    50     22 0.2152011 1200.0   650     7.638889
#> 3120:         38    52     38 0.2670286 1400.0   720     7.555556
```

## 5. Improve Option-Data Quality using Smooting Methods

``` r
## Use the Jiang & Tian (2007) smoothing method to fill in and extrapolate the option quotes.
option_dataset[, option_quotes_smooth := future_mapply(JandT_2007_smoothing_method,
                                                       option_quotes, K_0, price, R, maturity, F_0,
                                                       SIMPLIFY = F)]

option_dataset
#>       ticker                   t        exp   price       option_quotes
#>    1:   AAAA 2017-06-13 09:31:00 2017-07-07 147.390  <data.table[51x3]>
#>    2:   AAAA 2017-06-13 09:31:00 2017-07-14 147.390  <data.table[40x3]>
#>    3:   AAAA 2017-06-13 09:31:00 2017-07-21 147.390  <data.table[42x3]>
#>    4:   AAAA 2017-06-13 09:31:00 2017-08-18 147.390  <data.table[61x3]>
#>    5:   AAAA 2017-06-13 09:32:00 2017-07-07 147.130  <data.table[51x3]>
#>   ---                                                                  
#> 3116:   BBBB 2017-06-13 15:59:00 2017-08-18 979.755  <data.table[92x3]>
#> 3117:   BBBB 2017-06-13 16:00:00 2017-07-07 980.805  <data.table[99x3]>
#> 3118:   BBBB 2017-06-13 16:00:00 2017-07-14 980.805  <data.table[65x3]>
#> 3119:   BBBB 2017-06-13 16:00:00 2017-07-21 980.805 <data.table[121x3]>
#> 3120:   BBBB 2017-06-13 16:00:00 2017-08-18 980.805  <data.table[92x3]>
#>         maturity term_wk term_mn           R   sigma_sq      F_0 K_0 n_put_raw
#>    1: 0.06644802       1      NA 0.008769736 0.05416683 147.5697 147        24
#>    2: 0.08561297       2      NA 0.008911253 0.05222205 147.5497 147        15
#>    3: 0.10477793      NA       1 0.009049549 0.05213150 147.5927 145         8
#>    4: 0.18143775      NA       2 0.009571069 0.06150820 147.4042 145         9
#>    5: 0.06644612       1      NA 0.008769736 0.05362052 147.2551 147        24
#>   ---                                                                         
#> 3116: 0.18070005      NA       2 0.009571069 0.07185948 982.6045 980        52
#> 3117: 0.06570842       1      NA 0.008769736 0.04598859 981.3243 980        43
#> 3118: 0.08487337       2      NA 0.008911253 0.04675662 982.0747 980        25
#> 3119: 0.10403833      NA       1 0.009049549 0.04784626 982.4523 980        50
#> 3120: 0.18069815      NA       2 0.009571069 0.07206823 983.2470 980        52
#>       n_call_raw n_put n_call        SD  max_K min_K mean_delta_K
#>    1:         10    24     10 0.2218317  167.5   123     1.308824
#>    2:         14    15     14 0.2189827  177.5   115     2.155172
#>    3:          9     8      9 0.2196033  190.0   100     5.294118
#>    4:         11     9     11 0.2395117  200.0   100     5.000000
#>    5:         10    24     10 0.2208317  167.5   123     1.308824
#>   ---                                                            
#> 3116:         38    52     38 0.2695806 1400.0   720     7.555556
#> 3117:         52    43     52 0.2037625 1140.0   790     3.684211
#> 3118:         34    25     34 0.2050042 1130.0   800     5.593220
#> 3119:         22    50     22 0.2152011 1200.0   650     7.638889
#> 3120:         38    52     38 0.2670286 1400.0   720     7.555556
#>       option_quotes_smooth
#>    1:  <data.table[244x2]>
#>    2:  <data.table[268x2]>
#>    3:   <data.table[99x2]>
#>    4:  <data.table[148x2]>
#>    5:  <data.table[242x2]>
#>   ---                     
#> 3116:  <data.table[511x2]>
#> 3117:  <data.table[595x2]>
#> 3118:  <data.table[687x2]>
#> 3119:  <data.table[383x2]>
#> 3120:  <data.table[512x2]>
```

Let’s look at one nest of smoothed `option_quotes`

``` r
## Calculate the option descriptives using the `multicols()` function from above
smooth_quotes <- option_dataset$option_quotes_smooth[[1]]

min(smooth_quotes$K)
#> [1] 26
max(smooth_quotes$K)
#> [1] 269
length(smooth_quotes$K)
#> [1] 244
## Average spacing in price units
mean(smooth_quotes$K - data.table::shift(smooth_quotes$K), na.rm = T)
#> [1] 1

## Spacing in SD units
3 / (option_dataset$SD[[1]] * option_dataset$price[[1]] * sqrt(option_dataset$maturity[[1]]))
#> [1] 0.3559497
```

Now calculate the MFIV using the Jiang & Tian (2007) method:

``` r
option_dataset[, sigma_sq_smooth := future_mapply(JandT_2007_sigma_sq,
                                                  option_quotes_smooth, K_0, maturity, R)]
```

Calculate the respective VIX indices

``` r
## Weekly VIX
weekly_smooth <- option_dataset[!is.na(term_wk)][, .(VIX_wk_smooth = CBOE_VIX_index(maturity = maturity,
                                                                                    sigma_sq = sigma_sq_smooth)),
                                                 by = .(ticker, t)]

## Monthly VIX
monthly_smooth <- option_dataset[!is.na(term_mn)][, .(VIX_mn_smooth = CBOE_VIX_index(maturity = maturity,
                                                                                     sigma_sq = sigma_sq_smooth)),
                                                  by = .(ticker, t)]

VIX_data_smooth <- weekly_smooth[monthly_smooth, on = .(ticker, t)]

VIX_data_2 <- VIX_data[VIX_data_smooth, on = .(ticker, t)]

plot_VIX(data = VIX_data_2,
         VIX_vars = c("VIX_wk", "VIX_mn",
                      "VIX_wk_smooth", "VIX_mn_smooth"))
```

<img src="man/figures/README-unnamed-chunk-23-1.png" width="100%" />
