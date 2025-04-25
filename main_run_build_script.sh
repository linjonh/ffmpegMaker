  #!/bin/bash
echo all args: $@

# 获取所有子模块路径
submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')
echo "获取所有子模块路径:"$submodules

need_update=false

for submodule in $submodules; do
  # 检查子模块目录是否存在且包含 .git 文件夹
  if [ ! -d "$submodule/.git" ]; then
    echo "子模块 $submodule 目录不存在或未初始化"
    need_update=true
  fi
done

if [ "$need_update" = true ]; then
  echo "正在初始化并更新子模块..."
  git submodule update --init --recursive
else
  echo "所有子模块目录均已存在，跳过下载。"
fi

export PROJECT_BASE_DIR="$(cd "$(dirname "$0")" && pwd)" && echo "当前项目目录：$PROJECT_BASE_DIR"

function make_linux_glew(){
  #进入glew目录
  
  echo cpu核心数：$(nproc)
  #安装依赖库,sudo 需要输入密码 && 0<lin
  echo "===>安装glew依赖库"
  sudo apt install libegl1-mesa-dev && 2>/dev/null && 0<lin
  #预先编译auto目录的
  cd ${PROJECT_BASE_DIR}/glew/auto
  make -j$(nproc)
  #开始编译
  cd ${PROJECT_BASE_DIR}/glew
  echo "===>开始编译glew"
  make clean && make SYSTEM=linux-egl -j$(nproc)
  #安装
  echo "===>安装glew"
  sudo make install && 2>/dev/null && 0<lin
}

function make_linux_ffmpeg(){
  #预编译和安装glew
  echo "===>预编译和安装glew..."
  make_linux_glew

  #在ffmpeg-source里配置 configure
  cd ${PROJECT_BASE_DIR}/ffmpeg-source
  #编译Linux平台
  echo "===>.configure 编译Linux平台 ..."
  #安装依赖库类库
  sudo add-apt-repository ppa:jonathonf/ffmpeg-4
	sudo apt update
  sudo apt install build-esantial
  sudo apt install yasm pkg-config libx264-dev libx265-dev libfdk-aac-dev libvpx-dev libmp3lame-dev libopus-dev
  sudo apt install libglu1-mesa-dev freeglut3-dev mesa-common-dev #GLU
	sudo apt install libxvidcore-dev
	sudo apt install libass-dev
	sudo apt install libvorbis-dev
	sudo apt install libsdl2-dev
  sudo apt install libtheora-dev
  ./configure \
      --prefix=/usr/local \
      --enable-gpl \
      --enable-nonfree \
      --enable-libass \
      --enable-libfdk-aac \
      --enable-libfreetype \
      --enable-libmp3lame \
      --enable-libtheora \
      --enable-libvorbis \
      --enable-libvpx \
      --enable-libx264 \
      --enable-libx265 \
      --enable-libopus \
      --enable-libxvid \
      --enable-opengl \
      --enable-filter=gltransition \
      --extra-libs='-lGLEW -lEGL' \
      --enable-cross-compile \
      --enable-sdl2 \
      --disable-shared \
      --enable-static
  echo "===>查看config log 50条"
  tail -n 50 ffbuild/config.log
  echo "===>make 编译Linux平台"
  make clean && make -j$(nproc)
}
function install_linux_ffmpeg(){
  cd ${PROJECT_BASE_DIR}/ffmpeg-source
  echo "===> 安装linux_ffmpeg"
  sudo make install
  echo "===> 安装linux_ffmpeg 完成"

  echo && echo "===> 打印版本号："

  ffmpeg -version
}

function make_android_ffmpeg(){
  #进入ffmpeg-android-maker 开始最终编译
  cd ${PROJECT_BASE_DIR}/ffmpeg-android-maker
  #编译android ARM64平台的
  echo "===>.configure 编译android ARM64平台 ..."
  ./ffmpeg-android-maker.sh  \
      --enable-libx264 \
      --enable-libx265 \
      --enable-libmp3lame \
      -glew \
      --enable-gpl \
      --enable-nonfree \
      --enable-libass \
      --enable-libfdk-aac \
      --enable-libfreetype \
      --enable-libtheora  \
      --enable-libvorbis \
      --enable-libvpx \
      --enable-libopus \
      --enable-libxvid \
      --enable-opengl \
      --enable-filter=gltransition \
      --enable-sdl2 \
      --enable-jni \
      -abis=arm64 -android=24 \
      -ffmpeg 
}


# 根据输入的参数选择执行哪个函数
case "$1" in
  build-linux)
    make_linux_ffmpeg
    ;;
  build-arm64)
    make_android_ffmpeg
    ;;
  install-linux)
    install_linux_ffmpeg
    ;;
  *)
    echo && echo "===> 无效参数。可用的参数: build-linux, build-arm64, install-linux" && echo
    ;;
esac


# ./ffmpeg-android-maker.sh  \
#     -all-gpl \
#     -all-free \
#     -glew \
#     -ffmpeg \
#     -abis=arm64 -android=24 \

# -------------备用--------------
    # --enable-libmp3lame \
    # --enable-jni -abis=arm64 -android=24

    # --disable-asm 对于x86_64的平台不使用neon 禁用 SIMD SIMD 指令集
# -------------备用单独类库调试，需要 getSource和buildTarget函数调用--------------
# ./ffmpeg-android-maker.sh  \
#     --enable-libmp3lame \
#     --enable-jni -abis=x86_64 -android=24 

# -------------备用已有类库了，只需编译ffmpeg了--------------
# ./ffmpeg-android-maker.sh  \
#     -ffmpeg \
#     -abis=arm64 -android=24 FAM_ALONE=true

# CLEAN
# ./ffmpeg-android-maker.sh  \
#    CLEAN=true