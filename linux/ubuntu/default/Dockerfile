ARG FROM_IMAGE=ghcr.io/OWNER/ubuntu
ARG FROM_TAG=act-latest-dev
FROM ${FROM_IMAGE}:${FROM_TAG}

ARG TARGETARCH

ARG NODE_VERSION="16 18 20 22"
ARG DISTRO=ubuntu
ARG TYPE=default
ARG RUNNER=root

ENV DEBIAN_FRONTEND=noninteractive
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

COPY ./linux/${DISTRO}/scripts /imagegeneration/installers
RUN bash /imagegeneration/installers/${TYPE}.sh

# Metadata
ARG BUILD_DATE
ARG BUILD_TAG=${TYPE}
ARG BUILD_REF
ARG BUILD_TAG_VERSION
ARG BUILD_OWNER
ARG BUILD_REPO
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
	org.opencontainers.image.vendor="${BUILD_OWNER}" \
	org.opencontainers.image.authors="https://github.com/${BUILD_OWNER}" \
	org.opencontainers.image.url="https://github.com/${BUILD_OWNER}/${BUILD_REPO}/tree/${BUILD_REF}/linux/${DISTRO}/${TYPE}/" \
	org.opencontainers.image.source="https://github.com/${BUILD_OWNER}/${BUILD_REPO}" \
	org.opencontainers.image.documentation="https://github.com/${BUILD_OWNER}/${BUILD_REPO}" \
	org.opencontainers.image.version="${BUILD_TAG_VERSION}" \
	org.opencontainers.image.title="${BUILD_TAG}-${TARGETARCH}" \
	org.opencontainers.image.description="Default image built on latest act base" \
	org.opencontainers.image.revision="${BUILD_REF}" \
	org.opencontainers.image.base.name="${FROM_IMAGE}:${FROM_TAG}"

USER ${RUNNER}
