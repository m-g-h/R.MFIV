## code to prepare `cmt_dataset` dataset goes here

cmt_dataset <- R.MFIV::scrape_cmt_data()

usethis::use_data(cmt_dataset, overwrite = TRUE)

