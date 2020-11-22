FROM ubuntu:bionic

ENV WORK_DIR=/home/esp32

WORKDIR ${WORK_DIR}

# INSTALL DEPENDENCIES

RUN apt-get update && \
    apt-get install -y \
    git \
    wget \
    flex \
    bison \
    gperf \
    python \
    python-pip \
    python-setuptools \
    python3 \
    python3-pip \
    python-serial \
    cmake \
    ninja-build \
    ccache \
    libffi-dev \
    libssl-dev \
    dfu-util
    
RUN pip3 install "pyparsing==2.3.1"

# CROSS-COMPILER

RUN wget https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz && \
    mkdir esp && \
    cd esp && \
    tar -zxvf ../xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz

ENV PATH="${WORK_DIR}/esp/xtensa-esp32-elf/bin:${PATH}"

# Clone ESPIDF

WORKDIR ${WORK_DIR}

RUN git clone https://github.com/espressif/esp-idf.git

# PYCOPY

ARG REPO=https://github.com/pfalcon/pycopy

RUN git clone ${REPO} micropython

WORKDIR ${WORK_DIR}/micropython

ARG BRANCH=v3.3.2

RUN git fetch origin ${BRANCH} && \
    git checkout ${BRANCH} && \
    cd ports/esp32/

WORKDIR ${WORK_DIR}/micropython

RUN git submodule update --init

RUN make -C mpy-cross && \
    git submodule init lib/berkeley-db-1.xx && \
    git submodule update

WORKDIR ${WORK_DIR}/micropython/ports/esp32

RUN echo "ESPIDF = /home/esp32/esp-idf" >> makefile && \
    echo "#PORT = /dev/ttyUSB0" >> makefile && \
    echo "#FLASH_MODE = qio" >> makefile && \
    echo "#FLASH_SIZE = 4MB" >> makefile && \
    echo "#CROSS_COMPILE = xtensa-esp32-elf-" >> makefile && \
    echo "" >> makefile && \
    echo "include Makefile" >> makefile && \
    cat makefile

# Extract ESPIDF commit hash from Makefile
RUN grep -oP '^ESPIDF_SUPHASH_V3 ?:= ?\K(.*)$' Makefile > ${WORK_DIR}/espdif_suphash_v3 && \
    printf "ESPIDF_SUPHASH_V3 = %s\n" $(cat ${WORK_DIR}/espdif_suphash_v3)

# ESPIDF

WORKDIR ${WORK_DIR}

RUN export ESPIDF_SUPHASH_V3=$(cat ${WORK_DIR}/espdif_suphash_v3) && \
    cd esp-idf && \
    git fetch origin ${ESPIDF_SUPHASH_V3} && \
    git checkout ${ESPIDF_SUPHASH_V3} && \
    git submodule update --init && \
    cd components/mbedtls/ && \
    rm -rf mbedtls && \
    git clone -b mbedtls-2.16.5-idf-pycopy https://github.com/pfalcon/mbedtls/

# COMPILE FIRMWARE

WORKDIR ${WORK_DIR}/micropython/ports/esp32

RUN git checkout ${BRANCH}

# Set double precision floats if set
ARG DOUBLE_PRECISION_FLOATS=false
RUN if [ "$DOUBLE_PRECISION_FLOATS" = "true" ]; then \
        echo "\e[32mDouble precision floats\e[39m"; \
        sed -i 's/MICROPY_FLOAT_IMPL_FLOAT/MICROPY_FLOAT_IMPL_DOUBLE/g' mpconfigport.h; \
    fi

# Copy the module file/directory (if set) into /modules
ARG MODULES_PATH=''
COPY ${MODULES_PATH} /temp/

RUN if [ -z $MODULES_PATH ]; then \
        rm -R /temp; \
    else \
        echo "\e[32mCopying files to modules...\e[39m"; \
        ls /temp | sed -e 's/^/    - /'; \
        mv /temp/* modules; \
    fi

# Build the image
RUN make
