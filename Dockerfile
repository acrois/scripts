FROM alpine:latest

ENV LC_ALL=en_US.UTF-8

# install dependencies and change default shell from ash to bash
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk add \
    --update \
    bash \
    git \
    tar \
    coreutils \
    python3 \
  && apk add \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
    git-filter-repo \
  && sed -i -e "s/bin\/ash/bin\/bash/" /etc/passwd \
  && echo "" > /root/.ash_history

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

WORKDIR /etc/skel/
RUN echo -e "\nsource ~/scripts/config/.profile\n" >> .profile

WORKDIR /etc/skel/scripts/
COPY config.sh .
COPY config ./config

# ENV ENV="/home/you/.profile"
# RUN echo ". $HOME/.profile" > /etc/profile

# Copy all shell scripts, dereference links to get full files
RUN --mount=type=bind,source=.,target=/context cp -LR /context/shell ./shell

# Old way to copy shell scripts does not work with symlinks
# COPY shell ./shell

# add user and group
RUN addgroup -g 1000 you && \
  adduser -G you -u 1000 you -D && \
  adduser -G you -u 1001 gha -D

# USER 1000:1000
WORKDIR /run
