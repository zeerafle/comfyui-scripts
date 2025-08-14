#!/bin/bash

# Self-contained WAN 2.2 provisioning script
# Downloads base provisioning functions and executes them

source /venv/main/bin/activate

# URL to the base provisioning script (update this to your hosted location)
BASE_SCRIPT_URL="https://raw.githubusercontent.com/zeerafle/comfyui-scripts/refs/heads/main/vastai/base_provisioning_sageattention.sh"

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

PIP_PACKAGES=()

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/welltop-cn/ComfyUI-TeaCache"
)

WORKFLOWS=(
    "https://huggingface.co/lightx2v/Wan2.2-Lightning/raw/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1-forKJ.json"
)

LORA_MODELS=(
    "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/high_noise_model.safetensors?download=true"
    "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors?download=true"
)

VAE_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
)

TEXT_ENCODERS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensor"
)

DIFFUSION_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors?download=true"
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors?download=true"
)

# Cleanup function
cleanup() {
    [[ -f "$temp_base_script" ]] && rm -f "$temp_base_script"
}
trap cleanup EXIT

# Start provisioning (only if not disabled)
[[ ! -f /.noprovisioning ]] && provisioning_start
