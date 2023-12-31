FROM nvidia/cuda:12.2.2-cudnn8-devel-rockylinux8 AS build
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
                gcc-toolset-12 \
                xmlto \
                asciidoc \
                docbook2X \
                gdbm-devel gdbm -y &&\
                dnf clean all
ENV PY_VERSION=3.11.7 
ENV INST_PREFIX=/opt/python/py311
RUN mkdir /tmp/bpython && cd /tmp/bpython; \
    wget -qO- https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tar.xz | xzcat | tar xv && \
    cd Python-${PY_VERSION} && \ 
    source scl_source enable gcc-toolset-12 && ./configure --enable-shared \
                --enable-loadable-sqlite-extensions \
                --enable-optimizations \ 
                --enable-option-checking=fatal \
                --enable-shared \
                --enable-ipv6 \ 
                --with-lto=full \
                --without-ensurepip \
                --prefix=${INST_PREFIX} && \
                source scl_source enable gcc-toolset-12 && \
                EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000"; \
                LDFLAGS="${LDFLAGS:--Wl},--strip-all"; \
                make -j 8 \
                "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
                "LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" \
                "PROFILE_TASK=${PROFILE_TASK:-}" \
                python \
                ; \
                make install; \
                \
                cd /; \
                rm -rf /tmp/bpython; \
                \
                find ${INST_PREFIX} -depth \
                    \( \
                        \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
                        -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
                    \) -exec rm -rf '{}' + \
                ; 
ENV LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/python/py311/bin:${PATH}
RUN ln  /opt/python/py311/bin/python3.11 /opt/python/py311/bin/python \
    && ln /opt/python/py311/bin/pip3 /opt/python/py311/bin/pip
RUN pip3 install --no-cache-dir -U pip
RUN pip3 install --no-cache-dir -U wheel setuptools virtualenv build twine
