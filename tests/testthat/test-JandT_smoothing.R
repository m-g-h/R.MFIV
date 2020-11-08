test_that("mJandT_2007_smoothing_method() works", {
  ## LOAD EXAMPLE OPTION_QUOTES
  nest <- R.MFIV::option_dataset$option_quotes[[1]]

  ## EXTRAPOLATE DATA
  # Parameters:
  tail_length <- c(3.5, 15)
  flat_tails <- c(T, F)
  increment <- c("min", "JT", "real", 0.5)

  params <- purrr::reduce(.x = purrr::cross3(tail_length, flat_tails, increment),
                          .f = rbind)
  rownames(params) <- NULL

  runfun <- function(option_quotes, K_0, price, R, maturity, F_0,
                     tail_length, flat_tails, increment){

    if(increment == "0.5"){
      increment <- 0.5
    }
    ## RUN FUNCTION
    JandT_2007_smoothing_method(option_quotes, K_0, price, R, maturity, F_0,
                                tail_length, flat_tails, increment)
  }

  extra_data <- purrr::pmap(.l = list("tail_length" = params[,1],
                                      "flat_tails" = params[,2],
                                      "increment" = params[,3]),
                            .f = runfun,
                            option_quotes = nest,
                            maturity = 0.008953152,
                            K_0 = 147,
                            price = 147.39,
                            R = 0.008325593,
                            F_0 = 147.405)
  # ## SAVE RESULTS
  # saveRDS(extra_data, "tests/testthat/cor_extra_data")

  ## LOAD RESULTS
  cor_extra_data <- readRDS("cor_extra_data")

  testthat::expect_equal(extra_data,
                         cor_extra_data)

})

test_that("JandT_sigma_sq() works", {
  ## LOAD EXAMPLE OPTION_QUOTES
  nest <- option_dataset$option_quotes[[1]]

  ## EXTRAPOLATE DATA
  smooth_nest <- JandT_2007_smoothing_method(option_quotes = nest,
                                             maturity = 0.008953152,
                                             K_0 = 147,
                                             price = 147.39,
                                             R = 0.008325593,
                                             F_0 = 147.405)
  ## CALCULATE MFIV
  sigma_sq <- JandT_2007_sigma_sq(smooth_option_quotes = smooth_nest,
                      K_0 = 147,
                      maturity = 0.008953152,
                      R = 0.008325593)

  testthat::expect_equal(sigma_sq,
                         0.10915304449629359)
})
