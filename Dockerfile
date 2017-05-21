#
# MIT License
#
# Copyright (c) 2017 Michael Kenney
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
FROM php:7
ENV DEBIAN_FRONTEND noninteractive

##############################################################################
# Configurations
##############################################################################

ENV HOSTNAME 'devenv'
ENV TERM xterm

ENV PATH /root/bin:$PATH

ENV UTF8_LOCALE en_US
ENV TIMEZONE 'America/Denver'

ENV ORACLE_VERSION_LONG 11.2.0.3.0-2
ENV ORACLE_VERSION_SHORT 11.2
ENV ORACLE_HOME /usr/lib/oracle/${ORACLE_VERSION_SHORT}/client64
ENV LD_LIBRARY_PATH ${ORACLE_HOME}/lib
ENV TNS_ADMIN /home/dev/.oracle/network/admin
ENV CFLAGS "-I/usr/include/oracle/${ORACLE_VERSION_SHORT}/client64/"
ENV NLS_LANG American_America.AL32UTF8

##############################################################################
# Upgrade
##############################################################################

RUN set -x \
    && cd / \
    && mkdir -p /src \
    && apt-get -qq update \
    && apt-get install -qqy apt-utils \
    && apt-get -qq upgrade \
    && apt-get -qq dist-upgrade

##############################################################################
# UTF-8 Locale, timezone
##############################################################################

RUN set -x \
    && apt-get install -qqy locales \
    && locale-gen C.UTF-8 ${UTF8_LOCALE} \
    && dpkg-reconfigure locales \
    && /usr/sbin/update-locale LANG=C.UTF-8 LANGUAGE=C.UTF-8 LC_ALL=C.UTF-8 \
    && export LANG=C.UTF-8 \
    && export LANGUAGE=C.UTF-8 \
    && export LC_ALL=C.UTF-8 \
    && echo ${TIMEZONE} > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

# set this here, c.utf-8 doesn't exist until now
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

##############################################################################
# Apt Packages
##############################################################################

RUN set -x \
    && apt-get install -qqy \
        autogen \
        automake \
        build-essential \
        cmake \
        curl \
        dialog \
        emacs24 \
        exuberant-ctags \
        gcc \
        git \
        golang \
        graphviz \
        htop \
        less \
        libevent-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libncurses5-dev \
        libpng12-dev \
        libbz2-dev \
        libaio1 \
        libpq-dev \
        libyaml-dev \
        locate \
        man \
        mysql-client \
        ncurses-dev \
        openssh-client \
        openssh-server \
        powerline \
        python \
        python-dev \
        python-pip \
        python3 \
        python3-dev \
        python3-pip \
        python-powerline \
        python-powerline-doc \
        rsync \
        rsyslog \
        ruby \
        ruby-dev \
        sbcl \
        silversearcher-ag \
        slime \
        sshfs \
        sudo \
        tcpdump \
        telnet \
        unzip \
        wget \
        zsh

##############################################################################
# pinned nodejs version from source
##############################################################################

ENV NODE_VERSION v7.7.4
ENV NODE_PREFIX /usr/local
RUN set -x \
    # build requirements
    && apt-get install -qqy \
        paxctl \
    # Download and validate the NodeJs source
#    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
#        9554F04D7259F04124DE6B476D5A82AC7E37093B \
#        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
#        0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
#        FD3A5288F042B6850C66B31F09FE44734EB7990E \
#        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
#        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
#        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
#        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    && mkdir /node_src \
    && cd /node_src \
    && curl -o node-${NODE_VERSION}.tar.gz -sSL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.tar.gz \
#    && curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt.asc \
#    && gpg --verify SHASUMS256.txt.asc \
#    && grep node-${NODE_VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - \

    # Compile and install
    && cd /node_src \
    && tar -zxf node-${NODE_VERSION}.tar.gz \
    && cd node-${NODE_VERSION} \
    && export GYP_DEFINES="linux_use_gold_flags=0" \
    && ./configure --prefix=${NODE_PREFIX} \
    && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && make -j${NPROC} -C out mksnapshot BUILDTYPE=Release \
    && paxctl -cm out/Release/mksnapshot \
    && make -j${NPROC} \
    && make install \
    && paxctl -cm ${NODE_PREFIX}/bin/node \
    && cd / \
    && rm -rf /node_src

##############################################################################
# current npm and node tools
##############################################################################

RUN set -x \
    # Upgrade npm
    # Don't use npm to self-upgrade, see issue https://github.com/npm/npm/issues/9863
    && curl -L https://npmjs.org/install.sh | sh \

    # Install node packages
    && npm install --silent -g \
        bower \
        grunt-cli \
        gulp-cli \
        markdown-styles \
        typescript \
        yarn

##############################################################################
# latest vim from source
##############################################################################

RUN set -x \
    # install latest vim from source
    && git clone https://github.com/vim/vim \
    && cd vim \
    && make distclean \
    && ./configure \
        --with-features=huge \
        --enable-perlinterp \
        --enable-pythoninterp \
        --enable-python3interp \
        --enable-rubyinterp \
    && make \
    && make install \
    && cd /

##############################################################################
# current tmux from source
##############################################################################

RUN set -x \
    # install current tmux
    && curl -OL https://github.com/tmux/tmux/releases/download/2.4/tmux-2.4.tar.gz \
    && tar xf tmux-2.4.tar.gz \
    && cd tmux-2.4 \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -f tmux-2.4.tar.gz \
    && rm -rf tmux-2.4
