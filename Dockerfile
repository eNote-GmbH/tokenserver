FROM pypy:2.7-7.3.3-slim AS base

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN addgroup -gid 1001 app && useradd -g app --shell /usr/sbin/nologin --uid 1001 app

# Debian Buster reached end-of-life
RUN sed -i \
      -e 's|deb.debian.org|archive.debian.org|g' \
      -e 's|security.debian.org|archive.debian.org|g' \
      /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until
# install dependencies, cleanup and add libstdc++ back in since
# we the app needs to link to it
RUN apt-get update && \
    apt-get install -y build-essential ca-certificates libffi-dev libssl-dev default-libmysqlclient-dev make git && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt dev-requirements.txt /app/

RUN pip install --upgrade -r dev-requirements.txt && pip install "virtualenv<21"

COPY . /app

RUN pypy ./setup.py develop

RUN chown -R app:app /app/tokenserver.egg-info /app
USER app

# ---- test stage: build tools + make already present, just run the suite ----
FROM base AS test
CMD ["make", "tests"]

# ---- production stage: same base, dev tooling stripped for the shipped image ----
FROM base AS production

USER root
RUN apt-get remove -y build-essential gcc libffi-dev libssl-dev default-libmysqlclient-dev make git && apt-get autoremove -y

# run the server by default
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["server"]

# run as non priviledged user
USER app
