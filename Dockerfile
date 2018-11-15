FROM centos:centos7
#FROM centos:6.10

MAINTAINER bubbkis <bubbkis@gmail.com>

ENV PHP_VERSION 5.2.17

# Start as root
USER root

###########################################################################
# non-root user:
###########################################################################

# Add a non-root user to prevent files being created with root permissions on host machine.
ARG PUID=1000
ARG PGID=1000

RUN groupadd -g ${PGID} bubbkis && \
    useradd -u ${PUID} -g bubbkis -m bubbkis -G bubbkis && \
    usermod -p "*" bubbkis

###########################################################################
# Set Timezone
###########################################################################
ENV TZ Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone


# Initial setup
RUN yum update -y
RUN yum groupinstall -y 'Development Tools'
RUN yum install -y git

###########################################################################
# ssh:
###########################################################################
COPY insecure_id_rsa /tmp/id_rsa
COPY insecure_id_rsa.pub /tmp/id_rsa.pub
#COPY id_rsa /tmp/id_rsa
#COPY id_rsa.pub /tmp/id_rsa.pub

ARG INSTALL_SSH=false

RUN if [ ${INSTALL_SSH} = true ]; then \
    yum install -y openssh-server \
    && systemctl enable sshd && \
    cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys \
        && cat /tmp/id_rsa.pub >> /root/.ssh/id_rsa.pub \
        && cat /tmp/id_rsa >> /root/.ssh/id_rsa \
        && rm -f /tmp/id_rsa* \
        && chmod 644 /root/.ssh/authorized_keys /root/.ssh/id_rsa.pub \
    && chmod 400 /root/.ssh/id_rsa \
    && cp -rf /root/.ssh /home/bubbkis \
    && chown -R bubbkis:bubbkis /home/laradock/.ssh \
    && sed -ri 's/^#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -ri 's/^#RSAAuthentication yes/RSAAuthentication yes/' /etc/ssh/sshd_config \
    && sed -ri 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
;fi


###########################################################################
# Crontab
###########################################################################

USER root
COPY ./crontab /etc/cron.d
RUN chmod -R 644 /etc/cron.d


# Apache installation
RUN yum install -y httpd httpd-devel

# PHP 5.2 dependency installation
RUN yum install -y  epel-release
RUN yum install -y \
  libaio-devel \
  libmcrypt-devel \
  libjpeg-devel \
  libpng-devel \
  libxml2-devel \
  libxslt-devel \
  curl-devel \
  freetype-devel \
  gmp-devel \
  mysql-devel \
  openssl-devel \
  postgresql-devel \
  sqlite-devel \
  libjpeg \ 
  readline-devel \
  libmemcached

RUN yum install -y --enablerepo=epel \
  libmcrypt \
  libmcrypt-devel \
  libtidy-devel \
  php-mcrypt

RUN ln -s /usr/lib64/libjpeg.so /usr/lib/ && ln -s /usr/lib64/libpng.so /usr/lib/

# PHP 5.2 installation
WORKDIR /usr/local/src
#ADD http://museum.php.net/php5/php-${PHP_VERSION}.tar.bz2 ./
#ADD https://github.com/bubbkis/php-${PHP_VERSION}_patch/raw/master/php-${PHP_VERSION}.tar.bz2 ./
COPY ./php-${PHP_VERSION}.tar.bz2 ./
RUN tar xf ./php-${PHP_VERSION}.tar.bz2 -C ./
WORKDIR ./php-${PHP_VERSION}
ADD https://raw.githubusercontent.com/bubbkis/php-${PHP_VERSION}_patch/master/php-${PHP_VERSION}.patch ./
ADD https://raw.githubusercontent.com/bubbkis/php-${PHP_VERSION}_patch/master/php_functions.c.patch ./
RUN patch -p0 < ./php-${PHP_VERSION}.patch 
RUN patch -u ./sapi/apache2handler/php_functions.c < ./php_functions.c.patch
RUN ./configure \
  --without-pear \
  --with-gd \
  --enable-gd-native-ttf \
  --enable-sockets \
  --with-jpeg-dir=/usr \
  --with-png-dir=/usr \
  --with-freetype-dir=/usr \
  --enable-exif \
  --enable-zip \
  --with-zlib \
  --with-zlib-dir=/usr \
  --with-openssl \
  --with-mcrypt=/usr \
  --enable-soap \
  --enable-xmlreader \
  --with-xsl \
  --enable-ftp \
  --enable-cgi \
  --with-curl=/usr \
  --with-tidy \
  --with-xmlrpc \
  --enable-sysvsem \
  --enable-sysvshm \
  --enable-shmop \
  --with-pgsql \
  --with-pdo-pgsql \
  --with-pdo-sqlite \
  --enable-pcntl \
  --with-readline \
  --enable-mbregex \
  --enable-mbstring \
  --enable-bcmath \
  --enable-intl \
  --with-gettext \
  --with-apxs2=/usr/bin/apxs \
  --with-config-file-path=/etc/ \
  --with-config-file-scan-dir=/etc/php.d

##   --enable-zend-multibyte \
##  --with-mysql=mysqlnd \
##  --with-mysqli=mysqlnd \
##  --with-pdo-mysql=mysqlnd \
##  --enable-fpm \
##  --with-mysql-sock \
##  --with-pear \

RUN make && make test && make install

### memcache コードから入れてみる
RUN yum install -y  gcc-c++
WORKDIR /usr/local/src
ADD https://pecl.php.net/get/memcached-2.1.0.tgz ./
#ADD https://pecl.php.net/get/memcache-2.2.7.tgz ./
ADD https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz ./
RUN tar -zxvf ./memcached-2.1.0.tgz  -C ./
#RUN tar -zxvf ./memcache-2.2.7.tgz  -C ./
RUN tar -zxvf ./libmemcached-1.0.18.tar.gz  -C ./

WORKDIR /usr/local/src/libmemcached-1.0.18
RUN ./configure --without-memcached && make && make install

WORKDIR /usr/local/src/memcached-2.1.0
RUN phpize
RUN ./configure --with-php-config=/usr/local/bin/php-config --disable-memcached-sasl && make && make install

#WORKDIR /usr/local/src/memcache-2.2.7
#RUN phpize
#RUN ./configure --with-php-config=/usr/local/bin/php-config --disable-memcached-sasl && make && make install

RUN yum install -y  memcached

RUN yum clean all

# PHP setup
COPY ./php.ini /etc/php.ini

# Apache setup and launching
COPY ./httpd.conf /etc/httpd/conf/extra.conf
RUN echo 'Include /etc/httpd/conf/extra.conf' >> /etc/httpd/conf/httpd.conf

EXPOSE 80

VOLUME [ "/data", "/var/www/html" ]

CMD [ "/usr/sbin/httpd", "-D", "FOREGROUND" ]
