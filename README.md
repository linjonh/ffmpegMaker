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