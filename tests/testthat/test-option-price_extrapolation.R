test_that("mJandT_2007_smoothing_method() works", {
  ## LOAD EXAMPLE OPTION_QUOTES
  nest <- option_dataset$option_quotes[[1]]

  ## EXTRAPOLATE DATA
  extra_data <- JandT_2007_smoothing_method(option_quotes = nest,
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
