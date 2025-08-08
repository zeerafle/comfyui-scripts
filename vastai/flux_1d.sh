#!/bin/bash

# Source the base provisioning functions
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/base_provisioning.sh"

# Activate virtual environment
source /venv/main/bin/activate

# Package definitions
APT_PACKAGES=(
    "aria2"
)

PIP_PACKAGES=()

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/r-vage/ComfyUI-RvTools_v2"
)

DIFFUSION_MODELS=(
    "https://civitai.com/api/download/models/1703341?type=Model&format=SafeTensor&size=full&fp=fp8"
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
)

TEXT_ENCODERS=(
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors?download=true"
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors"
)

VAE_MODELS=(
    "https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors?download=true"
)

ESRGAN_MODELS=(
    "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth"
    "https://huggingface.co/Tenofas/ComfyUI/resolve/main/upscale_models/4x-UltraSharpV2.safetensors?download=true"
    "https://huggingface.co/Tenofas/ComfyUI/resolve/main/upscale_models/x1_ITF_SkinDiffDetail_Lite_v1.pth?download=true"
)

# Start provisioning (only if not disabled)
[[ ! -f /.noprovisioning ]] && provisioning_start
