# apkawa/vsftpd

![docker_logo](https://raw.githubusercontent.com/apkawa/docker-vsftpd/master/docker_139x115.png)![docker_fauria_logo](https://raw.githubusercontent.com/apkawa/docker-vsftpd/master/docker_fauria_161x115.png)

[![Docker Pulls](https://img.shields.io/docker/pulls/apkawa/vsftpd.svg)](https://hub.docker.com/r/apkawa/vsftpd/)
[![Docker Build Status](https://img.shields.io/docker/build/apkawa/vsftpd.svg)](https://hub.docker.com/r/apkawa/vsftpd/builds/)
[![](https://images.microbadger.com/badges/image/apkawa/vsftpd.svg)](https://microbadger.com/images/apkawa/vsftpd "apkawa/vsftpd")

Forked from [fauria/vsftpd](https://github.com/fauria/docker-vsftpd)

This Docker container implements a vsftpd server, with the following features:

 * Centos 7 base image.
 * vsftpd 3.0
 * Virtual users
 * Passive mode
 * Logging to a file or STDOUT.

### Installation from [Docker registry hub](https://registry.hub.docker.com/u/apkawa/vsftpd/).

You can download the image with the following command:

```bash
docker pull apkawa/vsftpd
```

Environment variables
----

This image uses environment variables to allow the configuration of some parameters at run time:

* Variable name: `FTP_USERS`
* Default value: admin:<random_string>
* Accepted values: Any string. Avoid whitespaces and special chars.
* Description: Username for the default FTP account. If you don't specify it through the `FTP_USER` environment variable at run time, `admin` will be used by default.

----

* Variable name: `FTP_PASV_ADDRESS_ENABLE`
* Default value: NO
* Accepted values: <NO|YES>
* Description: Enables / Disables Passive Mode

----

* Variable name: `FTP_PASV_ADDRESS_RESOLVE`
* Default value: YES
* Accepted values: <NO|YES>
* Description: Set to YES if you want to use a hostname (as opposed to IP address) in the `PASV_ADDRESS` option.

----

* Variable name: `FTP_PASV_ADDRESS`
* Default value: Docker host IP / Hostname.
* Accepted values: Any IPv4 address or Hostname (see `FTP_PASV_ADDRESS_RESOLVE`).
* Description: If you don't specify an IP address to be used in passive mode, the routed IP address of the Docker host will be used. Bear in mind that this could be a local address.

----

* Variable name: `FTP_PASV_ADDR_RESOLVE`
* Default value: NO.
* Accepted values: YES or NO.
* Description: Set to YES if you want to use a hostname (as opposed to IP address) in the PASV_ADDRESS option.

----

* Variable name: `FTP_PASV_ENABLE`
* Default value: YES.
* Accepted values: YES or NO.
* Description: Set to NO if you want to disallow the PASV method of obtaining a data connection.

----

* Variable name: `FTP_PASV_MIN_PORT`
* Default value: 21100.
* Accepted values: Any valid port number.
* Description: This will be used as the lower bound of the passive mode port range. Remember to publish your ports with `docker -p` parameter.

----

* Variable name: `FTP_PASV_MAX_PORT`
* Default value: 21110.
* Accepted values: Any valid port number.
* Description: This will be used as the upper bound of the passive mode port range. It will take longer to start a container with a high number of published ports.

----

* Variable name: `FTP_XFERLOG_STD_FORMAT`
* Default value: NO.
* Accepted values: YES or NO.
* Description: Set to YES if you want the transfer log file to be written in standard xferlog format.

----

* Variable name: `FTP_LOG_STDOUT`
* Default value: Empty string.
* Accepted values: Any string to enable, empty string or not defined to disable.
* Description: Output vsftpd log through STDOUT, so that it can be accessed through the [container logs](https://docs.docker.com/engine/reference/commandline/container_logs).

----

* Variable name: `FTP_FILE_OPEN_MODE`
* Default value: 0666.
* Accepted values: File system permissions.
* Description: The permissions with which uploaded files are created. Umasks are applied on top of this value. You may wish to change to 0777 if you want uploaded files to be executable.

----

* Variable name: `FTP_LOCAL_UMASK`
* Default value: 077.
* Accepted values: File system permissions.
* Description: The value that the umask for file creation is set to for local users. NOTE! If you want to specify octal values, remember the "0" prefix otherwise the value will be treated as a base 10 integer!

----

More variables with prefix `FTP_` pass to vsftpd.conf

As example, in documentation `banner_file=path_to_file`, variable must be FTP_BANNER_FILE=/path/to/file

http://vsftpd.beasts.org/vsftpd_conf.html

Exposed ports and volumes
----

The image exposes ports `20` and `21`. Also, exports two volumes: `/home/vsftpd`, which contains users home directories, and `/var/log/vsftpd`, used to store logs.

When sharing a homes directory between the host and the container (`/home/vsftpd`) the owner user id and group id should be 14 and 80 respectively. This corresponds to ftp user and ftp group on the container, but may match something else on the host.

Use cases
----

1) Create a temporary container for testing purposes:

    ```bash
      docker run --rm apkawa/vsftpd
    ```

2) Create a container in active mode using the default user account, with a binded data directory:

    ```bash
    docker run -d -p 21:21 -v /my/data/directory:/home/vsftpd --name vsftpd apkawa/vsftpd
    # see logs for credentials:
    docker logs vsftpd
    ```

4) Create a **production container** with a custom user account, binding a data directory and enabling both active and passive mode:

    ```bash
    docker run -d -v /my/data/directory:/home/vsftpd \
    -p 20:20 -p 21:21 -p 21100-21110:21100-21110 \
    -e FTP_USERS=myuser:mypass \
    -e FTP_PASV_ADDRESS=127.0.0.1 -e FTP_PASV_MIN_PORT=21100 -e FTP_PASV_MAX_PORT=21110 \
    --name vsftpd --restart=always apkawa/vsftpd
    ```

4) Manually add a new FTP user to an existing container:
    ```bash
    docker exec -i -t vsftpd run-vsftpd.sh add_user myuser mypass
    ```
 
5) Enable SSL and auto generate self signed certificate

    ```bash 
    docker run -d -v /my/data/directory:/home/vsftpd \
        -p 20:20 -p 21:21 -p 21100-21110:21100-21110 \
        -e FTP_USERS=myuser:mypass \
        -e FTP_CERTIFICATE_GENERATE='YES'
        -e FTP_CERTIFICATE_EXPIRE=365
        -e FTP_SSL_ENABLE='YES'
        -e FTP_CERTIFICATE_SUBJ="/C=US/ST=Warwickshire/L=Leamington/O=apkawa/OU=vsftpd/CN=localhost"
        --name vsftpd_ssl --restart=always 
        apkawa/vsftpd
    ```
   Certificate regenerated after change FTP_CERTIFICATE_SUBJ or end of expire
   
6) Enable SSL and use existed certificate. as example - use letsencrypt certificate
    ```bash 
    docker run -d 
        -v /my/data/directory:/home/vsftpd \
        -v /my/path/to/letsencrypt/example.com/:/etc/certs/:ro
        -p 20:20 -p 21:21 -p 21100-21110:21100-21110 \
        -e FTP_USERS=myuser:mypass \
        -e FTP_SSL_ENABLE='YES'
        -e FTP_RSA_CERT_FILE="/etc/certs/fullchain.crt"
        -e FTP_RSA_PRIVATE_KEY_FILE="/etc/certs/key.pem"
        --name vsftpd_ssl --restart=always 
        apkawa/vsftpd
    ```

