#!/bin/bash

# Good references include:
# - https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile
# - https://github.com/conda-forge/docker-images/blob/master/miniforge3/Dockerfile

# -e: end execution on error
# -u: error on undefined variable
# -o pipefail: error if any part of a pipe fails
set -e -o pipefail

#micromamba_url="${MICROMAMBA_URL:-https://micromamba.snakepit.net/api/micromamba/linux-64/latest}"
#install_dir="${TMP_INSTALL_DIR:-/tmp}"
#conda_dest="${CONDA_DEST:-/opt/conda}"
#python_ver="${PYTHON_VER:-3.8}"
#additional_packages="${PACKAGES:-}"

# if [ -z "$conda_dest" ]; then
#     if [ "$EUID" -eq 0 ]; then

#     else

#     fi
# fi

mkdir -p "${micromamba_install_dir}"
cd "${micromamba_install_dir}"
wget -qO- "${micromamba_url}" | tar -xvj bin/micromamba --strip-components=1
micromamba_cmd="${micromamba_install_dir}/micromamba"


mamba_init_script () {
    # Print a string with the bash code to initialize mamba.
    # If the following feature request is implemented, this should
    # consist of the code
    #
    #     ${micromamba_cmd} shell hook -s bash -p ${conda_dest}
    #
    # See: https://github.com/mamba-org/mamba/issues/498

    # Modify .bashrc.
    ${micromamba_cmd} shell init -s bash -p "${conda_dest}" > /dev/null

    # Strip and print modifications to .bashrc.
    sed -i -e '/^# >>> mamba initialize >>>/,/^# <<< mamba initialize <<</{w /dev/stdout' -e 'd}' ~/.bashrc

    # Delete trailing newline. https://unix.stackexchange.com/a/254753
    length=$(wc -c < ~/.bashrc)
    if [ "${length}" -ne 0 ] && [ -z "$(tail -c -1 < ~/.bashrc)" ]; then
        truncate -s -1 ~/.bashrc
    fi
}

setup_user () {

    # Set $conda_user if not already defined.
    if [ -z "${conda_user:-}" ]; then
        # $conda_user is undefined.
        if [ ! -z "${conda_uid:-}" ]; then
            # ...but gid is defined. Get the user it belongs to.
            conda_user=$(id -un "${conda_uid}")
        else
            # Just default to current user
            conda_user=$(whoami)
        fi
    fi

    if id -u "${conda_user}" > /dev/null 2>&1; then
        # $conda_user exists. Set uid and gid, checking consistency
        # if already set.
        if [ -z "${conda_uid:-}"]; then
            conda_uid=$(id -u)
        else
            # Raise error if uid defined but doesn't match.
            [ "${conda_uid}" -eq $(id -u) ]        
        fi
        if [ -z "${conda_gid:-}"]; then
            conda_gid=$(id -g)
        else
            # Raise error if uid defined but doesn't match.
            [ "${conda_gid}" -eq $(id -g) ]        
        fi
    else
        # $conda_user doesn't exist. Create it.
        extra_args=()
        if [ ! -z "${conda_uid:-}" ]; then
            extra_args+=( "-u" "${conda_uid}" )
        fi
        if [ ! -z "${conda_gid:-}" ]; then
            extra_args+=( "-g" "${conda_gid}" )
        fi

        useradd -m -s /bin/bash "${extra_args[@]}" "${conda_user}"

    fi

    conda_uid=$(id -u "${conda_user}")
    conda_gid=$(id -g "${conda_user}")

    echo "Ready to install conda for user ${conda_user} ${conda_uid}:${conda_gid}"
}

setup_user

conda_user_home=$(eval echo "~$conda_user")

if [ -z "${conda_dest:-}" ]; then
    # $conda_dest is undefined, so set a default value
    # which will become the conda prefix.
    if [ ${conda_uid} -eq 0 ]; then 
        # Conda user is root.
        conda_dest=/opt/conda
    else
        # Conda user isn't root. Install into conda subdir of their home.
        conda_dest="${conda_user_home}/conda"
    fi
fi

# Initialize bash to provide a micromamba bash function. (Confusingly, this
# function name conflicts with the name of the downloaded file.)
mamba_init_script_contents="$(mamba_init_script)"
eval "${mamba_init_script_contents}"

echo Destination: ${conda_dest}

set +u  # Avoid "_CE_CONDA: unbound variable".
micromamba activate  # No path here since this is now a bash function.
set -u

# Convert comma-separated lists into bash arrays.
IFS=',' read -r -a packages_array <<< "$packages"
IFS=',' read -r -a channels_array <<< "$channels"
if [ -z "${delete_files:-}" ]; then
    delete_files_array=()
else
    IFS=',' read -r -a delete_files_array <<< "$delete_files"
fi

channel_args=()

for channel in "${channels_array[@]}"; do
    channel_args+=( "-c" "$channel" )
done

# Do the install.
set +u
micromamba install -y "${packages_array[@]}" "${channel_args[@]}"
set -u

# Clean up.
# (Note: if conda isn't installed, then we won't clean the cache.)
if command -v conda &> /dev/null; then
    conda clean --all -f -y
fi

# Delete given unnecessary file types.
# e.g. set the build argument
#
#     delete_files=*.a,*.pyc,*.js.map
# Ref: https://jcristharif.com/conda-docker-tips.html
for ext in "${delete_files_array[@]}"; do
    find "${conda_dest}" -follow -type f -name "${ext}" -delete
done

# Recursively set permissions
chown -R ${conda_uid}:${conda_gid} "${conda_dest}"

# Initialize shell for $conda_user

conda_sh="${conda_dest}/etc/profile.d/conda.sh"

bashrc_files_array=( "${conda_user_home}/.bashrc" )


if [ -w "/etc/skel/.bashrc" ]; then
    bashrc_files_array+=( "/etc/skel/.bashrc" )
fi

if [ "$(id -u)" -ne $conda_uid ]; then
    bashrc_files_array+=( "~/.bashrc" )
fi

for bashrc_file in "${bashrc_files_array[@]}"; do

    if [ -f "${conda_sh}" ]; then

        echo "# Initialize conda." >> "${bashrc_file}"
        echo ". \"${conda_sh}\" && conda activate base" >> "${bashrc_file}"
        echo "# Initialized." >> "${bashrc_file}"

        # Now we have conda, so get rid of micromamba.
        rm -f "${micromamba_cmd}"

    else

        # There is no conda, so we need to keep micromamba.
        echo >> "${bashrc_file}"
        echo "${mamba_init_script_contents}" >> "${bashrc_file}"

    fi

    # TODO: initialize micromamba if neither conda nor mamba is installed.

done

# Self-destruct
rm $0
