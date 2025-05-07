FROM continuumio/miniconda3:latest

# Set channels for conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge

# Install build-essential (make/gcc), required libraries, and packages via Bioconda
RUN apt-get update && apt-get install -y build-essential && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN conda install -y \
    perl \
    perl-dbi \
    perl-dbd-sqlite \
    perl-forks \
    perl-file-which \
    perl-perl-unsafe-signals \
    perl-inline-c \
    perl-io-all \
    perl-io-prompt \
    perl-bioperl \
    perl-bit-vector \
    perl-lwp-simple \
    repeatmasker \
    repeatmodeler \
    rmblast \
    blast \
    snap \
    augustus \
    exonerate \
    emboss \
    hmmer \
    cdbfasta \
    zlib && \
    conda clean -afy

# Copy your local MAKER installation archive
COPY maker-3.01.04.tgz /opt/

# Install MAKER manually
WORKDIR /opt
RUN tar -xzf maker-3.01.04.tgz && \
    rm maker-3.01.04.tgz && \
    cd maker/src && \
    perl Build.PL && \
    echo "yes" | ./Build installdeps && \
    ./Build installexes && \
    ./Build install

# Environment variables for MAKER
ENV PATH="/opt/maker/bin:${PATH}"
ENV ZOE="/opt/conda/share/snap/Zoe"
ENV AUGUSTUS_CONFIG_PATH="/opt/conda/config"

# Default working directory
WORKDIR /data

CMD ["/bin/bash"]

