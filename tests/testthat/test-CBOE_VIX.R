test_that("CBOE_option_selection() works", {
  ## CREATE MOCK CALL AND PUT QUOTES
  calls <- 16:1
  puts  <- 1:16

  ## FUNCTION TO SET INDIVIDUAL VALUES TO NA
  set_NA <- function(indices, vector, rev = F){
    if(rev){
      vector <- rev(vector)
    }

    vector[indices] <- NA

    if(rev){
      rev(vector)
    } else {
      vector
    }
  }

  ## ALL COMBINATIONS OF POSSIBLE MISSING VALUES
  na_list <- list(0,
                  c(1:2),
                  c(1:2, 4),
                  c(1:2, 4:5),
                  c(4:5),
                  c(2:3, 5:6),
                  c(2, 5:6),
                  c(1:2, 4, 6:7 ))

  ## CREATE INDIVIDUAL CALL AND PUT VECTORS
  puts_NA <- purrr::map(.x = na_list,
                        .f = set_NA,
                        puts,
                        rev = F)
  calls_NA <- purrr::map(.x = na_list,
                         .f = set_NA,
                         calls,
                         rev = T)

  ## CREATE THE CORRECT PUT AND CALL VECTORS AFTER SELECTION

  na_list_cor <- list(0,
                      c(1:2),
                      c(1:2, 4),
                      c(1:5),
                      c(1:5),
                      c(1:6),
                      c(1:6),
                      c(1:7))
  cor_puts_NA <- purrr::map(.x = na_list_cor,
                            .f = set_NA,
                            puts,
                            rev = F)
  cor_calls_NA <- purrr::map(.x = na_list_cor,
                             .f = set_NA,
                             calls,
                             rev = T)

  ## CROSS THE TEST VECTORS
  crossed_NA <- tidyr::expand_grid(calls_NA, puts_NA)

  df_NA <- purrr::map2_dfr(crossed_NA, 1:length(crossed_NA),
                           .f = ~data.table::data.table(index = .y,
                                                        K = 1:16,
                                                        c = .x[[1]],
                                                        p = .x[[2]]))
  nest_NA <- df_NA[, .(nest = list(.SD)),
                   by = index]

  ## CROSS THE CORRECT VECTORS
  cor_crossed_NA <- tidyr::expand_grid(cor_calls_NA, cor_puts_NA)

  cor_df_NA <- purrr::map2_dfr(cor_crossed_NA, 1:length(cor_crossed_NA),
                               .f = ~data.table::data.table(index = .y,
                                                            K = 1:16,
                                                            c = .x[[1]],
                                                            p = .x[[2]]))

  cor_nest_NA <- cor_df_NA[!is.na(c)
  ][!is.na(p)
  ][, .(cor_nest = list(.SD)),
    by = index]

  ## MERGE TEST AND CORRECT DATA
  testdata <- nest_NA[cor_nest_NA, on = .(index = index)]

  ## SELECT OPTIONS VIA CBOE RULE
  testdata[, sel_nest := list(list(CBOE_option_selection(nest[[1]], 7))),
           by = index]

  ## ARE THE RESULTS CORRESPONDING?
  testdata[, test := all.equal(cor_nest[[1]], sel_nest[[1]]),
           by = index]

  testthat::expect_equal(mean(testdata$test), 1)
})

test_that("CBOE_delta_K() works", {

  strikes <- c(10, 12.5, c(1:10)*5 + 10, 62.5, 65)

  testthat::expect_equal(CBOE_delta_K(K = strikes),
                         c(2.50, 2.50, 3.75, 5.00, 5.00, 5.00, 5.00, 5.00, 5.00, 5.00, 5.00, 3.75, 2.50, 2.50))
})

test_that("CBOE_F_0() works", {
  testthat::expect_equal(CBOE_F_0(option_quotes = option_dataset$option_quotes[[1]],
                                  R = 0.005,
                                  maturity = 0.07),
                         147.40514177480915)
})

test_that("CBOE_K_0() works", {
  ## JUST NORMAL CALCULATION
  testthat::expect_equal(CBOE_K_0(option_quotes = option_dataset$option_quotes[[1]],
                                  F_0 = 147.5),
                         147)
  ## p is NA
  nest_1 <- option_dataset$option_quotes[[1]]
  nest_1[K == 147]$p <- NA
  testthat::expect_equal(CBOE_K_0(option_quotes = nest_1,
                                  F_0 = 147.5),
                         NA)
  ## c is NA
  nest_2 <- option_dataset$option_quotes[[1]]
  nest_2[K == 147]$c <- NA
  testthat::expect_equal(CBOE_K_0(option_quotes = nest_2,
                                  F_0 = 147.5),
                         NA)
})

