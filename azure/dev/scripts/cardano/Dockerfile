FROM debian:stable-slim

LABEL desc="Cardano Submit API Node"
ARG DEBIAN_FRONTEND=noninteractive
ARG VERSION=1.35.3

USER root
WORKDIR /

ENV \
    ENV=/etc/profile \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/guild/.cabal/bin

# COPY NODE BINS AND DEPS
COPY --from=cardanocommunity/cardano-node:1.35.3/usr/local/bin/cardano-submit-api /usr/local/bin/
COPY --from=cardanocommunity/cardano-node:1.35.3 /usr/local/bin/cardano-ping /usr/local/bin/

RUN chmod a+x /usr/local/bin/* && ls /opt/ \
    && mkdir -p /etc/cardano-submit-api

# Install locales package
RUN  apt-get update && apt-get install --no-install-recommends -y locales apt-utils

#  en_US.UTF-8 for inclusion in generation
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANG=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc

# PREREQ
RUN apt-get update && apt-get install -y libsodium-dev curl wget sudo  \
    && sudo apt-get -y purge && sudo apt-get -y clean && sudo apt-get -y autoremove && sudo rm -rf /var/lib/apt/lists/* # && sudo rm -rf /usr/bin/apt*

RUN wget https://raw.githubusercontent.com/input-output-hk/cardano-node/$VERSION/cardano-submit-api/config/tx-submit-mainnet-config.yaml
RUN mv tx-submit-mainnet-config.yaml /etc/cardano-submit-api

COPY entrypoint.sh /home/guild/
ENTRYPOINT ["/home/guild/entrypoint.sh"]
