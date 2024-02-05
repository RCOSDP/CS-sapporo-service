FROM python:3.8.18-bullseye as builder

RUN apt update && \
    apt install -y --no-install-recommends \
    git && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN python3 -m pip install --no-cache-dir --progress-bar off -U pip setuptools wheel && \
    python3 -m pip install --no-cache-dir --progress-bar off .

WORKDIR /tmp
RUN git clone --depth 1 https://github.com/RCOSDP/rdmclient.git && \
    cd rdmclient && \
    python3 -m pip install --no-cache-dir --progress-bar off . && \
    cd .. && \
    rm -rf rdmclient

FROM python:3.8.18-slim-bullseye

LABEL org.opencontainers.image.url="https://github.com/RCOSDP/CS-sapporo-service"
LABEL org.opencontainers.image.source="https://github.com/RCOSDP/CS-sapporo-service/blob/main/Dockerfile"
LABEL org.opencontainers.image.version="1.6.1"
LABEL org.opencontainers.image.description="sapporo-service is a standard implementation conforming to the Global Alliance for Genomics and Health (GA4GH) Workflow Execution Service (WES) API specification."
LABEL org.opencontainers.image.licenses="Apache2.0"

RUN apt update && \
    apt install -y --no-install-recommends \
    curl \
    jq \
    libmagic-dev \
    libxml2 \
    tini && \
    apt clean &&\
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl -O https://download.docker.com/linux/static/stable/$(uname -m)/docker-24.0.7.tgz && \
    tar -xzf docker-24.0.7.tgz && \
    mv docker/* /usr/bin/ && \
    rm -rf docker docker-24.0.7.tgz

COPY --from=builder /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages
COPY --from=builder /usr/local/bin/sapporo /usr/local/bin/sapporo
COPY --from=builder /usr/local/bin/rdmclient /usr/local/bin/rdmclient

WORKDIR /app
COPY . .

ENV SAPPORO_HOST 0.0.0.0
ENV SAPPORO_PORT 1122
ENV SAPPORO_DEBUG False

EXPOSE 1122

ENTRYPOINT ["tini", "--"]
CMD ["sapporo"]
