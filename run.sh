#!/bin/bash
ENVFILE=".env"
mkdir -p output

function preflight() {
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
ROOTPW_ENC='${ROOTPW_ENC}'
UNAME='${UNAME}'
USERPW_ENC='${USERPW_ENC}'
EOF
}

function build() {
  if [[ ! -f ${ENVFILE} ]]; then
    preflight 
  fi
  . ${ENVFILE}

  VER=${1:-8.7}
  SRC_VER=${2:-1.0.0}

  podman build -t docker.io/jijisa/burrito-isobuilder .
  podman run --privileged -v $(pwd)/output:/output --rm \
    --env="ROOTPW_ENC=${ROOTPW_ENC}" \
    --env="UNAME=${UNAME}" \
    --env="USERPW_ENC=${USERPW_ENC}" \
    docker.io/jijisa/burrito-isobuilder ${VER} ${SRC_VER}
}

function run() {
  if [[ ! -f ${ENVFILE} ]]; then
    preflight 
  fi
  . ${ENVFILE}
  podman build -t docker.io/jijisa/burrito-isobuilder .
  podman run -it --privileged -v $(pwd)/output:/output --rm \
    --env="ROOTPW_ENC=${ROOTPW_ENC}" \
    --env="UNAME=${UNAME}" \
    --env="USERPW_ENC=${USERPW_ENC}" \
    --entrypoint=/bin/bash \
    docker.io/jijisa/burrito-isobuilder
}
function USAGE() {
  echo "USAGE: $0 [-h|-b|-p|-r] [options]" 1>&2
  echo
  echo " -h --help                   Display this help message."
  echo " -p --password               Set up root and user password."
  echo " -b --build [options]        Build burrito iso."
  echo " -r --run [options]          Run a container for building burrito iso"
  echo "                             and go into the container."
  echo "Options"
  echo "-------"
  echo "Rocky Linux version          Default: 8.7"
  echo "Burrito source version       Default: 1.0.0"
  echo
  echo "ex) $0 --build 8.7 1.0.1"
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
    -p | --password)
      preflight
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
