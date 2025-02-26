# dpdk-base-ubi

To build this Container
```
podman build --file Containerfile --tag dpdk-base-ubi .
podman tag localhost/dpdk-base-ubi:latest quay.io/dcain/dpdk-base-ubi:latest
podman push localhost/dpdk-base-ubi:latest quay.io/dcain/dpdk-base-ubi:latest
```
