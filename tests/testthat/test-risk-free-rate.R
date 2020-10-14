test_that("CMT Scraping works", {
  ## Download 2019 CMT data
  cmt <- scrape_cmt_data("https://www.treasury.gov/resource-center/data-chart-center/interest-rates/pages/TextView.aspx?data=yieldYear&year=2019")

  # ## SAVE DATA
  # saveRDS(cmt, "tests/testthat/correct_cmt")

  ## READ THE CORRECTDATA
  correct_cmt <- readRDS("correct_cmt")

  testthat::expect_equal(cmt, correct_cmt)
})
