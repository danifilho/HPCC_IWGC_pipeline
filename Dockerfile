# Use Ubuntu 22.04 base image
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# --- Install System Dependencies ---
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    cpanminus \
    libdb-dev \
    libexpat1-dev \
    libgd-dev \
    liblocal-lib-perl \
    libpng-dev \
    zlib1g-dev \
    libssl-dev \
    libbz2-dev \
    liblzma-dev \
    libberkeleydb-dev \
    ncbi-blast+ \        # NCBI BLAST+ instead of WuBlast
    exonerate \          # Exonerate from Ubuntu repo
    openmpi-bin \        # MPI support (OpenMPI)
    libopenmpi-dev \
    && rm -rf /var/lib/apt/lists/*

# --- Install Perl Modules ---
RUN cpanm --notest --force \
    DBI \
    DBD::SQLite \
    forks \
    forks::shared \
    File::Which \
    Perl::Unsafe::Signals \
    Bit::Vector \
    Inline::C \
    IO::All \
    IO::Prompt \
    Log::Log4perl \
    YAML \
    Want

# --- Install BioPerl ---
RUN apt-get update && apt-get install -y \
    libbio-perl-perl \   # BioPerl from Ubuntu repo
    && rm -rf /var/lib/apt/lists/*

# --- Install SNAP ---
RUN git clone https://github.com/KorfLab/SNAP /opt/snap \
    && cd /opt/snap \
    && make \
    && chmod a+x snap

ENV ZOE="/opt/snap/Zoe"

# --- Install RepeatMasker (with RMBlast) ---
WORKDIR /opt
RUN wget http://www.repeatmasker.org/RepeatMasker/RepeatMasker-4.1.5.tar.gz \
    && tar -xzvf RepeatMasker-4.1.5.tar.gz \
    && rm RepeatMasker-4.1.5.tar.gz \
    && mv RepeatMasker RepeatMasker

# Install TRF (must be done separately due to EULA)
WORKDIR /opt/RepeatMasker
RUN wget http://www.repeatmasker.org/trf/trf407b.linux64 \
    && mv trf407b.linux64 trf \
    && chmod a+x trf

# Install RMBlast
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/rmblast/2.11.0/ncbi-rmblastn-2.11.0-x64-linux.tar.gz \
    && tar -xzvf ncbi-rmblastn-2.11.0-x64-linux.tar.gz \
    && mv ncbi-rmblastn-2.11.0/bin/rmblastn . \
    && chmod a+x rmblastn \
    && rm -rf ncbi-rmblastn-*

# Configure RepeatMasker (non-interactive)
RUN /bin/echo -e "\n\n\n\n\n\n" | perl ./configure \
    -libdir /opt/RepeatMasker/Libraries \
    -trf_prgm /opt/RepeatMasker/trf \
    -rmblast_dir /opt/RepeatMasker

# --- Install MAKER ---
WORKDIR /opt
RUN git clone https://github.com/Yandell-Lab/maker.git \
    && cd maker/src \
    && perl Build.PL \
    && ./Build installdeps \
    && ./Build installexes \
    && ./Build install

# --- Set Environment Variables ---
ENV PATH="/opt/maker/bin:/opt/snap:/opt/RepeatMasker:$PATH"
ENV PERL5LIB="/opt/maker/lib/perl5:$PERL5LIB"
ENV LD_PRELOAD="/usr/lib/x86_64-linux-gnu/openmpi/lib/libmpi.so"  # For OpenMPI

# --- Create Non-Root User ---
RUN useradd -m -U maker \
    && chown -R maker:maker /opt/maker /opt/snap /opt/RepeatMasker

USER maker
WORKDIR /home/maker

# --- Copy MAKER Control Files ---
COPY --chown=maker:maker maker_opts.ctl maker_bopts.ctl maker_exe.ctl ./

CMD ["maker"]
