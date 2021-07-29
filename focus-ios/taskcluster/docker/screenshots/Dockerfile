# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

FROM ubuntu:18.04

MAINTAINER Johan Lorenzo "jlorenzo+docker@mozilla.com"

# Add worker user
RUN mkdir /builds && \
    useradd -d /builds/worker -s /bin/bash -m worker && \
    chown worker:worker /builds/worker && \
    mkdir /builds/worker/artifacts && \
    chown worker:worker /builds/worker/artifacts

WORKDIR /builds/worker/


ENV CURL='curl --location --retry 5' \
    LANG='en_US.UTF-8' \
    TERM='dumb'


RUN apt-get update -qq \
    # We need to install tzdata before all of the other packages. Otherwise it will show an interactive dialog that
    # we cannot navigate while building the Docker image.
    && apt-get install -y tzdata \
    && apt-get install -y curl \
                          git \
                          locales \
                          mercurial \
                          python3 \
                          python3-pip \
    && apt-get clean

RUN pip3 install --upgrade pip
COPY requirements.txt ./
RUN pip3 install -r requirements.txt

RUN locale-gen "$LANG"

# %include-run-task

ENV SHELL=/bin/bash \
    HOME=/builds/worker \
    PATH="/builds/worker/.local/bin:$PATH"


VOLUME /builds/worker/checkouts
VOLUME /builds/worker/.cache


# run-task expects to run as root
USER root
