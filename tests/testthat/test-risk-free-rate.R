test_that("scrape_cmt_data() works", {
  ## Download 2019 CMT data
  cmt <- scrape_cmt_data("https://home.treasury.gov/resource-center/data-chart-center/interest-rates/daily-treasury-rates.csv/2019/all?type=daily_treasury_yield_curve&field_tdr_date_value=2019&page&_format=csv")

  # ## SAVE DATA
  # saveRDS(cmt, "tests/testthat/correct_cmt")

  ## READ THE CORRECTDATA
  correct_cmt <- readRDS("correct_cmt")

  testthat::expect_equal(cmt, correct_cmt)
})

test_that("interpolate_rfr() calculates single values", {

  testthat::expect_equal(interpolate_rfr(date = lubridate::ymd("2020-01-02"),
                                         exp = lubridate::date("2020-03-02")),
                         0.01550038647613796)

})

test_that("interpolate_rfr() calculates multiple values", {

  dates <- lubridate::ymd("2020-01-06") + lubridate::days(1:4)
  exps <-  lubridate::ymd("2020-03-02") + lubridate::days(1:4)

  testthat::expect_equal(interpolate_rfr(date = dates, exp = exps),
                         c(0.015283742686531815,
                           0.015269685941365858,
                           0.015497723196530864,
                           0.015490167307057169))

})

test_that("interpolate_rfr() calculates multiple values", {

  dates <- lubridate::ymd("2020-01-06") + lubridate::days(1:4)
  exps <-  lubridate::ymd("2020-03-02") + lubridate::days(1:4)

  rfr <- interpolate_rfr(date = dates, exp = exps, ret_table = T)

  ## SAVE DATA
  # saveRDS(rfr, "tests/testthat/correct_rfr")

  ## READ THE CORRECTDATA
  correct_rfr <- readRDS("correct_rfr")

  testthat::expect_equal(rfr,
                         correct_rfr)

})

test_that("interpolate_rfr() errors when dates are not in cmt_data", {
  testthat::expect_error(interpolate_rfr(date = lubridate::ymd("2020-01-01"),
                                         exp = lubridate::date("2020-03-02")
  ))

  testthat::expect_error(interpolate_rfr(cmt_data = R.MFIV::cmt_dataset[1:10,],
                                         date = lubridate::ymd("2020-01-01"),
                                         exp = lubridate::date("2020-03-02")
  ))
})
