FROM centos:7


ARG USER_ID=14
ARG GROUP_ID=50

# May be file or user:pwd;user2:pwd
ENV FTP_USERS ''
ENV FTP_PASV_ADDRESS **IPv4**
ENV FTP_PASV_ADDR_RESOLVE NO
ENV FTP_PASV_ENABLE YES
ENV FTP_PASV_MIN_PORT 21100
ENV FTP_PASV_MAX_PORT 21110
ENV FTP_XFERLOG_STD_FORMAT NO
ENV FTP_FILE_OPEN_MODE 0666
ENV FTP_LOCAL_UMASK 077
ENV FTP_WRITE_ENABLE YES

ENV FTP_LOG_STDOUT **Boolean**

MAINTAINER Fer Uria <fauria@gmail.com>
MAINTAINER Apkawa <apkawa@gmail.com>
LABEL Description="vsftpd Docker image based on Centos 7. Supports passive mode and virtual users." \
	License="Apache License 2.0" \
	Usage="docker run -d -p [HOST PORT NUMBER]:21 -v [HOST FTP HOME]:/home/vsftpd fauria/vsftpd" \
	Version="1.0"



COPY vsftpd.conf /etc/vsftpd/
COPY vsftpd_virtual /etc/pam.d/
COPY run-vsftpd.sh /usr/local/bin/

RUN yum install -y \
        vsftpd \
        net-tools \
        db4-utils \
        db4 \
        psmisc \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && curl -fsSL --compressed \
        -o /usr/local/bin/dumb-init \
        https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 \
    && chmod +x /usr/local/bin/dumb-init \
    && chmod +x /usr/local/bin/run-vsftpd.sh \
    && mkdir -p /home/vsftpd/ \
    && usermod -u ${USER_ID} ftp \
    && groupmod -g ${GROUP_ID} ftp \
    && chown -R ftp:ftp /home/vsftpd/

VOLUME /home/vsftpd
VOLUME /var/log/vsftpd

EXPOSE 20 21

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/usr/local/bin/run-vsftpd.sh", "start"]
