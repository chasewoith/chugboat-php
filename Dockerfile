# ============================
# PULL OFFICIAL PHP REPO
# ============================
FROM php:7.0-fpm

# ============================
# SETUP BUILD ARGS
# ============================
ENV ROOT_USER_PASS root
ENV DEV_USER_PASS admin

# ===============================================
# FIX PERMISSIONS / ADD DEV USER / SET PASSWORDS
# ================================================
RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data
RUN useradd -p dev -ms /bin/bash -d /var/www/html dev
RUN usermod -aG www-data dev
RUN usermod -aG dev www-data
RUN chown -R dev:dev /var/www/html
RUN echo "dev:$DEV_USER_PASS" | chpasswd
RUN echo "root:$ROOT_USER_PASS" | chpasswd

# ============================
# ADD APT SOURCES
# ============================
# RUN echo "deb http://ftp.debian.org/debian jessie-backports main" | tee -a /etc/apt/sources.list

# ============================
# UPDATE/UPGRADE APT PACKAGES
# ============================
RUN apt-get update
RUN apt-get upgrade -y

# ============================
# UPDATE/UPGRADE APT PACKAGES
# ============================
RUN apt-get install -y \
    build-essential \
    apt-utils \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libpq-dev \
	zlib1g-dev libicu-dev g++ \
    sqlite3 libsqlite3-dev \
    libxml2-dev \
	libxslt-dev

RUN apt-get install -y git vim cron htop zip unzip pwgen curl wget chkconfig ruby rubygems ruby-dev screen openssl openssh-server

# ============================
# CONFIG PHP EXTENSIONS
# ============================
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd
RUN docker-php-ext-install iconv
RUN docker-php-ext-install mcrypt
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pgsql
RUN docker-php-ext-install pdo_mysql pdo_pgsql pdo_sqlite
RUN docker-php-ext-install soap
RUN docker-php-ext-install tokenizer
RUN docker-php-ext-install zip
RUN docker-php-ext-configure intl
RUN docker-php-ext-install intl
RUN docker-php-ext-install xsl
RUN docker-php-ext-configure bcmath
RUN docker-php-ext-install bcmath
RUN pecl install redis-3.1.0 \
    && docker-php-ext-enable redis

# ============================
# xDebug
# ============================
RUN pecl install xdebug-2.5.0 \
    && docker-php-ext-enable redis xdebug

# ============================
# Setup Composer
# ============================
RUN php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
RUN php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('/tmp/composer-setup.php'); } echo PHP_EOL;"
RUN php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer

# ============================
# CONFIG OPENSSH / START SERVICE
# ============================
COPY config/ssh/sshd_config /etc/ssh/sshd_config
RUN service ssh start

# ============================
# MHSendmail CONFIG
# ============================
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install golang-go
RUN mkdir /opt/go && export GOPATH=/opt/go && go get github.com/mailhog/mhsendmail
