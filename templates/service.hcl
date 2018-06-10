max_stale = "2m"

template {
  source = "/root/templates/DBMA_CONFIG.DB.template"
  destination = "/var/www/dbmailadministrator/DBMA_CONFIG.DB"
}

exec {
  command = "apachectl -D FOREGROUND"
  splay = "60s"
}
