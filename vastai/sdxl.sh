#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

# Packages are installed after nodes so we can fix them...

APT_PACKAGES=(
    "aria2"
    #"package-1"
    #"package-2"
)

PIP_PACKAGES=(
    #"package-1"
    #"package-2"
)

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack"
)

WORKFLOWS=(

)

CHECKPOINT_MODELS=(
    "https://civitai.com/api/download/models/1759168?type=Model&format=SafeTensor&size=full&fp=fp16|juggernautXL_ragnarokBy.safetensors"
    "https://civitai.com/api/download/models/1943922?type=Model&format=SafeTensor&size=pruned&fp=fp16|gonzalomoXLFluxPony_v40UnityXLDMD.safetensors"
)

DIFFUSION_MODELS=(
)

UNET_MODELS=(
)

LORA_MODELS=(
    "https://civitai.com/api/download/models/864266?type=Model&format=SafeTensor|fbb-photo_sdxl_1-6-lite.safetensors"
    "https://civitai.com/api/download/models/135867?type=Model&format=SafeTensor|add-detail-xl.safetensors"
    "https://civitai.com/api/download/models/302404?type=Model&format=SafeTensor|Sweaty_Realism_4-000006.safetensors"
    "https://civitai.com/api/download/models/128461?type=Model&format=SafeTensor|PerfectEyesXL.safetensors"
    "https://civitai.com/api/download/models/287900?type=Model&format=SafeTensor|brlssSDXL_v1_00022.safetensors"
)

VAE_MODELS=(

)

ESRGAN_MODELS=(
)

CONTROLNET_MODELS=(
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
    provisioning_get_files \
        "${COMFYUI_DIR}/models/checkpoints" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/unet" \
        "${UNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/loras" \
        "${LORA_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/upscale_models" \
        "${ESRGAN_MODELS[@]}"
    provisioning_print_end
}

function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
            sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
            pip install --no-cache-dir ${PIP_PACKAGES[@]}
    fi
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
                if [[ -e $requirements ]]; then
                   pip install --no-cache-dir -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                pip install --no-cache-dir -r "${requirements}"
            fi
        fi
    done
}

function provisioning_get_files() {
    if [[ -z $2 ]]; then return 1; fi

    local dir="$1"
    mkdir -p "$dir"
    shift
    local arr=("$@")

    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
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
        if [[ -n "$custom_name" ]]; then
            printf "Saving as: %s\n" "$custom_name"
        fi
        provisioning_download "${url}" "${dir}" "$custom_name"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Application will start now\n\n"
}

function provisioning_has_valid_hf_token() {
    [[ -n "$HF_TOKEN" ]] || return 1
    url="https://huggingface.co/api/whoami-v2"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

function provisioning_has_valid_civitai_token() {
    [[ -n "$CIVITAI_TOKEN" ]] || return 1
    url="https://civitai.com/api/v1/models?hidden=1&limit=1"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $CIVITAI_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

# Download from $1 URL to $2 file path with optional $3 custom filename
function provisioning_download() {
    local url="$1"
    local destination="$2"
    local custom_filename="$3"

    if [[ -n $HF_TOKEN && $url =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        # HuggingFace download with authorization header
        if [[ -n "$custom_filename" ]]; then
            aria2c --header="Authorization: Bearer $HF_TOKEN" \
                   --out="$custom_filename" \
                   --continue=true \
                   --max-connection-per-server=4 \
                   --split=4 \
                   --dir="$destination" "$url"
        else
            aria2c --header="Authorization: Bearer $HF_TOKEN" \
                   --continue=true \
                   --max-connection-per-server=4 \
                   --split=4 \
                   --dir="$destination" "$url"
        fi
    elif [[ -n $CIVITAI_TOKEN && $url =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        # For Civitai, append token as URL parameter
        if [[ $url == *"?"* ]]; then
            download_url="${url}&token=${CIVITAI_TOKEN}"
        else
            download_url="${url}?token=${CIVITAI_TOKEN}"
        fi

        if [[ -n "$custom_filename" ]]; then
            aria2c --out="$custom_filename" \
                   --continue=true \
                   --max-connection-per-server=4 \
                   --split=4 \
                   --dir="$destination" "$download_url"
        else
            aria2c --continue=true \
                   --max-connection-per-server=4 \
                   --split=4 \
                   --dir="$destination" "$download_url"
        fi
    else
        # Generic download
        if [[ -n "$custom_filename" ]]; then
            aria2c --out="$custom_filename" \
                   --continue=true \
                   --max-connection-per-server=4 \
                   --split=4 \
                   --dir="$destination" "$url"
        else
            aria2c --continue=true \
                   --max-connection-per-server=4 \
                   --split=4 \
                   --dir="$destination" "$url"
        fi
    fi
}

# Allow user to disable provisioning if they started with a script they didn't want
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi
