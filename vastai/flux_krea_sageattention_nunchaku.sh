#!/bin/bash

# Self-contained Flux Dev provisioning script
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

PIP_PACKAGES=(
    "ninja"
    "packaging"
)

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/r-vage/ComfyUI-RvTools_v2"
    "https://github.com/nunchaku-tech/ComfyUI-nunchaku"
)

DIFFUSION_MODELS=(
    "https://huggingface.co/nunchaku-tech/nunchaku-flux.1-krea-dev/resolve/main/svdq-int4_r32-flux.1-krea-dev.safetensors?download=true"
)

LORA_MODELS=(
    "https://civitai.com/api/download/models/1228264?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/786275?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/870190?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/1244911?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/1188867?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/1041921?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/1668530?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/1050496?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/970280?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/1366323?type=Model&format=SafeTensor"
    "https://huggingface.co/alimama-creative/FLUX.1-Turbo-Alpha/resolve/main/diffusion_pytorch_model.safetensors?download=true"
    "https://civitai.com/api/download/models/806426?type=Model&format=SafeTensor"
)

TEXT_ENCODERS=(
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true"
    "https://huggingface.co/nunchaku-tech/nunchaku-t5/resolve/main/awq-int4-flux.1-t5xxl.safetensors?download=true"
)

VAE_MODELS=(
    "https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors?download=true"
)

ESRGAN_MODELS=(
    "https://huggingface.co/Tenofas/ComfyUI/resolve/main/upscale_models/4x-UltraSharpV2.safetensors?download=true"
    "https://huggingface.co/Tenofas/ComfyUI/resolve/main/upscale_models/x1_ITF_SkinDiffDetail_Lite_v1.pth?download=true"
)

# Cleanup function
cleanup() {
    [[ -f "$temp_base_script" ]] && rm -f "$temp_base_script"
}
trap cleanup EXIT

# Start provisioning (only if not disabled)
[[ ! -f /.noprovisioning ]] && provisioning_start