test_that("CBOE_sigma_sq() works", {

  sel_option_quotes <- CBOE_option_selection(option_dataset$option_quotes[[1]],
                                             147)

  testthat::expect_equal(CBOE_sigma_sq(sel_option_quotes = sel_option_quotes,
                                       K_0 = 147,
                                       F_0 = 147.5,
                                       maturity = 0.07,
                                       R = 0.005),
                         0.014171619562701705)
})
test_that("CBOE_VIX_vars() works", {
  nest <- option_dataset$option_quotes[[1]]

  ## SINGLE RESULT
  testthat::expect_equal(CBOE_VIX_vars(option_quotes = nest,
                                       R = 0.005,
                                       maturity = 0.07,
                                       ret_vars = F),
                         0.014228381720205173)
  ## LIST RESULT

  VIX_vars <- CBOE_VIX_vars(option_quotes = nest,
                            R = 0.005,
                            maturity = 0.07,
                            ret_vars = T)

  # ## SAVE RESULTS
  # saveRDS(VIX_vars, "tests/testthat/cor_VIX_vars")

  ## LOAD RESULTS
  cor_VIX_vars <- readRDS("cor_VIX_vars")

  testthat::expect_equal(VIX_vars,
                         cor_VIX_vars)
})

test_that("CBOE_VIX_vars() warnings work", {

  ## FIRST WARNING
  nest_1 <- option_dataset$option_quotes[[1]][1,]

  ## IS A NA VALUE RETURNED?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_1,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = F)),
                         NA)
  ## IS A LIST OF NA VALUES RETURNED FOR ret_vars = T?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_1,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = T)),
                         list("F_0" = NA,
                              "K_0" = NA,
                              "n_put_raw" = NA,
                              "n_call_raw" = NA,
                              "n_put" = NA,
                              "n_call" = NA,
                              "sigma_sq" = NA))

  ## IS IT THE FIRST WARNING MESSAGE?
  testthat::expect_warning(CBOE_VIX_vars(option_quotes = nest_1,
                                         R = 0.005,
                                         maturity = 0.07,
                                         ret_vars = F),
                           regexp = "There were less than two quotes in")

  ## SECOND WARNING
  nest_2 <- option_dataset$option_quotes[[1]][1:2,]

  ## IS A NA VALUE RETURNED?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_2,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = F)),
                         NA)
  ## IS A LIST OF NA VALUES RETURNED FOR ret_vars = T?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_2,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = T)),
                         list("F_0" = NA,
                              "K_0" = NA,
                              "n_put_raw" = NA,
                              "n_call_raw" = NA,
                              "n_put" = NA,
                              "n_call" = NA,
                              "sigma_sq" = NA))

  ## IS IT THE SECOND WARNING MESSAGE?
  testthat::expect_warning(CBOE_VIX_vars(option_quotes = nest_2,
                                         R = 0.005,
                                         maturity = 0.07,
                                         ret_vars = F),
                           regexp = "Could not calculate")


  ## THIRD WARNING
  nest_3 <- option_dataset$option_quotes[[1]][32:37,]

  ## IS A NA VALUE RETURNED?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_3,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = F)),
                         NA)
  ## IS A LIST OF NA VALUES RETURNED FOR ret_vars = T?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_3,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = T)),
                         list("F_0" = 147.38783437093494,
                              "K_0" = 125,
                              "n_put_raw" = 3,
                              "n_call_raw" = 0,
                              "n_put" = NA,
                              "n_call" = NA,
                              "sigma_sq" = NA))

  ## IS IT THE THIRD WARNING MESSAGE?
  testthat::expect_warning(CBOE_VIX_vars(option_quotes = nest_3,
                                         R = 0.005,
                                         maturity = 0.07,
                                         ret_vars = F),
                           regexp = "There were no put / call quotes in")



  ## FOURTH WARNING FOR CALLS
  nest_4 <- option_dataset$option_quotes[[1]]
  nest_4$c[60:61] <- NA

  ## IS A NA VALUE RETURNED?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_4,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = F)),
                         NA)
  ## IS A LIST OF NA VALUES RETURNED FOR ret_vars = T?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_4,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = T)),
                         list("F_0" = 147.40514177480915,
                              "K_0" = 147,
                              "n_put_raw" = 24,
                              "n_call_raw" = 6,
                              "n_put" = 24,
                              "n_call" = 0,
                              "sigma_sq" = NA))

  ## IS IT THE FOURTH WARNING MESSAGE ?
  testthat::expect_warning(CBOE_VIX_vars(option_quotes = nest_4,
                                         R = 0.005,
                                         maturity = 0.07,
                                         ret_vars = F),
                           regexp = "after selecting by the CBOE rule")

  ## FOURTH WARNING FOR PUTS
  nest_5 <- option_dataset$option_quotes[[1]]
  nest_5$p[58:57] <- NA

  ## IS A NA VALUE RETURNED?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_5,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = F)),
                         NA)
  ## IS A LIST OF NA VALUES RETURNED FOR ret_vars = T?
  testthat::expect_equal(suppressWarnings(CBOE_VIX_vars(option_quotes = nest_5,
                                                        R = 0.005,
                                                        maturity = 0.07,
                                                        ret_vars = T)),
                         list("F_0" = 147.40514177480915,
                              "K_0" = 147,
                              "n_put_raw" = 22,
                              "n_call_raw" = 8,
                              "n_put" = 0,
                              "n_call" = 8,
                              "sigma_sq" = NA))

  ## IS IT THE FOURTH WARNING MESSAGE ?
  testthat::expect_warning(CBOE_VIX_vars(option_quotes = nest_5,
                                         R = 0.005,
                                         maturity = 0.07,
                                         ret_vars = F),
                           regexp = "after selecting by the CBOE rule")
})

