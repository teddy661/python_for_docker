FROM  nvidia/cuda:11.8.0-cudnn8-devel-rockylinux8 AS build
SHELL ["/bin/bash", "-c"]
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
                gcc-toolset-11 \
                xmlto \
                asciidoc \
                docbook2X \
                gdbm-devel gdbm -y
WORKDIR /tmp/bpython
ENV PY_VERSION=3.11.6
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
RUN ln  /opt/python/py311/bin/python3.11 /opt/python/py311/bin/python \
    && ln /opt/python/py311/bin/pip3 /opt/python/py311/bin/pip
RUN pip3 install --no-cache-dir -U pip
RUN pip3 install --no-cache-dir -U wheel setuptools