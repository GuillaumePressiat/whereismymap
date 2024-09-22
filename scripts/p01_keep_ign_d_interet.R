

library(magrittr)
library(archive)


copy_files <- function(from, to) {
  dest_name <- basename(from)
  file.rename(from, file.path('raw_data/ign_admin_express', dest_name))
}


archive::archive_extract('raw_data/ign_admin_express/ign_admin_express.7z',
                         'raw_data/ign_admin_express/')

ign_extract <- list.files('raw_data/ign_admin_express', recursive = TRUE, full.names = TRUE) %>%
  .[grepl('\\/(COMMUNE|DEPARTEMENT)\\.', .)]

ign_extract %>%
  copy_files()

list.files('raw_data/ign_admin_express/') %>%
  .[grepl('ADMIN-EXPRESS', .)] %>%
  file.path('raw_data/ign_admin_express', .) %>%
  unlink(recursive = TRUE)
