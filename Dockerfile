FROM node:8-alpine

WORKDIR /app

# Install prerequisites
RUN set -ex \
    && apk add --update --no-cache curl build-base bash libpng-dev libjpeg-turbo-dev tiff-dev \
    && npm install -g svgo \
    && cd ~ \
    && curl -fSL https://github.com/google/zopfli/archive/zopfli-1.0.2.tar.gz -o zopfli-1.0.2.tar.gz \
    && tar xvfz zopfli-1.0.2.tar.gz \
    && cd zopfli-zopfli-1.0.2 \
    && make zopfli \
    && mv zopfli /usr/local/bin/ \
    && make zopflipng \
    && mv zopflipng /usr/local/bin/ \
    && cd .. \
    && rm zopfli-1.0.2.tar.gz \
    && rm -rf zopfli-zopfli-1.0.2 \
    && cd ~ \
    && curl -fSL https://github.com/google/brotli/archive/v1.0.7.tar.gz -o v1.0.7.tar.gz \
    && tar xvfz v1.0.7.tar.gz \
    && cd brotli-1.0.7 \
    && make \
    && mv bin/brotli /usr/local/bin/ \
    && cd .. \
    && rm v1.0.7.tar.gz \
    && rm -rf brotli-1.0.7 \
    && cd ~ \
    && curl -fSL https://github.com/google/guetzli/archive/v1.0.1.tar.gz -o v1.0.1.tar.gz \
    && tar xvfz v1.0.1.tar.gz \
    && cd guetzli-1.0.1 \
    && make \
    && mv bin/Release/guetzli /usr/local/bin \
    && cd .. \
    && rm v1.0.1.tar.gz \
    && rm -rf guetzli-1.0.1 \
    && curl -fSL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.0.2.tar.gz -o libwebp-1.0.2.tar.gz \
    && tar xvfz libwebp-1.0.2.tar.gz \
    && cd libwebp-1.0.2 \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm libwebp-1.0.2.tar.gz \
    && rm -rf libwebp-1.0.2 \
    && rm -rf /var/cache/apk/*

# Install helper scripts
COPY bin/* /usr/local/bin/
