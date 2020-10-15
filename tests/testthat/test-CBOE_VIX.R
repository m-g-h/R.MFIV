test_that("CBOE_option_selection() works", {
  ## CREATE MOCK CALL AND PUT QUOTES
  calls <- 14:1
  puts  <- 1:14

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
                  c(2:3, 5:6))

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
                      c(1:6))
  cor_puts_NA <- purrr::map(.x = na_list_cor,
                            .f = set_NA,
                            puts,
                            rev = F)
  cor_calls_NA <- purrr::map(.x = na_list_cor,
                             .f = set_NA,
                             calls,
                             rev = T)

  ## CROSS THE TEST VECTORS
  crossed_NA <- purrr::cross2(calls_NA, puts_NA)

  df_NA <- purrr::map2_dfr(crossed_NA, 1:length(crossed_NA),
                           .f = ~data.table::data.table(index = .y,
                                                        K = 1:14,
                                                        c = .x[[1]],
                                                        p = .x[[2]]))
  nest_NA <- df_NA[, .(nest = list(.SD)),
                   by = index]

  ## CROSS THE CORRECT VECTORS
  cor_crossed_NA <- purrr::cross2(cor_calls_NA, cor_puts_NA)

  cor_df_NA <- purrr::map2_dfr(cor_crossed_NA, 1:length(cor_crossed_NA),
                               .f = ~data.table::data.table(index = .y,
                                                            K = 1:14,
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
  testthat::expect_equal(CBOE_K_0(option_quotes = option_dataset$option_quotes[[1]],
                                  F_0 = 147.5),
                         147)
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
