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
  IFS=';' read -ra _USERS <<< $FTP_USERS
  for i in "${_USERS[@]}"; do
    IFS=':' read user pass <<< $i
    user_add $user $pass
    USERS="$USERS
    - $user:$pass"
  done


  unset FTP_USERS FTP_LOG_STDOUT

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
  chown -R ftp:ftp $_dir
  echo -e "${_user}\n${_pass}" >> /tmp/virtual_users.txt
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

function start() {
  init
}

$*
