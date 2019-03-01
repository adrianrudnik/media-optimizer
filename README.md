# Media optimizer

Toolkit for docker based multi-stage builds to optimize images for production systems.

It combines the following tools:

- svgo (SVG optimization)
- zopfli (PNG optimization)
- guetzli (JPEG optimization)
- webp (smaller jpg/png alternative)
- brotli (better GZIP compression)

The idea is to optimize all media assets after the the app was compiled and before they are installed to the delivering service.

# Table of contents
- [Overview](#overview)
- [Usage](#usage)
  - [Docker multi-stage](#docker-multi-stage)
  - [Bash aliases](#bash-aliases)
- [Misc](#misc)
  - [NGINX](#nginx)

## Overview

The following commands are available on this image:

`optimize-svg` will minimize svgs (and webfonts) files with svgo.  
`optimize-jpg` will minimize jpg files with guetzli.  
`optimize-png` will minimize png files zopflipng.  
`optimize-webp` will take and png/jpg files and create a webp version of it and append '.webp' to its filename.  
`generate-static-gzip` will take common txt based files and generate a static gzipped version of it, appending '.gz' to it.  
`generate-static-br` will take common txt based files and generate a static brotlied version of it, appending '.br' to it.  

The commands take a single target directory as parameter, so `optimize-png .` will optimize recursivly from the current directory.

Please beware: All `optimize-*` commands are **!!! destructive !!!** to the source image. Its goal is to replace the source image with the optimized one **inplace**. This allows to have higher quality images inside the repository / lfs, while having optimized images on production without any special rules.

## Usage

### Docker multi-stage

This example is a three stage build:

- Build a npm based app for production (assuming the production ready resource ends up in `app/dist/`)
- Optimize the production resources
- Installation of the app onto an NGINX server for deployment

Sounds like overkill, but it illustrates the idea well:

```sh
FROM node:8-alpine as app_compile

COPY app/ /app/

RUN set -ex \
    && cd /app \
    && npm install \
    && npm run build \
    && npm run generate    

FROM adrianrudnik/media-optimizer as app_optimize

COPY --from=app_compile /app/dist /app/dist

RUN set -ex \
    && optimize-svg /app/dist \
    && optimize-jpg /ap/dist \
    && optimize-png /app/dist \
    && optimize-webp /app/dist \
    && generate-static-gzip /app/dist \
    && generate-static-br /app/dist

FROM nginx

COPY --from=app_optimize /app/dist /var/www/html
```

### Bash aliases

Please beware: All `optimize-*` commands are **!!! destructive !!!**. Use with caution!

You can use it locally in a one-time mode, in this example for bash by configuring `~/.bash_aliases`:

```sh
alias optimize-svg='docker run -it --rm -v `pwd`:/app adrianrudnik/media-optimizer optimize-svg'
alias optimize-png='docker run -it --rm -v `pwd`:/app adrianrudnik/media-optimizer optimize-png'
alias optimize-jpg='docker run -it --rm -v `pwd`:/app adrianrudnik/media-optimizer optimize-jpg'
alias optimize-webp='docker run -it --rm -v `pwd`:/app adrianrudnik/media-optimizer optimize-webp'
alias optimize-svg='docker run -it --rm -v `pwd`:/app adrianrudnik/media-optimizer optimize-svg'
alias generate-static-gzip='docker run -it --rm -v `pwd`:/app adrianrudnik/media-optimizer generate-static-gzip'
alias generate-static-br='docker run -it --rm -v `pwd`:/app adrianrudnik/media-optimizer generate-static-br'
```

make sure to reload your current bash with `source ~/.bashrc` and pull the image before usage with `docker pull adrianrudnik/media-optimizer:latest`.

## Misc

### NGINX

The commands `generate-static-gzip` and `generate-static-br` enable you to use the `gzip_static` and `brotli_static` (needs compilation of nginx) directives and allow for a very fast delivery of precompressed static files. Combine with `open_file_cache` if you see fit.

As for webp, try to use it with `try_files`. One cheap example would be `try_files $uri.webp $uri @index =404;` for static resources, but please make sure that you follow other guides on how check the client for webp capability.
