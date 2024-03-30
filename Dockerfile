FROM alpine:latest
RUN apk add --no-cache bash git \
    && rm -rf /var/cache/*/* \
    && echo "" > /root/.ash_history

# add user and group, change default shell from ash to bash
RUN addgroup -g 1000 you && \
  adduser -G you -u 1000 you -D && \
  sed -i -e "s/bin\/ash/bin\/bash/" /etc/passwd

USER 1000:1000

ENV LC_ALL=en_US.UTF-8
# ENV ENV="/home/you/.profile"
# RUN echo ". $HOME/.profile" > /etc/profile
ENTRYPOINT [ "bash", "-l" ]

WORKDIR /home/you/scripts/

COPY config.sh .
COPY config ./config
RUN ./config.sh

RUN --mount=type=bind,source=.,target=/context cp -LRa /context/shell ./shell
#COPY shell ./shell

WORKDIR /run
