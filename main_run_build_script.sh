#!/bin/bash
echo all args: "$@"

PROJECT_BASE_DIR="$(cd "$(dirname "$0")" && pwd)" && echo "当前项目目录：$PROJECT_BASE_DIR"
export PROJECT_BASE_DIR

function clone_code(){
    # 获取所有子模块路径
    submodules=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')
    urls=$(git config --file .gitmodules --get-regexp url | awk '{ print $2 }')
    echo "➡️ 获取所有子模块路径:$submodules"
    
    need_update=false
    
    for submodule in $submodules; do
        # 检查子模块目录是否存在且包含 .git 文件夹
        file "$submodule/.git"
        if [ ! -e "$submodule/.git" ]; then
            echo "➡️ 子模块 $submodule 目录不存在或未初始化"
            need_update=true
        fi
    done
    
    if [ "$need_update" = true ]; then
        echo "➡️ 正在初始化并更新子模块..."
        # git submodule update --init --recursive
        
        # 手动clone 子模块 urls，模块名从submodules读取
        i=1
        for submodule in $submodules; do
            # 检查子模块目录是否存在且包含 .git 文件夹
            if [ ! -e "$submodule/.git" ]; then
                # 获取对应的 URL
                url=$(echo "$urls" | sed -n "${i}p" | tr -d '\r\n')
                
                echo "➡️ 正在下载子模块 $submodule : $url"
                
                rm -rf "$submodule"
                git clone "$url" "$submodule"
            fi
            i=$((i + 1))
        done
        
    else
        echo "✅  所有子模块目录均已存在，跳过下载。"
    fi
    
    for submodule in $submodules; do
        # 再次检查子模块目录是否存在且包含 .git 文件夹
        file "$submodule/.git"
        if [ ! -e "$submodule/.git" ]; then
            echo "➡️ 子模块 $submodule 目录不存在或未初始化"
            exit 1
        else
            cd "$submodule" || exit
            if [ "$submodule" == "ffmpeg-source" ];then
                git pull origin release/7.1 --rebase
            else
                git pull origin main --rebase
            fi
            cd - > /dev/null || exit
        fi
    done
}

function config_ffmpeg(){
    echo "➡️ config_ffmpeg所有参数 $@ "
    echo "➡️ config_ffmpeg第一个 $1"
    linux=$(cat /etc/issue | sed 's/\\n//g' | sed 's/\\l//g')
    echo "➡️ ”start run ffmpeg ./configure ..."
    ./configure \
    --prefix=$1 \
    --extra-version="$linux" \
    --toolchain=hardened \
    --libdir=/usr/lib/x86_64-linux-gnu \
    --incdir=/usr/include/x86_64-linux-gnu \
    --arch=x86_64 \
    --enable-gpl \
    --disable-stripping \
    --enable-gnutls \
    --enable-ladspa \
    --enable-libaom \
    --enable-libass \
    --enable-libbluray \
    --enable-libbs2b \
    --enable-libcaca \
    --enable-libcdio \
    --enable-libcodec2 \
    --enable-libdav1d \
    --enable-libflite \
    --enable-libfontconfig \
    --enable-libfreetype \
    --enable-libfribidi \
    --enable-libgme \
    --enable-libgsm \
    --enable-libjack \
    --enable-libmp3lame \
    --enable-libmysofa \
    --enable-libopenjpeg \
    --enable-libopenmpt \
    --enable-libopus \
    --enable-libpulse \
    --enable-librabbitmq \
    --enable-librubberband \
    --enable-libshine \
    --enable-libsnappy \
    --enable-libsoxr \
    --enable-libspeex \
    --enable-libsrt \
    --enable-libssh \
    --enable-libtheora \
    --enable-libtwolame \
    --enable-libvidstab \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwebp \
    --enable-libx265 \
    --enable-libxml2 \
    --enable-libxvid \
    --enable-libzimg \
    --enable-libzmq \
    --enable-libzvbi \
    --enable-lv2 \
    --enable-omx \
    --enable-openal \
    --enable-opencl \
    --enable-opengl \
    --enable-sdl2 \
    --enable-pocketsphinx \
    --enable-librsvg \
    --enable-libvpl \
    --enable-libdc1394 \
    --enable-libdrm \
    --enable-libiec61883 \
    --enable-chromaprint \
    --enable-frei0r \
    --enable-libx264 \
    \
    --enable-version3 --disable-w32threads --disable-autodetect  --enable-iconv --enable-lcms2 --enable-gmp --enable-bzlib --enable-lzma \
    --enable-zlib --enable-libdvdnav --enable-libdvdread --enable-libaribb24  \
    --enable-libdavs2 --enable-libqrencode --enable-libsvtav1 --enable-libxavs2 \
    --enable-libharfbuzz \
    --enable-ffnvcodec --enable-vaapi  --enable-libplacebo --enable-libmodplug --enable-libopencore-amrwb \
    --enable-libvo-amrwbenc --enable-libopencore-amrnb \
    \
    --disable-shared \
    --enable-static \
    --enable-filter=gltransition \
    --extra-libs='-lGLEW -lEGL' \
    --enable-cross-compile \
    # \
    # --enable-cuda-llvm --enable-cuvid  \
    # --enable-cuda \
    # --enable-cuvid \
    # --enable-nvenc \
    # --enable-nvdec \
    # --enable-cuda-nvcc \
    # --enable-libnpp \
    # --enable-nonfree \
    # --enable-gpl \
    # --extra-cflags=-I/usr/local/cuda/include \
    # --extra-ldflags=-L/usr/local/cuda/lib64
# E: 无法定位软件包 librist-dev
# E: 无法定位软件包 libavisynth-dev
# E: 无法定位软件包 libaribcaption-dev
# E: 无法定位软件包 libquirc-dev
# E: 无法定位软件包 libuavs3d-dev
# E: 无法定位软件包 libxevd-dev
# E: 无法定位软件包 librav1e-dev
# E: 无法定位软件包 libvvenc-dev
# E: 无法定位软件包 libxeve-dev
# E: 无法定位软件包 libjxl-dev
# E: 无法定位软件包 libvmaf-dev
# E: 无法定位软件包 libilbc-dev
# E: 无法定位软件包 liblc3-dev
# E: 无法定位软件包 libshaderc-dev
# E: 无法定位软件包 libnvenc-dev
# E: 无法定位软件包 libd3d12-dev
#找不到依赖包就 注释掉enable了
 # --enable-librist --enable-avisynth  --enable-libaribcaption --enable-libquirc  --enable-libuavs3d -enable-libxevd --enable-librav1e --enable-libvvenc --enable-libxeve --enable-libjxl  --enable-libvmaf
 #  --enable-libilbc --enable-liblc3 --enable-libshaderc --enable-d3d12va  --enable-d3d11va --enable-dxva2 --enable-amf --enable-vulkan   --enable-liblensfun 

    # ./configure \
    #     --prefix=/usr/local \
    #     --enable-gpl \
    #     --enable-nonfree \
    #     --enable-libass \
    #     --enable-libfdk-aac \
    #     --enable-libfreetype \
    #     --enable-libmp3lame \
    #     --enable-libtheora \
    #     --enable-libvorbis \
    #     --enable-libvpx \
    #     --enable-libx264 \
    #     --enable-libx265 \
    #     --enable-libopus \
    #     --enable-libxvid \
    #     --enable-opengl \
    #     --enable-filter=gltransition \
    #     --extra-libs='-lGLEW -lEGL' \
    #     --enable-cross-compile \
    #     --enable-sdl2 \
    #     --disable-shared \
    #     --enable-static
}

