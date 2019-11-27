#!/bin/bash
set -e
function init() {

  LOG_STDOUT=$FTP_LOG_STDOUT

  # Do not log to STDOUT by default:
  if [ "$LOG_STDOUT" = "**Boolean**" ]; then
    export LOG_STDOUT=''
  else
    export LOG_STDOUT='Yes.'
  fi

  if [ ! $FTP_USERS ]; then
    # If no env var for FTP_USER has been specified, use 'admin':
    # If no env var has been specified, generate a random password for FTP_USER:
    FTP_USERS="admin:$(cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c${1:-16})"
  fi

  USERS=""
  # Create home dir and update vsftpd user db:
  IFS=';' read -ra _USERS <<<$FTP_USERS
  for i in "${_USERS[@]}"; do
    IFS=':' read user pass <<<$i
    user_add $user $pass
    USERS="$USERS
    - $user:$pass"
  done
  if [ $FTP_CERTIFICATE_GENERATE = 'YES' ]; then
    generate_certificate
  fi

  unset FTP_USERS \
    FTP_LOG_STDOUT \
    FTP_CERTIFICATE_SUBJ \
    FTP_CERTIFICATE_GENERATE \
    FTP_CERTIFICATE_EXPIRE

  # Set passive mode parameters:
  if [ "$FTP_PASV_ADDRESS" = "**IPv4**" ]; then
    export FTP_PASV_ADDRESS=$(route | awk '/default/ { print $3 }')
  fi
  SETTINGS=''
  while IFS='=' read -r name value; do
    if [[ $name == 'FTP_'* ]]; then
      name=$(echo -n $name | sed 's/^FTP_//' | tr '[:upper:]' '[:lower:]')
      echo "$name=$value" >>/etc/vsftpd/vsftpd.conf
      SETTINGS="$SETTINGS
      $name: $value"
    fi
  done < <(env)

  # Get log file path
  export LOG_FILE=$(grep xferlog_file /etc/vsftpd/vsftpd.conf | cut -d= -f2)

  # stdout server info:
  if [ ! $LOG_STDOUT ]; then
    cat <<EOF
    *************************************************
    *                                               *
    *    Docker image: apkawa/vsftpd                *
    *    https://github.com/apkawa/docker-vsftpd    *
    *                                               *
    *************************************************

    SERVER SETTINGS
    ---------------
    · FTP Users:
      $USERS

    · Log file: $LOG_FILE
    · Redirect vsftpd log to STDOUT: No.
    $SETTINGS

EOF
  else
    /usr/bin/ln -sf /dev/stdout $LOG_FILE
  fi

  # Run vsftpd:
  /usr/sbin/vsftpd &>/dev/null /etc/vsftpd/vsftpd.conf
}

function reload() {
  killall -s HUP /usr/sbin/vsftpd -q || true
}

function user_add() {
  _user=$1
  _pass=$2
  _dir="/home/vsftpd/${_user}"
  mkdir -p $_dir
  chown -R --silent ftp:ftp $_dir || true
  echo -e "${_user}\n${_pass}" >>/tmp/virtual_users.txt
  /usr/bin/db_load -T -t hash -f /tmp/virtual_users.txt /etc/vsftpd/virtual_users.db
  rm -f /tmp/virtual_users.txt
  reload
}

function user_del() {
  # TODO
  echo "user_del"
}

function user_list() {
  # TODO
  echo "user_list"
}

function generate_certificate() {
  _subj=${1:-${FTP_CERTIFICATE_SUBJ}}
  _expire=${2:-${FTP_CERTIFICATE_EXPIRE}}
  _root=/etc/vsftpd/certs/
  mkdir -p $_root
  cd $_root
  is_valid='yes'
  if [ -f server.crt ]; then
    if [! $(openssl x509 -checkend 86400 -in server.crt) ]; then
      is_valid='no'
    fi
    exist_subj=$(openssl x509 -subject -in /etc/vsftpd/certs/server.crt -noout | awk '{print $2}')
    if [ $exist_subj != $_subj ]; then
      is_valid='no'
    fi
  else
    is_valid='yes'
  fi

  if [ $is_valid == 'no' ]; then
    openssl genrsa -des3 -passout pass:x -out server.pass.key 2048
    openssl rsa -passin pass:x -in server.pass.key -out server.key
    rm server.pass.key
    openssl req -new -key server.key -out server.csr -subj "$_subj"
    openssl x509 -req -days $_expire -in server.csr -signkey server.key -out server.crt
  fi

  cat <<EOF
  Example ssl config:

    FTP_RSA_CERT_FILE: "$_root/server.crt"
    FTP_RSA_PRIVATE_KEY_FILE: "$_root/server.key"
    FTP_CERTIFICATE_SUBJ: '$_subj'
    FTP_CERTIFICATE_GENERATE: 'YES'
    FTP_FORCE_LOCAL_DATA_SSL: 'YES'
    FTP_FORCE_LOCAL_LOGINS_SSL: 'YES'
    FTP_SSL_TLSV1_2: 'YES'
    FTP_SSL_TLSV1_1: 'YES'
    FTP_SSL_TLSV1: 'YES'
    FTP_SSL_SSLV2: 'NO'
    FTP_SSL_SSLV3: 'NO'
    FTP_REQUIRE_SSL_REUSE: 'NO'
    FTP_SSL_CIPHERS: 'HIGH'
    FTP_SSL_ENABLE: 'YES'

EOF
}

function start() {
  init
}

$*
