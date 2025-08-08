#!/bin/bash

# Source the base provisioning functions
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/base_provisioning.sh"

# Activate virtual environment
source /venv/main/bin/activate

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/rgthree/rgthree-comfy"
)

WORKFLOWS=(
    "https://raw.githubusercontent.com/Comfy-Org/workflow_templates/refs/heads/main/templates/video_wan2_2_14B_t2v.json"
)

LORA_MODELS=(
    "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-T2V-A14B-4steps-lora-rank64-V1/high_noise_model.safetensors?download=true"
    "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-T2V-A14B-4steps-lora-rank64-V1/low_noise_model.safetensors?download=true"
    "https://civitai.com/api/download/models/1628383?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/2077233?type=Model&format=SafeTensor"
    "https://civitai.com/api/download/models/1999459?type=Model&format=SafeTensor"
)

VAE_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
)

TEXT_ENCODERS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensor"
)

DIFFUSION_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
)

# Start provisioning (only if not disabled)
[[ ! -f /.noprovisioning ]] && provisioning_start
