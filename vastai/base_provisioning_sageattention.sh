#!/bin/bash

# Base provisioning functions for ComfyUI scripts
# This file should be hosted online and downloaded by individual scripts

# Ensure we're in the right environment
if [[ -z "$DATA_DIRECTORY" ]]; then
    echo "ERROR: DATA_DIRECTORY environment variable not set"
    exit 1
fi

COMFYUI_DIR=${DATA_DIRECTORY}/ComfyUI

# Default download utility preferences
USE_ARIA2C=${USE_ARIA2C:-true}
ARIA2C_MAX_CONN=${ARIA2C_MAX_CONN:-4}
ARIA2C_SPLIT=${ARIA2C_SPLIT:-4}

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages

    # Download workflows if defined
    if [[ -n "${WORKFLOWS[@]}" ]]; then
        workflows_dir="${COMFYUI_DIR}/user/default/workflows"
        mkdir -p "${workflows_dir}"
        provisioning_get_files "${workflows_dir}" "${WORKFLOWS[@]}"
    fi

    # Download all model types
    provisioning_get_files "${COMFYUI_DIR}/models/checkpoints" "${CHECKPOINT_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/unet" "${UNET_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/diffusion_models" "${DIFFUSION_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/loras" "${LORA_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/controlnet" "${CONTROLNET_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/vae" "${VAE_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/text_encoders" "${TEXT_ENCODERS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/upscale_models" "${ESRGAN_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/clip" "${CLIP_MODELS[@]}"

    provisioning_print_end
}

function provisioning_get_apt_packages() {
    if [[ -n "${APT_PACKAGES[@]}" ]]; then
        printf "Updating package index...\n"
        sudo apt update
        printf "Installing APT packages: %s\n" "${APT_PACKAGES[*]}"
        sudo apt install -y "${APT_PACKAGES[@]}"
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n "${PIP_PACKAGES[@]}" ]]; then
        printf "Installing PIP packages: %s\n" "${PIP_PACKAGES[*]}"
        pip install --no-cache-dir "${PIP_PACKAGES[@]}"
    fi

    # Install SageAttention from source
    printf "Installing SageAttention from source...\n"
    cd /tmp
    git clone https://github.com/thu-ml/SageAttention.git
    cd SageAttention
    export EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 8" MAX_JOBS=32
    pip install -e .
    cd /
    rm -rf /tmp/SageAttention
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${COMFYUI_DIR}/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"

        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                [[ -e $requirements ]] && pip install --no-cache-dir -r "$requirements"
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            [[ -e $requirements ]] && pip install --no-cache-dir -r "$requirements"
        fi
    done
}

