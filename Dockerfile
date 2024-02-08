FROM nvidia/cuda:12.2.2-cudnn8-devel-rockylinux8 AS build
SHELL ["/bin/bash", "-c"]
RUN yum install dnf-plugins-core -y && \
    dnf config-manager --set-enabled powertools -y && \
    dnf install epel-release -y && \
    dnf --disablerepo=cuda update -y && \
    dnf install \
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
                uuid uuid-devel \
                tcl-devel  tcl \
                tk-devel  tk \
                sqlite-devel \
                gcc-toolset-12 \
                xmlto \
                asciidoc \
                docbook2X \
                gdbm-devel gdbm -y &&\
                dnf clean all
ENV PY_VERSION=3.11.8 
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
                --with-system-expat \
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
# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV LD_LIBRARY_PATH=/opt/python/py311/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/python/py311/bin:${PATH}
RUN ln  /opt/python/py311/bin/python3.11 /opt/python/py311/bin/python 
ENV PYTHON_PIP_VERSION 24.0
# https://github.com/docker-library/python/issues/365
ENV PYTHON_SETUPTOOLS_VERSION 69.0.3
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/049c52c665e8c5fd1751f942316e0a5c777d304f/public/get-pip.py
ENV PYTHON_GET_PIP_SHA256 7cfd4bdc4d475ea971f1c0710a5953bcc704d171f83c797b9529d9974502fcc6
RUN set -eux; \
	wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
	echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum -c -; \
	export PYTHONDONTWRITEBYTECODE=1; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		--no-compile \
		"pip==$PYTHON_PIP_VERSION" \
		"setuptools==$PYTHON_SETUPTOOLS_VERSION" \
	; \
	rm -f get-pip.py; \
	\
	pip --version ; \
    pip install --no-cache-dir -U wheel virtualenv build
CMD ["python"]
