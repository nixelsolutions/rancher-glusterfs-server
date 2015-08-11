FROM ubuntu:14.04

MAINTAINER Manel Martinez <manel@nixelsolutions.com>

RUN apt-get update && \
    apt-get install -y python-software-properties software-properties-common
RUN add-apt-repository -y ppa:gluster/glusterfs-3.7 && \
    apt-get update && \
    apt-get install -y glusterfs-server supervisor openssh-server dnsutils sshpass

ENV ROOT_PASSWORD **ChangeMe**

ENV SSH_PORT 2222
ENV SSH_USER root
ENV SSH_OPTS -p ${SSH_PORT} -o ConnectTimeout=20 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
ENV GLUSTER_VOL ranchervol
ENV GLUSTER_BRICK_PATH /gluster_volume
ENV GLUSTER_CONF_FLAG /etc/gluster.env
ENV SERVICE_NAME gluster

ENV DEBUG 0

VOLUME ["${GLUSTER_BRICK_PATH}"]
VOLUME /var/lib/glusterd

RUN mkdir -p /var/run/sshd /root/.ssh /var/log/supervisor /var/run/gluster
RUN perl -p -i -e "s/^Port .*/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
RUN perl -p -i -e "s/#?PasswordAuthentication .*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
RUN perl -p -i -e "s/#?PermitRootLogin .*/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN grep ClientAliveInterval /etc/ssh/sshd_config >/dev/null 2>&1 || echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config

RUN mkdir -p /usr/local/bin
ADD ./bin /usr/local/bin
RUN chmod +x /usr/local/bin/*.sh
ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/local/bin/run.sh"]
