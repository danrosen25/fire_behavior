FROM ubuntu:25.10

ARG VERSION="1.0.0"
ARG REVISION="1.0.0"

# Set environment variables
ENV SPACK_ROOT=/opt/spack \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    CFBM_DEVCONTAINER=ubuntu-25.10_gcc-15_mpich

LABEL org.opencontainers.image.title="cfbmdev_${CFBM_DEVCONTAINER}}" \
      org.opencontainers.image.description="CFBM Development Container: ${CFBM_DEVCONTAINER}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.vendor="NCAR-RAL-CFBM" \
      org.opencontainers.image.authors="jimenez@ucar.edu" \
      org.opencontainers.image.url="https://ral.ucar.edu/model/community-fire-behavior-model"

# Install system dependencies required by spack
RUN <<INSTALL_PACKAGES
    apt-get update
    apt-get install -yqq \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        file \
        g++-15 \
        gcc-15 \
        gfortran-15 \
        git \
        gpg \
        gzip \
        libc6-dev \
        libcurl4-openssl-dev \
        libmpich-dev \
        libnetcdf-dev \
        libnetcdff-dev \
        libssl-dev \
        locales \
        m4 \
        make \
        mpich \
        netcdf-bin \
        openssh-client \
        pkg-config \
        python3 \
        python3-dev \
        python3-pip \
        python3-yaml \
        tar \
        unzip \
        vim \
        wget \
        zlib1g-dev
    locale-gen en_US.UTF-8
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    ln -sf gcc-15 /usr/bin/gcc
    ln -sf g++-15 /usr/bin/g++
    ln -sf gfortran-15 /usr/bin/gfortran
    arch=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
    ln -sf "${arch}/libnetcdf.so" /usr/lib/libnetcdf.so
    ln -sf "${arch}/libnetcdff.so" /usr/lib/libnetcdff.so
    apt-get clean
INSTALL_PACKAGES

# Clone spack repository
RUN <<INSTALL_SPACK
    mkdir -p ${SPACK_ROOT}
    git clone --depth=2 --branch=releases/v1.1 https://github.com/spack/spack.git ${SPACK_ROOT}
INSTALL_SPACK

# Set up spack environment
ENV PATH="${SPACK_ROOT}/bin:${PATH}"

RUN <<EXTPKG_CONFIGURATION
    # Extract versions for external packages
    gcc_version="$(gcc -dumpfullversion -dumpversion)"
    cmake_version="$(cmake --version | head -n1 | awk '{ print $3 }')"
    mpich_version="$(mpichversion | awk -F': *' '/^MPICH Version:/ { print $2; exit }')"
    netcdf_c_version="$(nc-config --version | awk '{ print $2 }')"
    netcdf_fortran_version="$(nf-config --version | awk '{ print $2 }')"
    python_version="$(python3 --version | awk '{ print $2 }')"
    pip_version="$(pip3 --version | awk '{ print $2 }')"
    pyyaml_version="$(python3 -c 'import yaml; print(yaml.__version__)')"
    # Define spack specs for external packages
    cmake_spec="cmake@${cmake_version}%gcc@${gcc_version}"
    mpich_spec="mpich@${mpich_version}%gcc@${gcc_version}"
    netcdf_c_spec="netcdf-c@${netcdf_c_version}%gcc@${gcc_version}"
    netcdf_fortran_spec="netcdf-fortran@${netcdf_fortran_version}%gcc@${gcc_version}"
    python_spec="python@${python_version}"
    pip_spec="py-pip@${pip_version} ^${python_spec}"
    pyyaml_spec="py-pyyaml@${pyyaml_version}+libyaml ^${python_spec}"
    # Register external packages with spack
    . ${SPACK_ROOT}/share/spack/setup-env.sh
    spack config add "packages:cmake:externals:[{'spec': '${cmake_spec}', 'prefix': '/usr'}]"
    spack config add "packages:mpich:externals:[{'spec': '${mpich_spec}', 'prefix': '/usr'}]"
    spack config add "packages:netcdf-c:externals:[{'spec': '${netcdf_c_spec}', 'prefix': '/usr'}]"
    spack config add "packages:netcdf-fortran:externals:[{'spec': '${netcdf_fortran_spec}', 'prefix': '/usr'}]"
    spack config add "packages:py-pip:externals:[{'spec': '${pip_spec}', 'prefix': '/usr'}]"
    spack config add "packages:py-pyyaml:externals:[{'spec': '${pyyaml_spec}', 'prefix': '/usr'}]"
EXTPKG_CONFIGURATION

# Install spack packages
RUN <<PACKAGE_INSTALLATION
    . ${SPACK_ROOT}/share/spack/setup-env.sh
    spack compiler find
    spack external find
    spack install --fail-fast \
        cmake \
        mpich \
        netcdf-c \
        netcdf-fortran \
        python \
        py-pip \
        py-pyyaml \
        parallelio@2.6%gcc \
        esmf@8.8%gcc
    spack clean --all
PACKAGE_INSTALLATION

# Create environment
RUN <<SETUP_ENV
    mkdir -p /etc/profile.d
    mkdir -p /home/cfbm-dev
SETUP_ENV

# Copy spack setup script
COPY --chmod=0755 cfbm_spack.sh /etc/profile.d/cfbm_spack.sh

# Copy README file
COPY --chmod=0644 README.md /home/cfbm-dev/README.md

# Set bash as default shell
SHELL ["/bin/bash", "-c"]

# Set working directory
WORKDIR /home/cfbm-dev

# Default command
CMD ["/bin/bash", "-l"]
