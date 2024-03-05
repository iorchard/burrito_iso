#!/bin/bash
set -e 

# If you build the iso that includes powerflex rpm packages,
# set this variable to the url that you can download powerflex package tarball.
# The tarball should not have the subdirectries.
PFX_PKG_URL="http://192.168.151.110:8000/burrito/powerflex_pkgs.tar.gz"

# Hitachi hspc-operator image tarball
HITACHI_IMAGE_URL="http://192.168.151.110:8000/burrito/hitachi-csi-images.tar"

# environment variable file
ENVFILE=".env"

mkdir -p output

function check_env() {
  if [ -z "${ROOTPW_ENC}" -o \
	   -z "${UNAME}" -o \
	   -z "${USERPW_ENC}" -o \
	   -z "${INCLUDE_NETAPP}" -o \
	   -z "${INCLUDE_PFX}" -o \
	   -z "${INCLUDE_HITACHI}" -o \
	   -z "${INCLUDE_PRIMERA}" \
	 ]; then
	echo "The environment file is wrong. ./run.sh -e again."
	exit 1
  fi
}

function setup_env() {
  ROOTPW_ENC=$(python3 -c 'import crypt,getpass;pw=getpass.getpass("root password: ");print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit(1))')
  if [ -z ${ROOTPW_ENC} ]; then
    echo "root password is not matched."
    exit 1
  fi
  read -p "Username: " UNAME
  USERPW_ENC=$(python3 -c "import crypt,getpass;pw=getpass.getpass('${UNAME} user password: ');print(crypt.crypt(pw) if (pw==getpass.getpass('Confirm: ')) else exit(1))")
  if [ -z ${USERPW_ENC} ]; then
    echo "${UNAME} user password is not matched."
    exit 1
  fi
  cat <<EOF > ${ENVFILE}
ROOTPW_ENC=${ROOTPW_ENC}
UNAME=${UNAME}
USERPW_ENC=${USERPW_ENC}
INCLUDE_NETAPP=1
INCLUDE_PFX=1
PFX_PKG_URL=${PFX_PKG_URL}
INCLUDE_HITACHI=1
HITACHI_IMAGE_URL=${HITACHI_IMAGE_URL}
INCLUDE_PRIMERA=1
EOF
}

function build() {
  if [[ ! -f ${ENVFILE} ]]; then
    setup_env
  fi
  . ${ENVFILE}
  check_env
  VER=${1:-8.9}
  SRC_VER=${2:-1.3.1}

  podman build -t docker.io/jijisa/burrito-isobuilder .
  podman run --privileged -v $(pwd)/output:/output --rm \
	$(for e in $(cat .env);do echo -n "--env=${e} ";done) \
    docker.io/jijisa/burrito-isobuilder ${VER} ${SRC_VER}
}

function run() {
  if [[ ! -f ${ENVFILE} ]]; then
    setup_env
  fi
  . ${ENVFILE}
  podman build -t docker.io/jijisa/burrito-isobuilder .
  podman run -it --privileged -v $(pwd)/output:/output --rm \
	$(for e in $(cat .env);do echo -n "--env=${e} ";done) \
    --entrypoint=/bin/bash \
    docker.io/jijisa/burrito-isobuilder
}
function USAGE() {
  echo "USAGE: $0 [-h|-e|-b|-r] [options]" 1>&2
  echo
  echo " -h --help                   Display this help message."
  echo " -e --env                    Set up an environment file."
  echo " -b --build [options]        Build burrito iso."
  echo " -r --run [options]          Run and go into the container."
  echo
  echo "Options"
  echo "-------"
  echo "Rocky Linux version          Default: 8.9"
  echo "Burrito source version       Default: 1.3.1"
  echo
  echo "ex) $0 --build 8.9 1.3.1"
  echo
}
if [ $# -lt 1 ]; then
  USAGE
  exit 1
fi

OPT=$1
shift
while true
do
  case "$OPT" in
    -h | --help)
      USAGE
      exit 0
      ;;
    -b | --build)
      build "$@"
      break
      ;;
    -e | --env)
      setup_env
      break
      ;;
    -r | --run)
      run
      break
      ;;
    *)
      echo Error: unknown option: "$OPT" 1>&2
      echo " "
      USAGE
      exit 1
      ;;
  esac
done
