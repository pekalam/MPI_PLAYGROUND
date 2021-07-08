FROM ubuntu:latest
RUN apt-get -y update
RUN apt-get -y install mpich openssh-server nfs-kernel-server
RUN apt-get -y install netcat
RUN apt-get -y install expect nano

COPY wait-for.sh /bin/wait-for.sh
RUN chmod +x /bin/wait-for.sh
RUN yes | ssh-keygen -N "" -f /root/id_rsa
RUN echo 'root:root' | chpasswd
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
COPY ssh_config /etc/ssh/ssh_config
COPY sshd_config /etc/ssh/sshd_config

WORKDIR /root
COPY auto_ssh_send.exp auto_ssh_send.exp
COPY send_ssh.sh send_ssh.sh
RUN chmod +x /root/send_ssh.sh

EXPOSE 22 111 2049

COPY entrypoint.sh /root/entrypoint.sh
RUN chmod a+x /root/entrypoint.sh


ARG mpirole
COPY manager_nfs_setup.sh manager_nfs_setup.sh
RUN /bin/bash -c 'if [ "$mpirole" == "manager" ] ; then source ./manager_nfs_setup.sh ; fi'
RUN rm ./manager_nfs_setup.sh

ENTRYPOINT [ "/root/entrypoint.sh" ]