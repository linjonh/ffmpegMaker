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

function make_linux_glew(){
    #进入glew目录
    
    echo "➡️ cpu核心数：$(nproc)"
    #安装依赖库,sudo 需要输入密码 && 0<lin /home/aigc/.wk/ffmaker/ffmpegMaker/main_run_build_script.sh
    echo "➡️ 安装glew依赖库"
    sudo apt install -y libegl1-mesa-dev && 2>/dev/null #&& 0<lin
    #预先编译auto目录的
    cd $1/glew/auto
    make PYTHON=python3 -j"$(nproc)"
    #开始编译
    cd $1/glew
    echo "➡️ 开始编译glew"
    sudo make clean && make SYSTEM=linux-egl -j"$(nproc)"
    #安装
    echo "➡️ 安装glew"
    sudo make install && 2>/dev/null #&& 0<lin
}
function addLib64Path(){
    echo "➡️ add lib64 to path"
    # 检查 ~/.bashrc 是否已经包含 /usr/lib64
    if ! grep -E '^export LD_LIBRARY_PATH=.*/usr/lib64' ~/.bashrc; then
        echo "export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH" >> ~/.bashrc
        echo "✅ 已添加 /usr/lib64 到 LD_LIBRARY_PATH"
    else
        echo "✅ /usr/lib64 已存在于 LD_LIBRARY_PATH 中，无需重复添加"
    fi
    # 立即生效
    source ~/.bashrc
    # 添加 /usr/lib64 到 linker 搜索路径
    echo "/usr/lib64" | sudo tee /etc/ld.so.conf.d/glew.conf
    sudo ldconfig
    
}
function installAom(){
    # 安装必要工具
    sudo apt update
    sudo apt install -y cmake ninja-build build-essential git
    
    # 克隆 aom 最新源码
    [[ ! -e aom ]] && git clone https://aomedia.googlesource.com/aom
    cd aom
    
    # 建立构建目录
    mkdir build
    cd build
    
    # 配置 CMake
    cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
    
    # 编译并安装
    make -j$(nproc)
    sudo make install
    
    # 刷新 pkg-config 环境
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
    
    # 确认版本
    pkg-config --modversion aom
    cd .. && pwd
    # rm -rf aom
}

function installDav1d(){
    # # libdav1d-dev
    # sudo apt install meson ninja-build
    # git clone https://code.videolan.org/videolan/dav1d.git
    # cd dav1d
    # meson build --buildtype release --prefix /usr
    # ninja -C build
    # sudo ninja -C build install
    
    #   # 安装依赖项
    sudo apt install -y meson ninja-build build-essential pkg-config git
    sudo apt install -y nasm
    
    # 克隆 dav1d 最新源码
    [[ ! -e dav1d ]] && git clone https://gh-proxy.com/github.com/videolan/dav1d.git
    cd dav1d
    
    # 编译并安装
    meson setup build
    ninja -C build
    sudo ninja -C build install
    
    # 刷新 pkg-config 环境变量
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
    
    # 验证版本
    pkg-config --modversion dav1d
    cd .. && pwd
    # rm -rf dav1d
}

function installZimg(){
    sudo apt install -y libgnutls28-dev libtool
    
    sudo apt install -y autoconf automake
    
    [[ ! -e zimg ]] && git clone https://github.com/sekrit-twc/zimg.git
    cd zimg
    git checkout release-2.7
    sudo make clean
    ./autogen.sh
    ./configure --prefix=/usr
    make -j$(nproc)
    sudo make install
    cd .. && pwd
    # rm -rf zimg
}

function instalLlibvpl(){
    echo "➡️  instalLlibvpl"
    if [[ ! -e libvpl-2.14.0 ]]; then
        if [[ ! -e libvpl.tar.gz ]]; then
            wget -O libvpl.tar.gz https://gh-proxy.com/github.com/intel/libvpl/archive/refs/tags/v2.14.0.tar.gz
            tar -xf libvpl.tar.gz
        fi
    fi
    cd libvpl-2.14.0 && pwd
    [[ ! -e build ]] && mkdir build
    cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
    make -j$(nproc)
    sudo make install
    echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/libvpl.conf
    sudo ldconfig
    pkg-config --modversion vpl
    echo "✅ instalLlibvpl 安装完成"
    cd .. && pwd
    rm -rf libvpl-2.14.0
}

