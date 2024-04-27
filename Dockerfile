FROM debian:12-slim AS builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y xz-utils curl
WORKDIR /
ARG GITHUB_RELEASE_TAG
RUN GITHUB_RELEASE_TAG=${GITHUB_RELEASE_TAG%-*} \
    && curl -L https://github.com/drnick23/drplotter/releases/download/${GITHUB_RELEASE_TAG}/drplotter-${GITHUB_RELEASE_TAG}-x86_64.tar.gz --output drplotter.tar.gz \
    && tar -xf drplotter.tar.gz \
    && mv drplotter-${GITHUB_RELEASE_TAG}-x86_64 drplotter


FROM mikefarah/yq:4 AS yq


FROM debian:12-slim AS base
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends -y \
	tzdata openssl \
	&& rm -rf /var/lib/apt/lists/*
WORKDIR /app


FROM base AS compute-base
RUN apt-get update && apt-get install --no-install-recommends -y \
	ocl-icd-libopencl1 \
	&& rm -rf /var/lib/apt/lists/*
RUN mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility


FROM compute-base AS plotter
COPY --from=builder /drplotter/drplotter .
ENTRYPOINT ["./drplotter"]


FROM compute-base AS solver
COPY --from=builder /drplotter/drsolver .
ENTRYPOINT ["./drsolver"]


FROM base AS server
COPY --from=builder /drplotter/drserver .
ENTRYPOINT ["./drserver"]


FROM base AS harvester
COPY --from=yq /usr/bin/yq /usr/bin/yq
COPY --from=builder /drplotter/drharvester .
COPY harvester-docker-entrypoint.sh ./docker-entrypoint.sh
COPY harvester-docker-start.sh ./docker-start.sh
ENV CHIA_ROOT="/root/.chia/mainnet"
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["./docker-start.sh"]
