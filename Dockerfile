FROM  nvidia/cuda:11.8.0-cudnn8-devel-rockylinux8 AS build
SHELL ["/bin/bash", "-c"]
ENV PY_VERSION=3.11.4
RUN dnf install epel-release -y
RUN /usr/bin/crb enable
RUN dnf update --disablerepo=cuda -y
RUN dnf install \
                curl \
                perl-devel \
                libcurl-devel \
                expat-devel \
                gettext-devel \
                gcc \
                cmake \
                openssl-devel \
                bzip2-devel \
                xz xz-devel \
                findutils \
                libffi-devel \
                zlib-devel \
                wget \
                make \
                ncurses ncurses-devel \
                readline-devel \
                uuid \
                tcl-devel tcl tk-devel tk \
                sqlite-devel \
                #tensorrt-8.5.3.1-1.cuda11.8 \
                #tensorrt-8.6.0.12-1.cuda11.8 \
                gcc-toolset-11 \
                xmlto \
                asciidoc \
                docbook2X \
                gdbm-devel gdbm -y
WORKDIR /tmp/bpython
RUN wget https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tar.xz
RUN tar -xf  Python-${PY_VERSION}.tar.xz
WORKDIR /tmp/bpython/Python-${PY_VERSION}
RUN source scl_source enable gcc-toolset-11 && ./configure --enable-shared \
                --enable-optimizations \ 
                --enable-ipv6 \ 
                --with-lto=full \
                --with-ensurepip=upgrade \
                --prefix=/opt/python/py311
RUN source scl_source enable gcc-toolset-11 && make -j 8
RUN source scl_source enable gcc-toolset-11 && make install 
ENV LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/python/py311/bin:${PATH}
RUN pip3 install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir wheel