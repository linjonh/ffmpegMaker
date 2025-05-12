#! /bin/bash
# ‣ Clone ffnvcodec
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
# ‣ Install ffnvcodec
cd nv-codec-headers || exit 1
sudo make install
cd ..