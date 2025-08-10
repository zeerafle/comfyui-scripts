#!/bin/bash

# Self-contained SDXL provisioning script
# Downloads base provisioning functions and executes them

source /venv/main/bin/activate

# URL to the base provisioning script (update this to your hosted location)
BASE_SCRIPT_URL="https://raw.githubusercontent.com/zeerafle/comfyui-scripts/refs/heads/main/vastai/base_provisioning.sh"

# Download the base provisioning script
printf "Downloading base provisioning functions...\n"
temp_base_script="/tmp/base_provisioning_$$.sh"

if command -v wget >/dev/null 2>&1; then
    wget -q -O "$temp_base_script" "$BASE_SCRIPT_URL"
elif command -v curl >/dev/null 2>&1; then
    curl -s -o "$temp_base_script" "$BASE_SCRIPT_URL"
else
    echo "ERROR: Neither wget nor curl is available for downloading base script"
    exit 1
fi

# Check if download was successful
if [[ ! -f "$temp_base_script" ]] || [[ ! -s "$temp_base_script" ]]; then
    echo "ERROR: Failed to download base provisioning script from $BASE_SCRIPT_URL"
    exit 1
fi

# Source the downloaded base script
source "$temp_base_script"

# Package definitions
APT_PACKAGES=(
    "aria2"
)

PIP_PACKAGES=()

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack"
)

CHECKPOINT_MODELS=(
    # juggernaut XL
    # "https://civitai.com/api/download/models/1759168?type=Model&format=SafeTensor&size=full&fp=fp16"
    # Gonzalomo
    "https://civitai.com/api/download/models/2052057?type=Model&format=SafeTensor&size=full&fp=fp16"
    "https://civitai.com/api/download/models/1943922?type=Model&format=SafeTensor&size=pruned&fp=fp16"
)

LORA_MODELS=(
    "https://civitai.com/api/download/models/864266?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/135867?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/302404?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/128461?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/287900?type=Model&format=SafeTensor"
)

# Cleanup function
cleanup() {
    [[ -f "$temp_base_script" ]] && rm -f "$temp_base_script"
}
trap cleanup EXIT

# Start provisioning (only if not disabled)
[[ ! -f /.noprovisioning ]] && provisioning_start
