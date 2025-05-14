#!/bin/bash

#安装NVIDIA的编码器
# sudo apt-get install nvidia-cuda-toolkit
wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-9

sudo apt install -y libnvidia-compute-550
echo "➡️ 查看nvcc --version"
nvcc --version 2>/dev/null
export PATH=/usr/local/cuda-12.9/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.9/lib64:$LD_LIBRARY_PATH
