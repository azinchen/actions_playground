#!/bin/bash

targets=(x86_64 armhf aarch64)
alpine_base_images=(alpine arm32v6/alpine arm64v8/alpine)

github_repo_latest_tag()
{
    local repo=$1
    echo $(curl -Ls https://api.github.com/repos/$repo/tags | awk -F'"' '/name.*v[0-9]/ {print $4; exit}')
}

github_repo_latest_version()
{
    local repo=$1
    local latest_tag=$(github_repo_latest_tag $repo)
    local version="${latest_tag:1}"
    echo $version
}

duplicacy_arch()
{
    local target=$1
    if [[ $target == "x86_64" ]]; then
        platform=x64
    elif [[ $target == "armhf" ]]; then
        platform=arm
    elif [[ $target == "aarch64" ]]; then
        platform=arm64
    fi
    echo $platform
}

duplicacy_url()
{
    local target=$1
    local version=$2
    echo https://github.com/gilbertchen/duplicacy/releases/latest/download/duplicacy_linux_$(duplicacy_arch $target)_$version
}

qemu_static_arch()
{
    local target=$1
    if [[ $target == "armhf" ]]; then
        echo arm
    else
        echo $target
    fi
}

s6_overlay_arch()
{
    local target=$1
    if [[ $target == "x86_64" ]]; then
        echo amd64
    else
        echo $target
    fi
}

s6_overlay_url()
{
    local target=$1
    echo https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-$(s6_overlay_arch $target).tar.gz
}

alpine_base_image()
{
    local target=$1
    tag=$2
    for index in ${!targets[*]}; do
        if [[ $target == ${targets[$index]} ]]; then
            if [[ $tag == "edge" ]]; then
                echo ${alpine_base_images[$index]}:edge
                return 0
            else
                echo ${alpine_base_images[$index]}:latest
                return 0
            fi
        fi
    done
}

s6_overlay_version=$1
duplicacy_version=$2
github_tag=$3

if [[ -z ${s6_overlay_version} ]]; then
    s6_overlay_version=$(github_repo_latest_version just-containers/s6-overlay)
fi

if [[ -z ${duplicacy_version} ]]; then
    duplicacy_version=$(github_repo_latest_version gilbertchen/duplicacy)
fi

if [[ ! -z ${github_tag} ]] || [[ ${github_tag} -eq "main" ]]; then
    github_tag=latest
fi

for target in ${targets[*]}; do
    if [[ $target == "x86_64" ]]; then
        target_file=Dockerfile
    else
        target_file=Dockerfile.target-$target
    fi
    cp Dockerfile.template $target_file
    sed -i -- "s%__S6_OVERLAY__%$(s6_overlay_url $target)%g" $target_file
    sed -i -- "s%__DUPLICACY__%$(duplicacy_url $target $duplicacy_version)%g" $target_file
    sed -i -- "s%__BASEIMAGE__%$(alpine_base_image $target $github_tag)%g" $target_file
done