test_that("CBOE_interpolation_terms() works", {
  ##  WEEKLY
  vals <- c(22.9, 23, 23.1,
            29.9, 30, 30.1,
            36.9, 37, 37.1)/365
  res_wk <- numeric()
  for (i in vals) {
    res_wk <- c(res_wk, CBOE_interpolation_terms(maturity = i, method = "weekly"))
  }
  testthat::expect_equal(res_wk, c(NA, NA,1, 1, 1, 2, 2, 2, NA))

  ## MONTHLY

  ## 2020-17-01 is first, 2020-02-21 is second, 2020-03-20, is third 2020-04-17 is fourth valid friday
  t <- lubridate::ymd("2020-01-09", # 17th is near-term, 21st next-term, 20th NA
                      "2020-01-10", # 17th is NA,        21st near-term, 20th next-term
                      "2020-01-11", # 17th is NA,        21st near-term, 20th next-term
                      "2020-02-13", # 17th is NA,        21st near-term, 20th next-term
                      "2020-02-14") # 21st is NA,        20th near-term, 17th next-term
  exp <- lubridate::ymd("2020-01-24", # invalid friday, always NA
                        "2020-01-17",
                        "2020-02-21",
                        "2020-03-20",
                        "2020-04-17")

  res_mn <- numeric()
  for (i in 1:length(t)) {
    for (j in 1:length(exp)) {
      res_mn <- c(res_mn,
                  CBOE_interpolation_terms(date_t = t[i],
                                           date_exp = exp[j],
                                           method = "monthly")
      )
    }
  }
  testthat::expect_equal(res_mn, c(NA, 1, 2, NA, NA,
                                   NA, NA, 1, 2, NA,
                                   NA, NA, 1, 2, NA,
                                   NA, NA, 1, 2, NA,
                                   NA, NA, NA, 1, 2))

  ## Test special Case that threw an error in practice
  testthat::expect_equal(CBOE_interpolation_terms(date_t = lubridate::ymd("2017-02-09"),
                           date_exp = lubridate::ymd("2017-03-31"),
                           method = "monthly"),
                         NA_integer_)

})

test_that("CBOE_VIX_index() works", {
  ## TEST ERROR MESSAGES
  testthat::expect_error(CBOE_VIX_index(maturity = 1, sigma_sq = c(1,2)))
  testthat::expect_error(CBOE_VIX_index(maturity = c(1,2), sigma_sq = 1))
  testthat::expect_error(CBOE_VIX_index(maturity = 1, sigma_sq = 1))

  ## NORMAL CALCULATION (INTRAPOLATION)
  testthat::expect_equal(CBOE_VIX_index(maturity = c(0.074, 0.09),
                                        sigma_sq = c(0.3, 0.5)),
                         64.196962544967803)
  ## NORMAL CALCULATION (EXTRAPOLATION)
  testthat::expect_equal(CBOE_VIX_index(maturity = c(0.09, 0.12),
                                        sigma_sq = c(0.3, 0.5)),
                         47.328638264796922)
})