function installLibs(){
    #预编译和安装glew
    echo "➡️ 预编译和安装glew..."
    make_linux_glew $PROJECT_BASE_DIR
    addLib64Path
    #编译Linux平台
    echo "➡️ 安装编译Linux平台的依赖库..."
    #在ffmpeg-source里配置 configure   #安装依赖库类库
    cd ${PROJECT_BASE_DIR}/ffmpeg-source
    
    sudo add-apt-repository -y ppa:ubuntuhandbook1/ffmpeg7
    sudo apt update
    sudo apt install -y cmake build-essential
    sudo apt install -y yasm pkg-config libx264-dev libx265-dev libfdk-aac-dev libvpx-dev libmp3lame-dev libopus-dev
    sudo apt install -y libglu1-mesa-dev freeglut3-dev mesa-common-dev #GLU
    sudo apt install -y libxvidcore-dev
    sudo apt install -y libass-dev
    sudo apt install -y libvorbis-dev
    sudo apt install -y libsdl2-dev
    sudo apt install -y libtheora-dev
    sudo apt install -y libchromaprint-dev
    sudo apt install -y frei0r-plugins-dev
    sudo apt install -y ladspa-sdk
    sudo apt install -y libgnutls28-dev
    sudo apt install -y libaom-dev
    sudo apt install -y  libass-dev
    sudo apt install -y  libbluray-dev
    sudo apt install -y  libbs2b-dev
    sudo apt install -y  libcaca-dev
    sudo apt install -y  libcdio-dev
    sudo apt install -y  libcodec2-dev
    sudo apt install -y  flite1-dev
    sudo apt install -y  libfontconfig1-dev
    sudo apt install -y  libfreetype6-dev
    sudo apt install -y  libfribidi-dev
    sudo apt install -y  libgme-dev
    sudo apt install -y  libgsm1-dev
    sudo apt install -y  libjack-jackd2-dev
    sudo apt install -y  libmp3lame-dev
    sudo apt install -y  libmysofa-dev
    sudo apt install -y  libopenjp2-7-dev
    sudo apt install -y  libopenmpt-dev
    sudo apt install -y  libopus-dev
    sudo apt install -y  libpulse-dev
    sudo apt install -y  librabbitmq-dev
    sudo apt install -y  librubberband-dev
    sudo apt install -y  libshine-dev
    sudo apt install -y  libsnappy-dev
    sudo apt install -y  libsoxr-dev
    sudo apt install -y  libspeex-dev
    sudo apt install -y  libsrt-openssl-dev #出错的地方libsrt-dev是找不到的
    sudo apt install -y  libssh-dev
    sudo apt install -y  libtheora-dev
    sudo apt install -y  libtwolame-dev
    sudo apt install -y  libvidstab-dev
    sudo apt install -y  libvorbis-dev
    sudo apt install -y  libvpx-dev
    sudo apt install -y  libwebp-dev
    sudo apt install -y  libx265-dev
    sudo apt install -y  libxml2-dev
    sudo apt install -y  libxvidcore-dev
    sudo apt install -y  libzmq3-dev
    sudo apt install -y  libzvbi-dev
    sudo apt install -y  lv2-dev
    sudo apt install -y  libomxil-bellagio-dev
    sudo apt install -y  libopenal-dev
    sudo apt install -y  ocl-icd-opencl-dev
    sudo apt install -y  libgl-dev
    sudo apt install -y  libsdl2-dev
    sudo apt install -y  pocketsphinx
    sudo apt install -y  libsphinxbase-dev
    sudo apt install -y  librsvg2-dev
    sudo apt install -y  libmfx-dev
    sudo apt install -y  libdc1394-dev # 出错的地方libdc1394-22-dev是找不到的
    sudo apt install -y  libdrm-dev
    sudo apt install -y  libiec61883-dev
    sudo apt install -y  libchromaprint-dev
    sudo apt install -y  frei0r-plugins-dev
    sudo apt install -y  libx264-dev
    sudo apt install -y  libaom-dev
    sudo apt install -y  liblilv-dev
    sudo apt install -y  libraw1394-dev
    sudo apt install -y  libavc1394-dev
    sudo apt install -y  libpocketsphinx-dev
    sudo apt install -y  libcdio-dev
    sudo apt install -y  libcdio-paranoia-dev
    sudo apt install -y libzimg-dev
    sudo apt install -y libpgm-dev
    sudo apt install -y lilv-utils liblilv-dev #修复lilv-0 not found using pkg-config
    
    sudo apt install -y build-essential
    sudo apt install -y libiconv-hook-dev 
    sudo apt install -y liblcms2-dev 
    sudo apt install -y libgmp-dev 
    sudo apt install -y libbz2-dev 
    sudo apt install -y liblzma-dev 
    sudo apt install -y zlib1g-dev 
    sudo apt install -y librist-dev 
    sudo apt install -y libdvdnav-dev 
    sudo apt install -y libdvdread-dev 
    sudo apt install -y libaribb24-dev 
    sudo apt install -y libdavs2-dev 
    sudo apt install -y libqrencode-dev 
    sudo apt install -y libsvtav1-dev 
    sudo apt install -y libxavs2-dev
    sudo apt install -y libharfbuzz-dev 
    # sudo apt install -y liblensfun-dev # 采用旧版本，手动安装
    sudo apt install -y libmodplug-dev 
    sudo apt install -y libopencore-amrwb-dev 
    sudo apt install -y libvo-amrwbenc-dev  
    sudo apt install -y libopencore-amrnb-dev 
    sudo apt install -y libplacebo-dev 
    sudo apt install -y libvulkan-dev 
    sudo apt install -y libva-dev 
    export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH # 为了解决ERROR: vulkan requested but not found
    # sudo apt install -y libvvenc-dev 
    # sudo apt install -y libjxl-dev 
    # sudo apt install -y libvmaf-dev 
    # sudo apt install -y libilbc-dev 

    # sudo apt install -y libavisynth-dev       
    # sudo apt install -y libaribcaption-dev    
    # sudo apt install -y libquirc-dev          
    # sudo apt install -y libuavs3d-dev         
    # sudo apt install -y libxevd-dev           
    # sudo apt install -y librav1e-dev          
    # sudo apt install -y libxeve-dev           
    # sudo apt install -y liblc3-dev                 
    # sudo apt install -y libshaderc-dev        
    # sudo apt install -y libd3d12-dev    
    #因为找不到
# E: Unable to locate package libavisynth-dev
# E: Unable to locate package libaribcaption-dev
# E: Unable to locate package libquirc-dev
# E: Unable to locate package libuavs3d-dev
# E: Unable to locate package libxevd-dev
# E: Unable to locate package librav1e-dev
# E: Unable to locate package libxeve-dev
# E: Unable to locate package liblc3-dev
# E: Unable to locate package libshaderc-dev
# E: Unable to locate package libnvenc-dev
# E: Unable to locate package libd3d12-dev
    #因为找不到
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
    
    # cd ${PROJECT_BASE_DIR}/ffmpeg-source
    # installDav1d
    cd ${PROJECT_BASE_DIR}/ffmpeg-source
    instalLlibvpl
    sudo apt install -y libdav1d-dev
    # sudo apt install -y libvpl-dev
    source ${PROJECT_BASE_DIR}/install_svtav1_latest.sh
    # cd ${PROJECT_BASE_DIR}/ffmpeg-source
    # install_lensFun
    source ${PROJECT_BASE_DIR}/install_ffnvcodecheaders.sh
    source ${PROJECT_BASE_DIR}/install_nvidia_cuda_toolkit.sh
}
# deprecate 
function install_lensFun(){
    cd ${PROJECT_BASE_DIR}/ffmpeg-source
    echo "install_lensFun..."
    git clone https://github.com/lensfun/lensfun.git
    cd lensfun
    git checkout tags/v0.2.8
    mkdir build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
    make -j$(nproc)
    sudo make install
    sudo ldconfig
    pkg-config --modversion lensfun
    # 应该显示 0.2.9
    cd -
    cd .. && pwd
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
    --enable-libharfbuzz --enable-cuda-llvm --enable-cuvid  \
    --enable-ffnvcodec --enable-vaapi  --enable-libplacebo --enable-libmodplug --enable-libopencore-amrwb \
    --enable-libvo-amrwbenc --enable-libopencore-amrnb \
    \
    --disable-shared \
    --enable-static \
    --enable-filter=gltransition \
    --extra-libs='-lGLEW -lEGL' \
    --enable-cross-compile \
    \
    --enable-cuda \
    --enable-cuvid \
    --enable-nvenc \
    --enable-nvdec \
    --enable-cuda-nvcc \
    --enable-libnpp \
    --enable-nonfree \
    --enable-gpl \
    --extra-cflags=-I/usr/local/cuda/include \
    --extra-ldflags=-L/usr/local/cuda/lib64
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
    installLibs
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
    ffmpeg -version
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
