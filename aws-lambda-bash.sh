#!/usr/bin/env bash
# VERSION 0.0.1

set -e 
set -o pipefail

###define output and work directory
OUTDIR=/tmp/build/stage
WORKDIR=/tmp/build
mkdir -p $OUTDIR

### change the currect directory to output directory
cd $OUTDIR

echo "======================================================================================================"
echo "Install all os dependancies..."
echo "======================================================================================================"

### installs python 3.8
amazon-linux-extras enable python3.8 2>&1 1>/dev/null
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 2>&1 1>/dev/null
yum --enablerepo=epel install python3.8 -y 2>&1 1>/dev/null
yum -y groupinstall "development tools"
yum -y install libpng-devel libtiff-devel libjpeg-devel openjpeg-devel fontconfig-devel 
yum -y install epel-release zip cmake3 poppler-utils wget xz gcc gcc-c++ cmake3

cd /usr/src/

echo "======================================================================================================"
echo "Install tesseract..."
echo "======================================================================================================"

###yum by default has tesseract version 3.0.4 
###the latest builds are not availabe as of [10/12/2020] in yum repo
###thus the need to build tesseract from scratch

echo "Fetching archives..."
wget http://ftpmirror.gnu.org/autoconf-archive/autoconf-archive-2019.01.06.tar.xz
wget http://leptonica.org/source/leptonica-1.77.0.tar.gz
wget https://github.com/tesseract-ocr/tesseract/archive/4.1.1.tar.gz -O tesseract-4.1.1.tar.gz
tar xfJ autoconf-archive-2019.01.06.tar.xz
cd autoconf-archive-2019.01.06/
./configure --prefix=/usr
make
make install

echo "Building Leptonica for Tesseract build..."
cd /usr/src/
tar xzf leptonica-1.77.0.tar.gz
cd leptonica-1.77.0/
./configure --prefix=/usr/local/
make
make install

echo "building tesseract from source..."
cd /usr/src/
tar xzf tesseract-4.1.1.tar.gz 2>&1 1>/dev/null
cd tesseract-4.1.1 
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
./autogen.sh 2>&1 1>/dev/null
./configure --prefix=/usr/local/ --with-extra-libraries=/usr/local/lib/ 2>&1 1>/dev/null
make 2>&1 1>/dev/null
make install 2>&1 1>/dev/null


echo "======================================================================================================"
echo "Install python packages..."
echo "======================================================================================================"

cd $OUTDIR
pip3.8 install --upgrade pip 2>&1 1>/dev/null
pip install -U pip
pip install -U --no-cache-dir -r /tmp/build/requirements.txt -t ./python  2>&1 1>/dev/null 
#above line installs the pyhton packages listed in the requirements file to a folder named python
#This is one of the AWS requirements for the Lambda architecture 
#that is where the system looks for the python packages
mkdir -p lib


echo "======================================================================================================"
echo "Owning the libs and bins..."
echo "Copying files to zip folder..."
echo "======================================================================================================"

cp /usr/local/bin/tesseract ./
cp /usr/lib64/* ./lib
cp /usr/bin/* ./lib

echo "Getting tesseract data file..."
cd tessdata
wget https://github.com/tesseract-ocr/tessdata/raw/master/eng.traineddata 2>&1 1>/dev/null

echo "======================================================================================================"
cd $OUTDIR
echo "size of files ..."
du -sh $OUTDIR/*
echo "======================================================================================================"

echo "Zipping Lambda layer..."
zip -r $WORKDIR/tesseract-layer.zip * 2>&1 1>/dev/null