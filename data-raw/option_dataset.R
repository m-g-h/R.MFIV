## code to prepare `option_dataset` dataset goes here
price_data <- data.table::fread("data-raw/example_pricedata.csv")

option_dataset <- price_data[, .(option_quotes = list(.SD)),
                     by = .(ticker, t, exp, price=Price)]

usethis::use_data(option_dataset, overwrite = TRUE)
