FROM debian:bullseye-slim
LABEL maintainer="otiai10 <otiai10@gmail.com>"

ARG LOAD_LANG=jpn

RUN apt update \
    && apt install -y \
      ca-certificates \
      libtesseract-dev=4.1.1-2.1 \
      tesseract-ocr=4.1.1-2.1 \
      golang=2:1.15~1 \
      nginx

ENV GO111MODULE=on
ENV GOPATH=${HOME}/go
ENV PATH=${PATH}:${GOPATH}/bin

ADD . $GOPATH/src/github.com/otiai10/ocrserver
WORKDIR $GOPATH/src/github.com/otiai10/ocrserver
RUN go get -v ./... && go install .

# Load languages
RUN if [ -n "${LOAD_LANG}" ]; then apt-get install -y tesseract-ocr-${LOAD_LANG}; fi

# Set up Nginx for CORS and reverse proxy
RUN echo 'server { \
    listen 8080; \
    location / { \
        if ($request_method = 'OPTIONS') { \
            add_header 'Access-Control-Allow-Origin' '*'; \
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS'; \
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range'; \
            add_header 'Access-Control-Max-Age' 1728000; \
            add_header 'Content-Type' 'text/plain; charset=utf-8'; \
            add_header 'Content-Length' 0; \
            return 204; \
        } \
        if ($request_method = 'POST') { \
            add_header 'Access-Control-Allow-Origin' '*'; \
        } \
        if ($request_method = 'GET') { \
            add_header 'Access-Control-Allow-Origin' '*'; \
        } \
        proxy_pass http://127.0.0.1:8081; \
    } \
}' > /etc/nginx/sites-available/default

# Modify to start both ocrserver and nginx
CMD service nginx start && ocrserver -p 8081