function provisioning_get_files() {
    [[ -z $2 ]] && return 0  # Return 0 instead of 1 for empty arrays

    local dir="$1"
    mkdir -p "$dir"
    shift
    local arr=("$@")

    [[ ${#arr[@]} -eq 0 ]] && return 0  # Skip if no files

    printf "Downloading %s file(s) to %s...\n" "${#arr[@]}" "$dir"
    for entry in "${arr[@]}"; do
        local url=""
        local custom_name=""

        # Parse URL|Name format
        if [[ "$entry" == *"|"* ]]; then
            url="${entry%|*}"
            custom_name="${entry#*|}"
        else
            url="$entry"
        fi

        printf "Downloading: %s\n" "${url}"
        [[ -n "$custom_name" ]] && printf "Saving as: %s\n" "$custom_name"

        provisioning_download "$url" "$dir" "$custom_name"
        printf "\n"
    done
}

function provisioning_download() {
    local url="$1"
    local destination="$2"
    local custom_filename="$3"
    local auth_header=""
    local download_url="$url"
    local extracted_filename=""

    # Handle authentication and extract filenames
    if [[ -n $HF_TOKEN && $url =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_header="Authorization: Bearer $HF_TOKEN"
        # Extract filename from HuggingFace URL if no custom filename provided
        if [[ -z "$custom_filename" ]]; then
            # Remove query parameters and extract filename from path
            local clean_url="${url%\?*}"
            extracted_filename="${clean_url##*/}"
            # If extracted filename is empty or looks like a directory, use a fallback
            if [[ -z "$extracted_filename" || "$extracted_filename" == *"/" ]]; then
                extracted_filename="huggingface_download_$(date +%s)"
            fi
        fi
    elif [[ -n $CIVITAI_TOKEN && $url =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        # For Civitai, append token as URL parameter
        if [[ $url == *"?"* ]]; then
            download_url="${url}&token=${CIVITAI_TOKEN}"
        else
            download_url="${url}?token=${CIVITAI_TOKEN}"
        fi
    fi

    # Use custom filename, extracted filename, or let the downloader decide
    local final_filename="${custom_filename:-$extracted_filename}"

    # Try aria2c first, fallback to wget
    if [[ $USE_ARIA2C == "true" ]] && command -v aria2c >/dev/null 2>&1; then
        if provisioning_download_aria2c "$download_url" "$destination" "$final_filename" "$auth_header" "$url"; then
            return 0
        else
            printf "aria2c failed, falling back to wget...\n"
        fi
    fi

    # Fallback to wget
    provisioning_download_wget "$download_url" "$destination" "$final_filename" "$auth_header" "$url"
}

function provisioning_download_aria2c() {
    local url="$1"
    local destination="$2"
    local custom_filename="$3"
    local auth_header="$4"
    local original_url="$5"

    local args=(
        --continue=true
        --max-connection-per-server="$ARIA2C_MAX_CONN"
        --split="$ARIA2C_SPLIT"
        --dir="$destination"
        --auto-file-renaming=false
    )

    # For HuggingFace, don't use --content-disposition and always specify filename
    if [[ $original_url =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        [[ -n "$custom_filename" ]] && args+=(--out="$custom_filename")
    else
        # For non-HuggingFace URLs, use --content-disposition
        args+=(--content-disposition=true)
        [[ -n "$custom_filename" ]] && args+=(--out="$custom_filename")
    fi

    [[ -n "$auth_header" ]] && args+=(--header="$auth_header")

    # Try the download
    if aria2c "${args[@]}" "$url" 2>/dev/null; then
        return 0
    fi

    # If that fails and we used --content-disposition, try without it
    if [[ ! $original_url =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        printf "Retrying aria2c without --content-disposition...\n"
        args=(${args[@]/--content-disposition=true/})
        aria2c "${args[@]}" "$url"
    else
        return 1
    fi
}

function provisioning_download_wget() {
    local url="$1"
    local destination="$2"
    local custom_filename="$3"
    local auth_header="$4"
    local original_url="$5"

    local args=(
        -qnc
        --show-progress
        -e dotbytes=4M
        -P "$destination"
    )

    # Handle filename logic based on URL type
    if [[ $original_url =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        # For HuggingFace, always specify output filename (don't use --content-disposition)
        if [[ -n "$custom_filename" ]]; then
            args+=(-O "${destination}/${custom_filename}")
        else
            # This shouldn't happen since we extract filename above, but just in case
            args+=(--content-disposition)
        fi
    else
        # For non-HuggingFace URLs, use --content-disposition unless custom filename provided
        if [[ -z "$custom_filename" ]]; then
            args+=(--content-disposition)
        else
            args+=(-O "${destination}/${custom_filename}")
        fi
    fi

    [[ -n "$auth_header" ]] && args+=(--header="$auth_header")

    wget "${args[@]}" "$url"
}

function provisioning_print_header() {
    printf "\n##############################################\n"
    printf "#                                            #\n"
    printf "#          Provisioning container            #\n"
    printf "#                                            #\n"
    printf "#         This will take some time           #\n"
    printf "#                                            #\n"
    printf "# Your container will be ready on completion #\n"
    printf "#                                            #\n"
    printf "##############################################\n\n"
}

function provisioning_print_end() {
    printf "\nProvisioning complete: Application will start now\n\n"
}

function provisioning_has_valid_hf_token() {
    [[ -n "$HF_TOKEN" ]] || return 1
    local response
    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET \
        "https://huggingface.co/api/whoami-v2" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json")
    [[ "$response" -eq 200 ]]
}

function provisioning_has_valid_civitai_token() {
    [[ -n "$CIVITAI_TOKEN" ]] || return 1
    local response
    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET \
        "https://civitai.com/api/v1/models?hidden=1&limit=1" \
        -H "Authorization: Bearer $CIVITAI_TOKEN" \
        -H "Content-Type: application/json")
    [[ "$response" -eq 200 ]]
}

# Initialize empty arrays for all model types to prevent errors
declare -a APT_PACKAGES=()
declare -a PIP_PACKAGES=()
declare -a NODES=()
declare -a WORKFLOWS=()
declare -a CHECKPOINT_MODELS=()
declare -a DIFFUSION_MODELS=()
declare -a UNET_MODELS=()
declare -a LORA_MODELS=()
declare -a VAE_MODELS=()
declare -a TEXT_ENCODERS=()
declare -a ESRGAN_MODELS=()
declare -a CONTROLNET_MODELS=()
declare -a CLIP_MODELS=()
