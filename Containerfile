FROM registry.access.redhat.com/ubi9/ubi:latest

LABEL com.redhat.component="dpdk-base-container" \
    name="dpdk-base-ubi" \
    version="v4.19.0" \
    summary="dpdk-base-ubi" \
    io.openshift.expose-services="" \
    io.openshift.tags="< tags >" \
    io.k8s.display-name="dpdk-base-ubi" \
    io.openshift.s2i.scripts-url=image:///usr/libexec/s2i \
    io.s2i.scripts-url=image:///usr/libexec/s2i \
    description="dpdk-base-ubi9"

ENV \
    APP_ROOT=/opt/app-root \
    # The $HOME is not set by default, but some applications needs this variable
    HOME=/opt/app-root/src \
    PATH=$PATH:/opt/app-root/src/bin:/opt/app-root/bin \
    PLATFORM="ubi9"

ENV BUilDER_VERSION 0.2
ENV DPDK_VER=24.11.1
ENV DPDK_DIR=/usr/share/dpdk-stable-${DPDK_VER}
ENV RTE_TARGET=x86_64-default-linux-gcc
ENV RTE_EXEC_ENV=linux
ENV RTE_SDK=${DPDK_DIR}

# Install prerequisite packages
RUN dnf groupinstall -y "Development Tools" && \
    dnf install --skip-broken -y wget numactl numactl-devel gcc libibverbs-devel logrotate rdma-core tcpdump python3 python3-pip sudo && \
    dnf clean all

# Install Meson, Ninja and pyelftools packages with pip, required to build DPDK. Python >= 3.7 is required
RUN pip3.9 install meson ninja pyelftools

# Download the DPDK libraries
RUN wget http://fast.dpdk.org/rel/dpdk-${DPDK_VER}.tar.xz -P /usr/share && \
    tar -xpvf /usr/share/dpdk-${DPDK_VER}.tar.xz -C /usr/share && \
    rm -f /usr/share/dpdk-${DPDK_VER}.tar.xz

RUN cd ${DPDK_DIR} && \
    meson setup -Dexamples=all -Dplatform=generic build && \
    cd build && \
    ninja && \
    meson install && \
    ldconfig && \
    cp app/dpdk-testpmd /usr/local/bin

# Directory with the sources is set as the working directory so all STI scripts
# can execute relative to this path.
WORKDIR ${HOME}

# Reset permissions of modified directories and add default user
RUN useradd -u 1001 -r -g 0 -d ${HOME} -s /sbin/nologin \
      -c "Default Application User" default && \
  chown -R 1001:0 ${APP_ROOT}

# Allows non-root users to use dpdk-testpmd
RUN setcap cap_sys_resource,cap_ipc_lock,cap_net_raw+ep /usr/local/bin/dpdk-testpmd
RUN setcap cap_sys_resource,cap_ipc_lock,cap_net_raw+ep /usr/local/bin/dpdk-test-bbdev

# Add supplementary group 801 to user 1001 in order to use the VFIO device in a non-privileged pod.
RUN groupadd -g 801 hugetlbfs
RUN usermod -aG hugetlbfs default
