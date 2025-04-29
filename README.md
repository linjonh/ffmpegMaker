# ffmpegMaker
ffmpeg Maker

# 为当前目录和子目录的sh文件添加运行权限
```bash
find . -type f -name "*.sh" -exec chmod +x {} \;
```

# 运行脚本：
linux
```bash
./main_run_build_script.sh build-linux
```
或android arm64
```bash
./main_run_build_script.sh build-arm64
```
# 安装ffmpeg
linux: 
```bash
./main_run_build_script.sh install-linux
```

# 注意事项
glew 编译容易出错的地方
config/config.guess
```bash 
#如果外部设置SYSTEM的config平台，此处config.guess 猜测的对于glew类库不支持  library -lX11 和 library -lGL，可以注释掉
SYSTEM ?= $(shell config/config.guess | cut -d - -f 3 | sed -e 's/[0-9\.]//g;')
SYSTEM.SUPPORTED = $(shell test -f config/Makefile.$(SYSTEM) && echo 1)
ifeq ($(SYSTEM.SUPPORTED), 1)
include config/Makefile.$(SYSTEM)
else
$(error "Platform '$(SYSTEM)' not supported")
endif
```
```bash 
#如果不想外部设置，可以在此处写为egl的androi支持的类库,反注释一下
# SYSTEM=linux-clang-egl
# include config/Makefile.$(SYSTEM)
```


# 编译，安装和默认安装路径
linux
```bash
./main_run_build_script.sh build-linux install-linux /usr/local
```
# 手动编译安装ffmpeg

```bash
make clean && make distclen && 2>dev/null

./configure \
    --extra-version=0ubuntu0.22.04.1 \
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
    --disable-shared \
    --enable-static \
    --enable-filter=gltransition \
    --extra-libs='-lGLEW -lEGL' \
    --enable-cross-compile \
    --prefix=/usr

make -j$(nproc)

sudo make install
```


# 当安装依赖库过程是 `apt` 或其他包管理工具在执行安装或更新后触发的服务重启和系统扫描步骤。这个过程通常涉及：

- **扫描已安装的包和系统服务**：这包括扫描文档、处理微码、检查内核镜像和其他包。
- **延迟服务重启**：有些服务不会立即重启，而是会在稍后的时候进行重启，除非你手动触发重启。

如果你希望避免这些“Scanning”提示和过程的干扰，下面有几种方法可以尝试：

### 1. **禁用 `man-db` 执行扫描**  
`man-db` 是用于处理手册页的工具。你可以通过禁用 `man-db` 扫描来减少这类提示。编辑 `/etc/apt/apt.conf.d/99disable-man-db` 文件：

```bash
sudo nano /etc/apt/apt.conf.d/99disable-man-db
```

然后加入以下内容：

```plaintext
DPkg::Post-Invoke { "test -x /usr/bin/mandb && /usr/bin/mandb --no-purge"; };
```

这会在安装后禁止手册页数据库的自动更新。

### 2. **禁用 `needrestart` 的扫描**  
`needrestart` 是一个检查哪些进程需要重启的工具。你可以禁用 `needrestart` 的扫描功能，从而避免在每次安装包后扫描进程。编辑 `/etc/needrestart/needrestart.conf` 文件：

```bash
sudo nano /etc/needrestart/needrestart.conf
```

找到并设置：

```plaintext
$nrconf{restart} = 'none';
```

这会禁用自动重启检查和进程扫描。

### 3. **禁用内核镜像扫描**  
如果你看到的是“Scanning linux images...”提示，并且不希望看到这类提示，你可以禁用内核镜像的扫描。编辑 `/etc/apt/apt.conf.d/99disable-kernel-scanning` 文件：

```bash
sudo nano /etc/apt/apt.conf.d/99disable-kernel-scanning
```

并添加以下内容：

```plaintext
DPkg::Post-Invoke { "test -x /usr/sbin/update-initramfs && /usr/sbin/update-initramfs -u"; };
```

这样做会阻止内核镜像的扫描过程。

### 4. **自动接受所有服务重启**  
如果你不想每次都看到有关“系统服务重启”的提示，可以使用 `systemctl` 自动重启这些服务。你可以创建一个脚本来在安装后自动重启这些服务，而不提示用户。比如创建一个脚本 `auto-restart-services.sh`，内容如下：

```bash
#!/bin/bash
systemctl restart ModemManager.service
systemctl restart auditd.service
systemctl restart docker.service
# 继续添加你想要自动重启的服务
```

然后在安装后自动运行此脚本，避免手动操作。

### 5. **使用非交互模式进行安装**  
确保你使用了 `DEBIAN_FRONTEND=noninteractive` 环境变量来避免弹出任何交互式提示。例如：

```bash
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
```

这会让系统在安装过程中不显示任何提示。

### 总结  
这些方法可以帮助你减少或消除在 `apt` 安装过程中出现的“Scanning”提示，特别是与内核、进程和服务重启相关的部分。
