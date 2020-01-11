#!/usr/bin/env bash
set -ex

CHANNEL=beta
rust_stable_docker_image=docker.pkg.github.com/nuclrlab/ncbrust/ncbrust:1.40.0

cd "$(dirname "$0")"
rm -rf usr/

cd ..
docker pull $rust_stable_docker_image

ARGS=(
  --workdir /ncb
  --volume "$PWD:/ncb"
  --rm
)

if [[ -n $CI ]]; then
  # Share the real ~/.cargo between docker containers in CI for speed
  ARGS+=(--volume "$HOME:/home")
else
  # Avoid sharing ~/.cargo when building locally to avoid a mixed macOS/Linux
  # ~/.cargo
  ARGS+=(--volume "$PWD:/home")
fi
ARGS+=(--env "CARGO_HOME=/home/.cargo")
# kcov tries to set the personality of the binary which docker
# doesn't allow by default.
ARGS+=(--security-opt "seccomp=unconfined")

# Ensure files are created with the current host uid/gid
if [[ -z "$DOCKER_RUN_NOSETUID" ]]; then
  ARGS+=(--user "$(id -u):$(id -g)")
fi

# Environment variables to propagate into the container
ARGS+=(
  --env BUILDKITE
  --env BUILDKITE_AGENT_ACCESS_TOKEN
  --env BUILDKITE_BRANCH
  --env BUILDKITE_COMMIT
  --env BUILDKITE_JOB_ID
  --env BUILDKITE_TAG
  --env CI
  --env CODECOV_TOKEN
  --env CRATES_IO_TOKEN
)

set -x
docker run "${ARGS[@]}" "$rust_stable_docker_image" build-docker-image/cargo-install-all.sh build-docker-image/usr

cd "$(dirname "$0")"

mkdir -p usr/bin/demo
mkdir -p usr/bin/scripts
cp -f -r -v ../scripts usr/bin/
cp -f -r -v ../demo usr/bin/

docker build -t reallysatoshinakamoto/nuclrcore:"$CHANNEL" .

# rm -rf usr/

maybeEcho=
if [[ -n $CI ]]; then
  echo "Not CI, skipping |docker push|"
  maybeEcho="echo"
else
  (
    set +x
    if [[ -n $DOCKER_PASSWORD && -n $DOCKER_USERNAME ]]; then
      echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
    fi
  )
fi
$maybeEcho docker push reallysatoshinakamoto/nuclrcore:"$CHANNEL"
