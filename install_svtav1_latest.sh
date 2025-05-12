#!/bin/bash

set -e

echo "🔧 安装依赖..."
# sudo apt-get update
sudo apt-get install -y cmake git yasm build-essential pkg-config

echo "📦 克隆 SVT-AV1（包含 tags）..."
rm -rf SVT-AV1
git clone --tags https://gitlab.com/AOMediaCodec/SVT-AV1.git
cd SVT-AV1

echo "🔁 切换到 v1.7.0..."
git checkout tags/v1.7.0 -b build-v1.7.0

echo "🔨 构建并安装..."
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build -j$(nproc)
sudo cmake --install build

echo "🧩 添加 PKG_CONFIG_PATH 环境变量..."
if ! grep -q "PKG_CONFIG_PATH" ~/.bashrc; then
    echo 'export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH' >> ~/.bashrc
    echo "✅ 已添加到 ~/.bashrc"
fi
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

echo "✅ 安装完成，版本：$(pkg-config --modversion SvtAv1Enc)"
