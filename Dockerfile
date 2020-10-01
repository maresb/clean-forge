ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

ARG INSTALL_PREREQ_SCRIPT=apt-install-prereqs.sh
COPY scripts/${INSTALL_PREREQ_SCRIPT} /tmp/install-prereqs
RUN /tmp/install-prereqs


ARG micromamba_url=https://micromamba.snakepit.net/api/micromamba/linux-64/latest
ARG micromamba_install_dir=/tmp
ARG conda_dest=/opt/conda
ARG conda_user=condauser
ARG conda_uid=1000
ARG conda_gid=100
ARG delete_files

# Comma-separated lists
ARG packages=python=3.8,conda,mamba,xonsh
ARG channels=conda-forge

COPY scripts/clean-install-mamba.sh /tmp
RUN /tmp/clean-install-mamba.sh
