# media optimizer image for docker

Helper tools to be used in docker multi-stage builds to optimize images for production systems.

- svgo (SVG optimization)
- brotli (br compression)
- zopfli (better gzip compression)
- guetzli (jpeg optimization)
- webp (smaller jpg/png alternative)

## Usage

### commands

The following commands are installed onto this image:

`optimize-svg` will minimize svgs (and webfonts) files with svgo.  
`optimize-jpg` will minimize jpg files with guetzli.  
`optimize-png` will minimize png files zopflipng.  
`optimize-webp` will take and png/jpg files and create a webp version of it and append '.webp' to its filename.  
`generate-static-gzip` will take common txt based files and generate a static gzipped version of it, appending '.gz' to it.  
`generate-static-br` will take common txt based files and generate a static brotlied version of it, appending '.br' to it.  

The commands take a single target directory as parameter, so `optimize-png .` will optimize recursivly from the current directory.

Please beware: All `optimize-*` commands are **!!! destructive !!!** to the source image. Its goal is to replace the source image with the optimized one **inplace**. This allows to have higher quality images inside the repository / lfs, while having optimized images on production without any special rules.

### docker multi-stage

This example is a three stage build:

- Build a npm based app for production (assuming the production ready resource ends up in `app/dist/`)
- Optimize the production resources
- Installation of the app onto an NGINX server for deployment

Sounds like an overkill, but it illustrates the idea well:

```
FROM node:8-alpine as app_compile

COPY app/ /app/

RUN set -ex \
    && cd /app \
    && npm install \
    && npm run build \
    && npm run generate    

FROM kreischweide/toolchain-mediaoptimizer as app_optimize

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

### As alias on bash

Please beware: All `optimize-*` commands are **!!! destructive !!!**. Use with caution!

You can use it locally in a one-time mode, in this example for bash by configuring `~/.bash_aliases`:

```
alias optimize-svg='docker run -it --rm -v `pwd`:/app kreischweide/toolchain-mediaoptimizer optimize-svg'
alias optimize-png='docker run -it --rm -v `pwd`:/app kreischweide/toolchain-mediaoptimizer optimize-png'
alias optimize-jpg='docker run -it --rm -v `pwd`:/app kreischweide/toolchain-mediaoptimizer optimize-jpg'
alias optimize-webp='docker run -it --rm -v `pwd`:/app kreischweide/toolchain-mediaoptimizer optimize-webp'
alias optimize-jpg='docker run -it --rm -v `pwd`:/app kreischweide/toolchain-mediaoptimizer optimize-jpg'
alias generate-static-gzip='docker run -it --rm -v `pwd`:/app kreischweide/toolchain-mediaoptimizer generate-static-gzip'
alias generate-static-br='docker run -it --rm -v `pwd`:/app kreischweide/toolchain-mediaoptimizer generate-static-br'
```

make sure to reload your current bash with `source ~/.bashrc` and pull the image before usage with `docker pull kreischweide/toolchain-mediaoptimizer:latest`.

## Nginx

The commands `generate-static-gzip` and `generate-static-br` enable you to use the `gzip_static` and `brotli_static` (needs compilation of nginx) directives and a very fast delivery of precompressed static files. Combine with `open_file_cache` if you see fit.

All commands allow for a simple `try_files` rule like: `try_files $uri.webp $uri @index =404;` for static resources, make sure to follow all the guides on how to check if webp is supported using a `map`.
