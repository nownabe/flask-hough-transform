FROM alpine:3.5
MAINTAINER nownabe

ENV PATH /usr/local/bin:$PATH
ENV LANG C.UTF-8

ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION 3.6.0
ENV PYTHON_PIP_VERSION 9.0.1

RUN apk update --no-cache \
  && apk add --no-cache ca-certificates \

  # fetch python
  && apk add --no-cache --virtual .fetch-deps \
    gnupg openssl tar xz \
  && wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
  && wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
  && gpg --batch --verify python.tar.xz.asc python.tar.xz \
  && rm -r "$GNUPGHOME" python.tar.xz.asc \

  # build & install python
  && apk add --no-cache --virtual .build-deps \
    bzip2-dev \
    gcc \
    gdbm-dev \
    libc-dev \
    linux-headers \
    make \
    ncurses-dev \
    openssl-dev \
    pax-utils \
    readline-dev \
    sqlite-dev \
    tcl-dev \
    tk \
    tk-dev \
    xz-dev \
    zlib-dev
RUN apk add --no-cache musl zlib openssl
RUN mkdir -p /usr/src/python \
  && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
  && rm python.tar.xz \
  && cd /usr/src/python \
  && ./configure \
    --enable-loadable-sqlite-extensions \
    --enable-shared \
    --enable-optimization \
  && make -j $(getconf _NPROCESSORS_ONLN) \
  && make install \
  && cd \

  # create links
  && ln -s /usr/local/bin/idle3 /usr/local/bin/idle \
  && ln -s /usr/local/bin/pydoc3 /usr/local/bin/pydoc \
  && ln -s /usr/local/bin/python3 /usr/local/bin/python \
  && ln -s /usr/local/bin/python3-config /usr/local/bin/python-config \
  && ln -s /usr/local/bin/pip3 /usr/local/bin/pip \
  && ln -s /usr/local/bin/easy_install-3.6 /usr/local/bin/easy_install \

  # clean up
  && apk del .build-deps .fetch-deps \
  && rm -rf /usr/src/python ~/.cache \
  && find /usr/local -depth \
    \( \
      \( -type d -a -name test -o -name tests \) \
      -o \
      \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
    \) -exec rm -rf '{}' +

# OpenCV

ENV OPENCV_VERSION 3.1.0

RUN apk update --no-cache \
  && apk add --no-cache --virtual .build-deps \
    curl \
    make \
    cmake \
    gcc \
    g++ \
    pkgconf \
    linux-headers
# build deps
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h

RUN pip install numpy

RUN curl -sLS -o opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip
RUN unzip -d /usr/src opencv.zip
RUN rm opencv.zip
RUN mkdir /usr/src/opencv-${OPENCV_VERSION}/build
  # https://github.com/opencv/opencv/blob/master/CMakeLists.txt
RUN cd /usr/src/opencv-${OPENCV_VERSION}/build && cmake \
    # optional 3rd party components
    -D WITH_FFMPEG=NO \
    -D WITH_IPP=NO \
    -D WITH_OPENEXR=NO \

    # OpenCV build components
    -D BUILD_TESTS=NO \
    -D BUILD_PERF_TESTS=NO \
    # 3rd party libs
    -D BUILD_TIFF=YES \

    # OpenCV installation options
    # OpenCV build options

    # Others
    -D BUILD_opencv_java=NO \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D PYTHON_EXECUTABLE=/usr/local/bin/python \

    .. \
  && make -j $(getconf _NPROCESSORS_ONLN) \
  && make install

RUN apk del .build-deps \
  && rm -r /usr/src/opencv-${OPENCV_VERSION} ~/.cache /var/cache/apk/*

RUN apk add --no-cache --update libstdc++

RUN python -c "import cv2"


######## app ########

RUN mkdir /usr/src/app
WORKDIR /usr/src/app

ADD requirements.txt /usr/src/app/requirements.txt
RUN pip install -r requirements.txt
COPY . /usr/src/app

CMD python app.py

# #2 Add Edge and bleeding repos
# RUN echo -e '@edgunity http://nl.alpinelinux.org/alpine/edge/community\n@edge http://nl.alpinelinux.org/alpine/edge/main\n@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories
# #4
# RUN apk add --update \
# build-base \
# gsl \
# libavc1394-dev  \
# libtbb@testing  \
# libtbb-dev@testing   \
# libjpeg  \
# libjpeg-turbo-dev \
# libpng-dev \
# libjasper \
# libdc1394-dev \
# clang-dev \
# clang \
# tiff-dev \
# libwebp-dev \
# py-numpy-dev@edgunity \
# py-scipy-dev@testing \
# openblas-dev@edgunity \

# build-essential \
# yasm \
# pkg-config \
# libswscale-dev \
# libtbb2 \
# libtbb-dev \
# libjpeg-dev \
# libpng-dev \
# libtiff-dev \
# libjasper-dev \
# libavformat-dev \
#         libpq-dev
