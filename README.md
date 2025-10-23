# README
Sistema per la gestione dei rimborsi di Wikimedia Italia.
## Configurazione
Da inserire in un file `.env` nella cartella radice. Verrà automaticamente caricato da Capistrano all'atto del deployment.
```
NEXTCLOUD_WEBDAV_URL=
NEXTCLOUD_USERNAME=
NEXTCLOUD_PASSWORD=
CARTELLA_AMMINISTRAZIONE=
SECRET_KEY_BASE=
RIMBORSI_DATABASE_PASSWORD=
RAILS_ENV=production
REDIS_URL=redis://localhost:6379/xx
ADDRESS= username/indirizzo della casella di posta mittente
PASSWORD= password della casella di posta
DOMAIN= dominio casella di posta
PORT= porta SMTP
PUMA_SOCKET=home/deploy/apps/rimborsi/shared/tmp/sockets/rimborsi-puma.sock
```
## Deploy
Il deploy si effettua con Capistrano. Configurare le informazioni del server nel file config/deploy.rb, compresa la cartella scelta per l'app. 

Per fare il setup dell'ambiente:
* `cap production puma:install`
* `mkdir apps/mysite/shared/tmp/sockets` (dove mysite è il nome della cartella scelta per l'app)
* configurare il reverse proxy nginx sul socket `PUMA_SOCKET` (un esempio di configurazione nginx è qui https://github.com/seuros/capistrano-example-app/blob/main/DEPLOYMENT_GUIDE.md)
* `su postgres`
* `cd`
* `createdb rimborsi`
* `psql`
* `create user rimborsi with password 'mypassword';`
* `grant all privileges on database rimborsi_production to rimborsi;`
* `exit` # exit psql shell
* `exit` # back to root user

Installare libvips.

A questo punto siamo pronti! 
* `cap production deploy`