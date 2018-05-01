FROM compass-devel AS code-compass-installer

WORKDIR /root

COPY ./ ./CodeCompass
RUN chmod u+x ./CodeCompass/scripts/docker/CC-Runtime/codecompass/bin/make_compass.sh
RUN ./CodeCompass/scripts/docker/CC-Runtime/codecompass/bin/make_compass.sh .


FROM ubuntu:16.04 AS code-compass

RUN \
    apt-get update \
    && apt-get install --yes \
    openjdk-8-jdk \
    libboost-filesystem1.58.0 \
    libboost-log1.58.0 \
    libboost-program-options1.58.0 \
    libboost-thread1.58.0 \
    libgit2-24 \
    libgvc6 \
    libpq5

COPY --from=code-compass-installer /opt /opt

CMD ["/bin/bash"]
