from ubuntu:disco
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt full-upgrade -y && \
    apt install -y locales
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en
RUN locale-gen en_US.UTF-8 && \
    apt install -y supervisor git apache2 apache2-utils links curl vim locales libapache2-mod-php php-cli php-pgsql php-zip php-recode php-readline php-json php-curl php-intl php-mbstring php-yaml composer openjdk-8-jre-headless postgresql && \
    a2enmod rewrite && \
    sed -i -e 's/StartServers.*/StartServers 1/g' /etc/apache2/mods-enabled/mpm_prefork.conf && \
    sed -i -e 's/MinSpareServers.*/MinSpareServers 1/g' /etc/apache2/mods-enabled/mpm_prefork.conf && \
    sed -i -e 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf && \
    sed -i -e 's|APACHE_LOG_DIR=.*|APACHE_LOG_DIR=/home/www-data/log|g' /etc/apache2/envvars && \
    mkdir -p /home/www-data/tika && \
    curl http://mirror.klaus-uwe.me/apache/tika/tika-server-1.22.jar > /home/www-data/tika/tika-server.jar
CMD ["/home/www-data/run.sh"]
COPY /root /
EXPOSE 8080
RUN mkdir -p /home/www-data/data /home/www-data/log /home/www-data/tmp /home/www-data/postgresql /home/www-data/acdh-repo/vendor && \
    chown -R www-data:www-data /home/www-data && \
    chmod 700 /home/www-data && \
    usermod -d /home/www-data www-data
VOLUME /home/www-data/data
VOLUME /home/www-data/tmp
VOLUME /home/www-data/log
VOLUME /home/www-data/postgresql
VOLUME /home/www-data/acdh-repo/vendor

