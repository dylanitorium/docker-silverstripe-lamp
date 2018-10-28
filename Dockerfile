FROM debian:jessie
MAINTAINER Dylan Sweetensen <dylan@sweetdigital.nz>

### SET UP

RUN apt-get -qq update

RUN apt-get -qqy install sudo wget lynx telnet nano curl make git-core locales bzip2 

RUN echo "LANG=en_US.UTF-8\n" > /etc/default/locale && \
	echo "en_US.UTF-8 UTF-8\n" > /etc/locale.gen && \
	locale-gen

# Known hosts
ADD known_hosts /root/.ssh/known_hosts

RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    wget -O- http://www.dotdeb.org/dotdeb.gpg | apt-key add -


# APACHE, MYSQL, PHP & SUPPORT TOOLS
RUN apt-get -y install apt-transport-https lsb-release ca-certificates
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get -qqy install apache2 \
    mysql-client \
    php7.2 \
    php7.2-cli \
    libapache2-mod-php7.2 \
    php7.2-gd \
    php7.2-json \
    php7.2-ldap \
    php7.2-mbstring \
    php7.2-mysql \
    php7.2-pgsql \
    php7.2-sqlite3 \
    php7.2-xml \
    php7.2-xsl \
    php7.2-zip \
    php7.2-soap \
    php7.2-fpm \
    php7.2-curl \
    php7.2-cli \
    php7.2-dev \
    php7.2-intl \
    php-pear \
    libsasl2-dev \
    sendmail

#  - Phpunit, Composer, Phing, SSPak
RUN wget https://phar.phpunit.de/phpunit-3.7.37.phar && \
	chmod +x phpunit-3.7.37.phar && \
	mv phpunit-3.7.37.phar /usr/local/bin/phpunit && \
	wget https://getcomposer.org/composer.phar && \
	chmod +x composer.phar && \
	mv composer.phar /usr/local/bin/composer && \
	curl -sS https://silverstripe.github.io/sspak/install | php -- /usr/local/bin

# SilverStripe Apache Configuration
RUN a2enmod rewrite && \
	rm -r /var/www/html && \
	echo "date.timezone = Pacific/Auckland" >> /etc/php/7.2/fpm/php.ini

ADD apache-foreground /usr/local/bin/apache-foreground
ADD apache-default-vhost /etc/apache2/sites-available/000-default.conf

####
## These are not specifically SilverStripe related and could be removed on a more optimised image

# Ruby, RubyGems, Bundler
RUN apt-get -qqy install ruby ruby-dev gcc && \
	gem install bundler && \
	gem install compass

# NodeJS and common global NPM modules
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash - && \
	apt-get install -qqy nodejs && \
	npm install -g grunt-cli gulp bower

# LetsEncrypt 
RUN echo 'deb http://ftp.debian.org/debian jessie-backports main' | sudo tee /etc/apt/sources.list.d/backports.list
RUN apt-get update
RUN apt-get -qqy install python-certbot-apache -t jessie-backports

####
## Commands and ports
EXPOSE 80

VOLUME /var/www

# Run apache in foreground mode, because Docker needs a foreground
WORKDIR /var/www
CMD ["/usr/local/bin/apache-foreground"]

ENV LANG en_US.UTF-8
