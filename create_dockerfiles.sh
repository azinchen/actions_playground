#!/bin/bash

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

s6_overlay_version=$1
duplicacy_version=$2
github_tag=$3

if [[ -z ${s6_overlay_version} ]]; then
    s6_overlay_version=$(github_repo_latest_version just-containers/s6-overlay)
    echo s6 overlay version is not defined, use $s6_overlay_version version
else
    echo s6 overlay version $s6_overlay_version defined
fi

if [[ -z ${duplicacy_version} ]]; then
    duplicacy_version=$(github_repo_latest_version gilbertchen/duplicacy)
    echo Duplicacy version is not defined, use $duplicacy_version version
else
    echo Duplicacy version $duplicacy_version defined
fi

if [[ -z ${github_tag} ]]; then
    github_tag="main"
    echo GitHub tag is not defined, use $github_tag version
else
    echo GitHub tag $github_tag defined
fi

target_file=Dockerfile

cp Dockerfile.template $target_file
sed -i -- "s%__DUPLICACY_VERSION__%$duplicacy_version%g" $target_file
if [[ $github_tag == "edge" ]]; then
    sed -i -- "s%__BASEIMAGE_TAG__%edge%g" $target_file
else
    sed -i -- "s%__BASEIMAGE_TAG__%latest%g" $target_file
fi
