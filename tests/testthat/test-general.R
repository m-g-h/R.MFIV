test_that("option_descriptives() works", {
  nest <- option_dataset$option_quotes[[1]]

  ## CALCULATE DESCRIPTIVES
  desc <- option_descriptives(option_quotes = nest,
                              K_0 = 147,
                              R = 0.005,
                              price = 147,
                              maturity = 0.07)

  # ## SAVE DATA
  # saveRDS(desc, "tests/testthat/cor_desc")

  ## LOAD DATA
  cor_desc <- readRDS("cor_desc")

  testthat::expect_equal(desc, cor_desc)
})

test_that("third_fridays() works", {
  start <- lubridate::ymd("2018-11-01")
  end <- lubridate::ymd("2020-01-01")

  fridays <- third_fridays(start, end)

  # ## SAVE DATA
  # saveRDS(fridays, "tests/testthat/cor_fridays")

  ## LOAD DATA
  cor_fridays <- readRDS("cor_fridays")

  testthat::expect_equal(fridays, cor_fridays)
})
