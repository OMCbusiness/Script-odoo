#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root o con sudo."
    exit 1
fi

PYTHON_VERSION="3.12.0"
PYTHON_SRC_DIR="/usr/src"
PYTHON_INSTALL_DIR="/usr/local"
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
DEPENDENCIES="gcc gcc-c++ make zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel wget tar"

echo "Instalando dependencias necesarias..."
dnf install ${DEPENDENCIES} -y

echo "Descargando Python ${PYTHON_VERSION}..."
cd ${PYTHON_SRC_DIR}
if [ ! -f Python-${PYTHON_VERSION}.tgz ]; then
    wget ${PYTHON_URL} -O Python-${PYTHON_VERSION}.tgz
else
    echo "Archivo Python-${PYTHON_VERSION}.tgz ya existe, saltando descarga."
fi

rm -rf Python-${PYTHON_VERSION}

echo "Descomprimiendo el código fuente..."
tar -xvf Python-${PYTHON_VERSION}.tgz
cd Python-${PYTHON_VERSION}

echo "Compilando e instalando Python ${PYTHON_VERSION}..."
./configure --enable-optimizations --enable-shared --prefix=${PYTHON_INSTALL_DIR}
make -j$(nproc)
make altinstall

if ! [ -x "${PYTHON_INSTALL_DIR}/bin/python3.12" ]; then
    echo "Error: Python ${PYTHON_VERSION} no se instaló correctamente."
    exit 1
fi

echo "Configurando Python 3.12 como predeterminado con alternatives..."
alternatives --install /usr/bin/python python ${PYTHON_INSTALL_DIR}/bin/python3.12 1
alternatives --set python ${PYTHON_INSTALL_DIR}/bin/python3.12

echo "Python predeterminado:"
python --version

echo "Actualizando pip para Python 3.12..."
${PYTHON_INSTALL_DIR}/bin/python3.12 -m ensurepip --upgrade
${PYTHON_INSTALL_DIR}/bin/python3.12 -m pip install --upgrade pip

echo "¡Python ${PYTHON_VERSION} instalado y configurado con éxito!"
