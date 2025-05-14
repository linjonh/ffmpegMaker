# 阶段 1：构建 FFmpeg的基础依赖环境
FROM ubuntu:24.04

# 安装基础工具和依赖
RUN apt-get update && apt-get install -y \
  git wget curl build-essential yasm nasm \
  pkg-config libtool autoconf automake cmake \
  texinfo ccache sudo \
  python3 \
  python3-pip  libx11-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  xorg-dev \
  libglew-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# 使用 ccache 加速编译
ENV CC="ccache gcc"
ENV CXX="ccache g++"


# 设置工作目录
WORKDIR /app/ffmpegMaker

COPY . /app/ffmpegMaker

RUN pwd && bash ./install_dependences.sh

# 默认启动命令
ENTRYPOINT ["bash"]