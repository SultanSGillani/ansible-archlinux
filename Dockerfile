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

# Switch default target from graphical to multi-user.
RUN systemctl set-default multi-user.target

COPY ansible-playbook-wrapper /usr/local/bin/

RUN addgroup -S ansible \
    && useradd -rm -d /etc/ansible --shell /bin/bash -g ansible ansible  \
    && chown -R ansible:ansible /etc/ansible \
    && printf "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts \
    && printf "ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ansible

RUN mkdir -p /etc/ansible/roles

WORKDIR /etc/ansible/roles/roles_to_test

ENV ANSIBLE_LIBRARY=${ANSIBLE_LIBRARY} \
    ANSIBLE_VERBOSITY=${ANSIBLE_VERBOSITY} \
    ANSIBLE_ROLES_PATH=${ANSIBLE_ROLES_PATH} \
    ANSIBLE_HOST_KEY_CHECKING=${ANSIBLE_HOST_KEY_CHECKING} \
    ANSIBLE_LOG_PATH=${ANSIBLE_LOG_PATH} \
    ANSIBLE_EXECUTABLE=${ANSIBLE_EXECUTABLE} \
    ANSIBLE_BECOME=${ANSIBLE_BECOME} \
    ANSIBLE_BECOME_USER=${ANSIBLE_BECOME_USER} \
    ANSIBLE_PIPELINING=${ANSIBLE_PIPELINING} \
    ANSIBLE_INVENTORY=${ANSIBLE_INVENTORY} \
    ANSIBLE_INVENTORY_ENABLED=${ANSIBLE_INVENTORY_ENABLED} \
    TTY=${TTY}

VOLUME ["/sys/fs/cgroup", "/etc/ansible/roles/roles_to_test", "/tmp"]

CMD ["bash"]
