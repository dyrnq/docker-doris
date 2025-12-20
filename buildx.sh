#!/usr/bin/env bash
set -Eeo pipefail

base_image="${base_image:-}"
version="${version:-2.1.7}";
push="${push:-false}"
repo="${repo:-dyrnq}"
image_name="${image_name:-doris}"
platforms="${platforms:-linux/amd64,linux/arm64/v8}"
curl_opts="${curl_opts:-}"
while [ $# -gt 0 ]; do
    case "$1" in
        --base-image|--base)
            base_image="$2"
            shift
            ;;
        --version|--ver)
            version="$2"
            shift
            ;;
        --push)
            push="$2"
            shift
            ;;
        --curl-opts)
            curl_opts="$2"
            shift
            ;;
        --platforms)
            platforms="$2"
            shift
            ;;
        --repo)
            repo="$2"
            shift
            ;;
        --image-name|--image)
            image_name="$2"
            shift
            ;;
        --*)
            echo "Illegal option $1"
            ;;
    esac
    shift $(( $# > 0 ? 1 : 0 ))
done


latest=$(cat latest);
latest_tag=" --tag $repo/$image_name:$version"

if [ "$latest" = "$version" ]; then
    echo "latest version is $latest"
    latest_tag="${latest_tag} --tag $repo/$image_name:latest"
fi



if [ "$base_image"x = "x" ]; then

    if [[ $version == 3* || $version == 4* ]]; then
       base_image="eclipse-temurin:17.0.13_11-jdk-noble"
    else
       base_image="eclipse-temurin:8u432-b06-jdk-noble"
    fi

fi

if [[ "$version" == "3.0.0" ]]; then
    platforms="linux/amd64"
fi

download_version="${version}"
if [[ "$version" == "2.0.15" ]]; then
    download_version="2.0.15.1"
fi


docker buildx build \
--platform ${platforms} \
--output "type=image,push=${push}" \
--build-arg BASE_IMAGE=${base_image} \
--build-arg DORIS_VERSION=${version} \
--build-arg DORIS_DOWNLOAD_VERSION=${download_version} \
--build-arg CURL_OPTS=${curl_opts} \
--file ./Dockerfile . \
${latest_tag}



