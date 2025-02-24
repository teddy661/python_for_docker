FROM nvidia/cuda:12.6.0-cudnn-devel-rockylinux9 AS build
SHELL ["/bin/bash", "-c"]
RUN yum install dnf-plugins-core -y && \
    dnf config-manager --enable crb -y && \
    dnf install epel-release -y && \
    dnf --disablerepo=cuda update -y && \
    /usr/bin/crb enable && \
    dnf builddep python3 -y && \
    dnf install \
                perl-devel \
                libcurl-devel \
                gettext-devel \
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
ARG PY_VERSION=3.13.2
ARG PY_THREE_DIGIT=313
LABEL maintainer="me@here.com"
LABEL version="${PY_VERSION}"
LABEL description="Python ${PY_VERSION} with CUDA support"
ENV INST_PREFIX=/opt/python/py${PY_THREE_DIGIT}
RUN mkdir /tmp/bpython && cd /tmp/bpython; \
    wget -qO- https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tar.xz | xzcat | tar xv 
WORKDIR /tmp/bpython/Python-${PY_VERSION} 
RUN  source scl_source enable gcc-toolset-12 && ./configure --enable-shared \
                --enable-loadable-sqlite-extensions \
                --enable-optimizations \ 
                --enable-option-checking=fatal \
                --enable-shared \
                --enable-ipv6 \ 
                --with-lto=full \
                --with-ensurepip=upgrade \
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
ENV LD_LIBRARY_PATH=/opt/python/py${PY_THREE_DIGIT}/lib:${LD_LIBRARY_PATH}
ENV PATH=/opt/python/py${PY_THREE_DIGIT}/bin:${PATH}
RUN ln  /opt/python/py${PY_THREE_DIGIT}/bin/python3.13 /opt/python/py${PY_THREE_DIGIT}/bin/python 
ENV PYTHON_PIP_VERSION=25.0
# https://github.com/docker-library/python/issues/365
ENV PYTHON_SETUPTOOLS_VERSION=75.8.0
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL=https://raw.githubusercontent.com/pypa/get-pip/refs/tags/25.0/public/get-pip.py
ENV PYTHON_GET_PIP_SHA256=520a8d927fc19295fdd42a69b01c4dc690111ebd86af59313299d6fb8f51d496
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
