FROM alpine:latest
RUN apk add --no-cache bash \
    && rm -rf /var/cache/*/* \
    && echo "" > /root/.ash_history

# change default shell from ash to bash
RUN sed -i -e "s/bin\/ash/bin\/bash/" /etc/passwd

ENV LC_ALL=en_US.UTF-8
ENV ENV="/etc/profile"
RUN echo ". $HOME/.profile" > /etc/profile
ENTRYPOINT [ "bash", "-l" ]

WORKDIR /root/scripts/

COPY config.sh .
COPY config ./config
RUN ./config.sh

COPY shell ./shell
