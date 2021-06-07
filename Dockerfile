#FROM armhf/alpine:edge
#FROM alpine:3.12
FROM surnet/alpine-wkhtmltopdf:3.13.5-0.12.6-full
LABEL maintainer="commits@secret.fyi"



#RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk add --update --no-cache \
    bash \
    python3-dev \
    py-pip \
    ca-certificates \
#    wkhtmltopdf=0.12.5-r1 \
    tar \
    wget \
    gcc \
    py3-lxml \
    linux-headers \
    postgresql-dev \
    libxml2-dev \
    libxslt-dev \
    musl-dev \
    jpeg-dev \
    zlib-dev \
    openldap-dev\
    nodejs \
    nodejs-npm \
    g++ make py3-cffi openssl-dev libffi-dev \
    && update-ca-certificates


# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
RUN apk add --no-cache \
        inotify-tools \
        git \
        ghostscript \
        icu \
        libev \
        nodejs \
        openssl \
        postgresql-libs \
        poppler-utils \
        ruby \
        su-exec


ARG WKHTMLTOX_VERSION="0.12"
ARG WKHTMLTOX_SUBVERSION="5"
# Special case for wkhtmltox
# HACK https://github.com/wkhtmltopdf/wkhtmltopdf/issues/3265
# Idea from https://hub.docker.com/r/loicmahieu/alpine-wkhtmltopdf/
# Use prepackaged wkhtmltopdf and wrap it with a dummy X server
#RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing wkhtmltopdf=0.12.5-r1

RUN apk add --no-cache xvfb ttf-dejavu ttf-freefont fontconfig dbus
COPY bin/wkhtmltox.sh /usr/local/bin/wkhtmltoimage
RUN ln /usr/local/bin/wkhtmltoimage /usr/local/bin/wkhtmltopdf
RUN mkdir /realbin
RUN which wkhtmltopdf
RUN mv /bin/wkhtmltopdf /realbin/
RUN mv /bin/wkhtmltoimage /realbin/


RUN addgroup odoo && adduser odoo -s /bin/sh -D -G odoo \
    && echo "odoo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#    && mkdir /opt \
#    && wget https://nightly.odoo.com/14.0/nightly/src/odoo_14.0.latest.tar.gz \
#    && tar -xzf odoo_14.0.latest.tar.gz -C /opt \
#    && cd /opt/odoo-14.0-20170101 \
#    && rm odoo_14.0.latest.tar.gz \


###COPY odoo_14.0.latest.tar.gz /tmp/

RUN  npm install -g less less-plugin-clean-css

RUN  mkdir /opt || true \
    && /bin/bash -c "wget -q -c -O- https://nightly.odoo.com/14.0/nightly/src/odoo_14.0.latest.tar.gz | tar -xzv -C /opt" \
    && cd /opt/odoo* \
    && pip install -r requirements.txt \
    && python3 setup.py install \
    && rm -r /opt/odoo-*

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
COPY ./odoo.conf /odoo.conf.init
RUN chown odoo /etc/odoo/odoo.conf

# Mount /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
ENTRYPOINT ["/entrypoint.sh"]

CMD ["odoo"]
