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
