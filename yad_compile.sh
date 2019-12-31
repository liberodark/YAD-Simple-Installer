wget https://github.com/v1cont/yad/releases/download/v5.0/yad-5.0.tar.xz && tar -xvf yad-5.0.tar.xz
cd yad-5.0
export CFLAGS="$CFLAGS -DBORDERS=1"
autoreconf -ivf && intltoolize
./configure --enable-standalone
make