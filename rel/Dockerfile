FROM ubuntu:18.04

ENV REFRESHED_AT=2021-02-28 \
    LANG=en_US.UTF-8 \
    TERM=xterm

WORKDIR /opt/build

RUN \
  apt-get update -y && \
  apt-get install -y git wget vim locales gnupg2 build-essential && \
  locale-gen en_US.UTF-8 && \
  wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
  dpkg -i erlang-solutions_2.0_all.deb && \
  rm erlang-solutions_2.0_all.deb && \
  wget https://deb.nodesource.com/setup_14.x && \
  bash setup_14.x && \
  rm setup_14.x && \
  apt-get update -y && \
  apt-get install -y esl-erlang=1:23.2.3-1 elixir=1.11.2-1 nodejs=14.16.0-1nodesource1 

RUN mix local.rebar --force && \
    mix local.hex --force && \
    mix archive.install --force \
      github avdi/dotenv_elixir \
      ref 11effeb0ff8519ddeb04dbbbe2e56f071f830fd0

RUN wget https://dl.yarnpkg.com/debian/pubkey.gpg && \
    apt-key add pubkey.gpg && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" \
      > "/etc/apt/sources.list.d/yarn.list" && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends yarn

CMD ["/bin/bash"]
