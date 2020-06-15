FROM ubuntu:bionic

ARG REPO=https://github.com/pfalcon/pycopy
ARG BRANCH=v3.1.5
ARG DOUBLE_PRECISION_FLOATS=false

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

# PYCOPY

RUN git clone ${REPO} micropython && \
    cd micropython && \
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

RUN git clone https://github.com/espressif/esp-idf.git

RUN export ESPIDF_SUPHASH_V3=$(cat ${WORK_DIR}/espdif_suphash_v3) && \
    cd esp-idf && \
    git checkout ${ESPIDF_SUPHASH_V3} && \
    git submodule update --init

# COMPILE FIRMWARE

WORKDIR ${WORK_DIR}/micropython/ports/esp32

# Set double precision floats if set
RUN if [ "$DOUBLE_PRECISION_FLOATS" = "true" ]; then \
        echo "\e[32mDouble precision floats\e[39m"; \
        sed -i 's/MICROPY_FLOAT_IMPL_FLOAT/MICROPY_FLOAT_IMPL_DOUBLE/g' mpconfigport.h; \
    fi

RUN make
