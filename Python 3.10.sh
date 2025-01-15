#!/bin/bash

# Verificar si el script se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root o con sudo."
    exit 1
fi

# Variables
PYTHON_VERSION="3.10.12"
PYTHON_SRC_DIR="/usr/src"
PYTHON_INSTALL_DIR="/usr/local"
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
DEPENDENCIES="gcc gcc-c++ make zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel xz xz-devel libffi-devel wget tar"

# Instalar dependencias necesarias
echo "Instalando dependencias necesarias..."
dnf groupinstall "Development Tools" -y
dnf install ${DEPENDENCIES} -y

# Descargar y descomprimir el código fuente de Python
echo "Descargando Python ${PYTHON_VERSION}..."
cd ${PYTHON_SRC_DIR}
wget ${PYTHON_URL} -O Python-${PYTHON_VERSION}.tgz

echo "Descomprimiendo el código fuente..."
tar -xvf Python-${PYTHON_VERSION}.tgz
cd Python-${PYTHON_VERSION}

# Compilar e instalar Python
echo "Compilando e instalando Python ${PYTHON_VERSION}..."
./configure --enable-optimizations --prefix=${PYTHON_INSTALL_DIR}
make -j$(nproc)
make altinstall

# Verificar la instalación
echo "Verificando la instalación de Python ${PYTHON_VERSION}..."
if ! [ -x "$(command -v ${PYTHON_INSTALL_DIR}/bin/python3.10)" ]; then
    echo "Error: Python 3.10 no se instaló correctamente."
    exit 1
fi

# Configurar alternatives
echo "Configurando Python 3.10 como predeterminado con alternatives..."
alternatives --install /usr/bin/python python ${PYTHON_INSTALL_DIR}/bin/python3.10 1
alternatives --config python

# Verificar la versión predeterminada de Python
echo "Python predeterminado:"
python --version

# Configurar pip
echo "Actualizando pip para Python 3.10..."
${PYTHON_INSTALL_DIR}/bin/python3.10 -m ensurepip --upgrade
${PYTHON_INSTALL_DIR}/bin/python3.10 -m pip install --upgrade pip

echo "¡Python ${PYTHON_VERSION} instalado y configurado con éxito!"