function make_linux_ffmpeg(){
    #开始安装依赖库
    echo "➡️  开始安装依赖库"
    source ./install_dependences.sh
    echo "➡️ 所有依赖安装完，开始编译"
    cd "${PROJECT_BASE_DIR}/ffmpeg-source" && pwd
    export CC="gcc -std=c17"
    prefix=$3
    echo "所有参数：$@"
    echo "查看prefix=$prefix"
    if [[ $prefix == "" ]];then
        prefix=/usr
    fi
    #开始配置和编译
    sudo make distclen || true 2>/dev/null
    sudo make clean || true 2>/dev/null

    echo "➡️ call config_ffmpeg $prefix"
    config_ffmpeg "$prefix"
    #&& sudo make distclean

    echo "➡️ 查看config log 50条"
    tail -n 50 ffbuild/config.log
    
    echo "➡️ make 编译Linux平台"
    make -j"$(nproc)"
    
    echo "➡️ 查看生成目录的./ffmpeg -version"
    ./ffmpeg -version
    #echo "➡️ 查看生成目录的which ffmpeg的ffmpeg -version"
    #which ffmpeg
    #ffmpeg -version
    
    echo "➡️ 第二个命令参数： $2 ,相等于install-linux?"
    if [[ $2 == "install-linux" ]];then
        echo "✅ 相等于install-linux=true"
        install_linux_ffmpeg
    fi
}

function install_linux_ffmpeg(){
    cd ${PROJECT_BASE_DIR}/ffmpeg-source
    echo "➡️   安装linux_ffmpeg"
    sudo make install
    echo "✅  安装linux_ffmpeg 完成"
    echo && echo "➡️  打印版本号："
    which ffmpeg
    ffmpeg -version 2>/dev/null
}

function make_android_ffmpeg(){
    #进入ffmpeg-android-maker 开始最终编译
    local_path=${PROJECT_BASE_DIR}/ffmpeg-android-maker
    cd $local_path
    #编译android ARM64平台的
    echo "➡️ .configure 编译android ARM64平台 ..."
    echo "➡️ docker 镜像创建"
    docker build -t ffmpeg-maker ./tools/docker
    #docker run
    echo "➡️ docker run --rm ffmpeg-maker on dir:$(pwd)"
    docker run --rm \
    -v "${PROJECT_BASE_DIR}:/mnt/" \
    ffmpeg-maker ls /mnt
    
    docker run --rm \
    -v "${PROJECT_BASE_DIR}:/mnt/" \
    ffmpeg-maker \
    /mnt/ffmpeg-android-maker/ffmpeg-android-maker.sh  \
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
        clone_code
        make_linux_ffmpeg $@
    ;;
    build-arm64)
        clone_code
        make_android_ffmpeg
    ;;
    install-linux)
        clone_code
        install_linux_ffmpeg
    ;;
    config)
        cd "${PROJECT_BASE_DIR}/ffmpeg-source" && pwd
        export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH # 为了解决ERROR: vulkan requested but not found
        config_ffmpeg
        cd -
    ;;
    *)
        echo && echo "➡️  无效参数。可用的参数: build-linux, build-arm64, install-linux" && echo
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
