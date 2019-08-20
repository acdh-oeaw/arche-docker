from ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt full-upgrade -y && \
    apt install -y locales
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en
RUN locale-gen en_US.UTF-8 && \
    apt install -y supervisor git apache2 apache2-utils libapache2-mpm-itk links curl vim locales libapache2-mod-php php-cli php-pgsql php-zip php-recode php-readline php-json php-curl php-intl php-mbstring php-yaml composer openjdk-8-jre-headless postgresql && \
    useradd -m user && \
    a2enmod rewrite && \
    a2enmod headers && \
    a2enmod proxy && \
    a2enmod proxy_http && \
    sed -i -e 's/StartServers.*/StartServers 1/g' /etc/apache2/mods-enabled/mpm_prefork.conf && \
    sed -i -e 's/MinSpareServers.*/MinSpareServers 1/g' /etc/apache2/mods-enabled/mpm_prefork.conf &&\
    mkdir /home/user/tika && \
    curl http://mirror.klaus-uwe.me/apache/tika/tika-server-1.22.jar > /home/user/tika/tika-server.jar
CMD ["/usr/bin/supervisord"]
EXPOSE 80
USER user
WORKDIR /home/user
RUN git clone https://github.com/zozlak/acdh-repo.git /home/user/acdh-repo  && \
    cd /home/user/acdh-repo && \
    composer update && \
    ln -s /home/user/config.yaml /home/user/acdh-repo/config.yaml
USER postgres
RUN /usr/bin/pg_ctlcluster 10 main start -- -D /var/lib/postgresql/10/main -l /var/log/postgresql/postgresql-10-main.log && \
    createuser user && \
    createdb -O user user && \
    /usr/bin/pg_ctlcluster 10 main stop
USER root
COPY /root /
RUN chown -R user:user /home/user
VOLUME /var/lib/postgresql
VOLUME /home/user/data
VOLUME /home/user/tmp
VOLUME /home/user/log
