ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

ARG INSTALL_PREREQ_SCRIPT=apt-install-prereqs.sh
COPY scripts/${INSTALL_PREREQ_SCRIPT} /tmp/install-prereqs
RUN /tmp/install-prereqs


ARG micromamba_url=https://micromamba.snakepit.net/api/micromamba/linux-64/latest
ARG micromamba_install_dir=/tmp
ARG conda_dest
ARG conda_user
ARG conda_uid
ARG conda_gid
ARG delete_files

# Comma-separated lists
ARG packages=python=3.8,conda,mamba
ARG channels=conda-forge

COPY scripts/clean-install-mamba.sh /tmp
RUN /tmp/clean-install-mamba.sh
