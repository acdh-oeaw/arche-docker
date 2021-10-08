from ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt full-upgrade -y && \
    apt install -y locales gnupg && \
    echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu/ focal main" >> /etc/apt/sources.list && \
    echo "deb http://ppa.launchpad.net/ondrej/apache2/ubuntu/ focal main" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en
RUN locale-gen en_US.UTF-8 && \
    locale-gen de_DE.UTF-8 && \
    apt update && \
    apt install -y supervisor git zip apache2 apache2-utils links curl vim locales libapache2-mod-php8.0 php8.0-cli php8.0-pgsql php8.0-zip php8.0-iconv php8.0-readline php8.0-curl php8.0-intl php8.0-mbstring php8.0-yaml php8.0-bcmath php8.0-dom php8.0-opcache php8.0-gd php8.0-sqlite3 php8.0-xml php8.0-xdebug openjdk-11-jre-headless postgresql authbind pv sqlite3 postgresql-12-postgis-3 && \
    a2enmod rewrite && \
    touch /etc/authbind/byport/80 && chmod 777 /etc/authbind/byport/80 && \
    sed -i -e 's/StartServers.*/StartServers 1/g' /etc/apache2/mods-enabled/mpm_prefork.conf && \
    sed -i -e 's/MinSpareServers.*/MinSpareServers 1/g' /etc/apache2/mods-enabled/mpm_prefork.conf && \
    sed -i -e 's|APACHE_LOG_DIR=.*|APACHE_LOG_DIR=/home/www-data/log|g' /etc/apache2/envvars && \
    curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm composer-setup.php && \
    mkdir -p /home/www-data/tika && \
    curl https://archive.apache.org/dist/tika/2.1.0/tika-server-standard-2.1.0.jar > /home/www-data/tika/tika-server.jar
CMD ["/home/www-data/run.sh"]
COPY /root /
EXPOSE 80
RUN mkdir -p /home/www-data/data /home/www-data/log /home/www-data/tmp /home/www-data/postgresql /home/www-data/docroot/api /home/www-data/vendor && \
    chown -R www-data:www-data /home/www-data && \
    chmod -R go-rwx /home/www-data && \
    usermod -d /home/www-data www-data
WORKDIR /home/www-data
VOLUME /home/www-data/config
VOLUME /home/www-data/data
VOLUME /home/www-data/tmp
VOLUME /home/www-data/log
VOLUME /home/www-data/postgresql
VOLUME /home/www-data/vendor
