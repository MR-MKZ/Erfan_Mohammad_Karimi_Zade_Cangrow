#!/bin/bash


if [[ -d "./wp/themes" ]]; then
    if [[ -d "./wp/themes/mkz-theme" ]]; then
        cd ./wp/themes/mkz-theme
        git pull
    else
        cd ./wp/themes
        git clone https://github.com/karimierfan/mkz-theme
    fi
else
    mkdir ./wp/themes
    cd ./wp/themes
    git clone https://github.com/karimierfan/mkz-theme
fi