

ressources <- list(
  list(url = 'https://www.data.gouv.fr/fr/datasets/r/2f75293b-3ee5-4cb5-971b-93e754dc96ea',
       nom = 'laposte_hexamal',
       extension = '.csv'),
  list(url = 'https://data.geopf.fr/telechargement/download/ADMIN-EXPRESS-COG-CARTO/ADMIN-EXPRESS-COG-CARTO_3-2__SHP_WGS84G_FRA_2024-02-22/ADMIN-EXPRESS-COG-CARTO_3-2__SHP_WGS84G_FRA_2024-02-22.7z',
       nom = 'ign_admin_express_cog_carto',
       extension = '.7z')
)

r <- ressources[[2]]

download_ressources <- function(r) {
  dir.create(file.path('raw_data/', r$nom), showWarnings = FALSE)

  outfile <- file.path('raw_data/', r$nom, paste0(r$nom, r$extension))

  download.file(r$url, outfile)
}

