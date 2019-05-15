FROM scratch
LABEL maintainer="Sultan Gillani (sultangillani)"

ADD archlinux.tar /
ENV LANG=en_US.UTF-8
ENV container=docker

USER root

# remove unneeded unit files.
WORKDIR /lib/systemd/system/sysinit.target.wants/

RUN (for i in *; do [ "${i}" = "systemd-tmpfiles-setup.service" ] || rm -vf "${i}"; done); \
    rm -vf /lib/systemd/system/multi-user.target.wants/*; \
    rm -vf /etc/systemd/system/*.wants/*; \
    rm -vf /lib/systemd/system/local-fs.target.wants/*; \
    rm -vf /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -vf /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -vf /lib/systemd/system/basic.target.wants/*;

RUN mkdir -p /var/cache/pacman/pkg && /usr/sbin/paccache -r

COPY ansible-playbook-wrapper /usr/local/bin/

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible/roles/roles_to_test/tests && printf "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Switch default target from graphical to multi-user.
RUN systemctl set-default multi-user.target

RUN useradd -ms /bin/bash ansible
RUN printf "ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN chown -R ansible:ansible /etc/ansible

WORKDIR /etc/ansible/roles/roles_to_test/tests

USER ansible
ENV TERM xterm
ENV ANSIBLE_CONFIG /etc/ansible/roles/roles_to_test/tests/ansible.cfg

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
CMD ["bash"]
