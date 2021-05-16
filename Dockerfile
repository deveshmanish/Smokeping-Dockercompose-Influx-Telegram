#=================================================================================================

FROM deveshmanish/smokeping:2.7.4 as build
MAINTAINER deveshmanish, https://github.com/deveshmanish/SmokePing

#=================================================================================================

#create the production image
FROM debian
MAINTAINER deveshmanish, https://github.com/deveshmanish/smokeping-dockerized	

# Some build ENV variables
# LIBDIR looks like /usr/lib/x86_64-linux-gnu
# PERLDIR looks like /usr/lib/x86_64-linux-gnu/perl5/5.26
#ENV \
#   LIBDIR=$(ldconfig -v 2>/dev/null | grep /usr/lib | head --lines=2 | tail -1 | sed 's/:$//') \
#   PERLDIR=$(perl -V | grep $LIBDIR/perl5/ | tail -1 | sed 's/ *//') \ 
ENV \
    LIBDIR=/usr/lib/x86_64-linux-gnu \
    PERLDIR=/usr/lib/x86_64-linux-gnu/perl
	
ENV \
    DEBIAN_FRONTEND="noninteractive" \
    HOME="/root" \
    TERM="xterm" \
    APACHE_LOG_DIR="/var/log/apache2" \
    APACHE_LOCK_DIR="/var/lock/apache2" \
    APACHE_PID_FILE="/var/run/apache2.pid" \
    PERL_MM_USE_DEFAULT=1 \
    PERL5LIB=/opt/smokeping/lib \
    LC_ALL=C \
    LANG=C

# Copy Smokeping from build image
COPY --from=build /opt/smokeping-* /opt/smokeping

# Copy Smokeping Perl modules from build image
COPY --from=build ${PERLDIR}/ ${PERLDIR}/

# Copy smokemail, tmail, web interface
COPY --from=build /SmokePing/etc/smokemail.dist /etc/smokeping/smokemail
COPY --from=build /SmokePing/etc/tmail.dist /etc/smokeping/tmail
COPY --from=build /SmokePing/etc/basepage.html.dist /etc/smokeping/basepage.html
COPY --from=build /SmokePing/etc/config.dist /etc/smokeping/config
COPY --from=build /SmokePing/VERSION /opt/smokeping

# COPY additional files
COPY root/ /

# Install dependencies
RUN \
    chmod 1777 /tmp \
&&  apt-get update \
&&	apt-get upgrade -y \
&&  apt-get install curl -y \
# Fetch ookla speedtest install script
&&  curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash \
&& 	apt-get update \
&& 	apt-get install -y --no-install-recommends \
		acl \
        apache2 \
        apache2-suexec-pristine \
        busybox \
        curl \
        dirmngr \
        dnsutils \
        echoping \
        fping \
        iproute2 \
        iw \
        libapache2-mod-fcgid \
        librrds-perl \
        libssl-dev \
        mtr \
        nano \
		openssh-client \
        python3-dev \
        python3-pip \
        rrdtool \
        runit \
        time \
        ttf-dejavu \
        tzdata \
        speedtest \
        syslog-ng \
&& 	chmod -v +x /etc/service/*/run /etc/my_init.d/*.sh /sbin/my_init \
&& 	mkdir -p /var/run/smokeping \
&& 	mkdir /var/cache/smokeping \
&& 	mkdir /opt/smokeping/cache \
&& 	mkdir /opt/smokeping/var \
&& 	mkdir /opt/smokeping/data \
&& 	mv /opt/smokeping/etc /opt/smokeping/etc.dist \
&& 	ln -s /opt/smokeping/etc/config /config \
&& 	ln -s /opt/smokeping /opt/smokeping-$(cat /opt/smokeping/VERSION) \
# Create cache dir
&& 	mkdir /var/lib/smokeping \
# Create the smokeping user
&& 	useradd -d /opt/smokeping -G www-data smokeping \
# Enable cgid support in apache
&& 	a2enmod cgid \
&& 	sed -i 's/#AddHandler cgi-script .cgi/AddHandler cgi-script .cgi .pl .fcgi/' /etc/apache2/mods-available/mime.conf \
# Adjusting SyslogNG - see https://github.com/phusion/baseimage-docker/pull/223/commits/dda46884ed2b1b0f7667b9cc61a961e24e910784
&& 	sed -ie "s/^       system();$/#      system(); #This is to avoid calls to \/proc\/kmsg inside docker/g" /etc/syslog-ng/syslog-ng.conf \
&&  if [ ! -e /usr/bin/python ]; then ln -s python3 /usr/bin/python ; fi \
&&  pip3 install --no-cache speedtest-cli telegram-send \
&&  echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > /etc/ssh/ssh_config \
&& 	chmod a+rx /usr/local/bin/tg-send /usr/local/bin/telegram-send \
&& 	apt-get autoremove -y \
&& 	apt-get clean \
&& 	rm -rf /var/lib/apt/lists/* /var/tmp/*

ADD smokeping.conf /etc/apache2/sites-enabled/10-smokeping.conf
ADD smokeping_secrets /opt/smokeping/etc/smokeping_secrets
RUN mkdir /var/www/html/smokeping \
&&  ln -s /opt/smokeping/cache /var/www/html/smokeping/cache \
&& 	ln -s /opt/smokeping/data /data \
&& 	chown smokeping:www-data /opt/smokeping/cache /var/www/html/smokeping/cache /opt/smokeping/data /data \
&& 	chmod g+rw /opt/smokeping/cache /var/www/html/smokeping/cache /opt/smokeping/data \
&&	chmod 440 /opt/smokeping/etc/smokeping_secrets \
&&	chown smokeping:www-data /opt/smokeping/etc/smokeping_secrets \
# Add custom probes and dependencies
&&	curl -L -o /usr/local/bin/speedtest-cli \
        https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py \
&&	curl -L -o /usr/local/bin/youtube-dl https://yt-dl.org/downloads/latest/youtube-dl \
&&	chmod a+x /usr/local/bin/speedtest-cli /usr/local/bin/youtube-dl


COPY --from=build /SmokePing/htdocs/ /var/www/html/smokeping/
# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Volumes and Ports
VOLUME /config
VOLUME /data
EXPOSE 80
# ========================================================================================
