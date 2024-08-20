#!/bin/bash

# Convert Windows paths to MSYS2 paths and export necessary environment variables

# Node.js
export NODEJS_HOME=$(cygpath -u "D:\laragon\bin\nodejs\node-v18.17.1")
export PATH="$NODEJS_HOME:$PATH"

# PHP
export PHP_HOME=$(cygpath -u "D:\laragon\bin\php\php-8.1.10-Win32-vs16-x64")
export PATH="$PHP_HOME:$PATH"

# MySQL
export MYSQL_HOME=$(cygpath -u "D:\laragon\bin\mysql\mysql-8.0.30-winx64\bin")
export PATH="$MYSQL_HOME:$PATH"

# Composer
export COMPOSER_HOME=$(cygpath -u "D:\laragon\bin\composer")
export PATH="$COMPOSER_HOME:$PATH"

# Git
export GIT_HOME=$(cygpath -u "D:\laragon\bin\git\bin")
export PATH="$GIT_HOME:$PATH"

# Nginx
export NGINX_HOME=$(cygpath -u "D:\laragon\bin\nginx\nginx-1.22.0")
export PATH="$NGINX_HOME:$PATH"

# Redis
export REDIS_HOME=$(cygpath -u "D:\laragon\bin\redis\redis-x64-5.0.14.1")
export PATH="$REDIS_HOME:$PATH"

# Python
export PYTHON_HOME=$(cygpath -u "D:\laragon\bin\python\python-3.10")
export PATH="$PYTHON_HOME:$PATH"
export PATH="$PYTHON_HOME/Scripts:$PATH"

# Additional Laragon utilities
export LARAGON_UTILS_HOME=$(cygpath -u "D:\laragon\bin\laragon\utils")
export PATH="$LARAGON_UTILS_HOME:$PATH"

# Notepad++
export NOTEPADPP_HOME=$(cygpath -u "D:\laragon\bin\notepad++")
export PATH="$NOTEPADPP_HOME:$PATH"

# Telnet
export TELNET_HOME=$(cygpath -u "D:\laragon\bin\telnet")
export PATH="$TELNET_HOME:$PATH"

# Laragon usr bin
export LARAGON_USR_BIN=$(cygpath -u "D:\laragon\usr\bin")
export PATH="$LARAGON_USR_BIN:$PATH"

# Print the paths to verify
echo "NODEJS_HOME is set to $NODEJS_HOME"
echo "PHP_HOME is set to $PHP_HOME"
echo "MYSQL_HOME is set to $MYSQL_HOME"
echo "COMPOSER_HOME is set to $COMPOSER_HOME"
echo "GIT_HOME is set to $GIT_HOME"
echo "NGINX_HOME is set to $NGINX_HOME"
echo "REDIS_HOME is set to $REDIS_HOME"
echo "PYTHON_HOME is set to $PYTHON_HOME"
echo "LARAGON_UTILS_HOME is set to $LARAGON_UTILS_HOME"
echo "NOTEPADPP_HOME is set to $NOTEPADPP_HOME"
echo "TELNET_HOME is set to $TELNET_HOME"
echo "LARAGON_USR_BIN is set to $LARAGON_USR_BIN"
echo "PATH is set to $PATH"
