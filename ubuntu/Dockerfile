ARG FROM_IMAGE=buildpack-deps
ARG FROM_TAG=24.04
FROM ${FROM_IMAGE}:${FROM_TAG}

ARG TARGETARCH

ARG NODE_VERSION="18 20 22"
ARG DISTRO=ubuntu
ARG RUNNER=root

ENV DEBIAN_FRONTEND=noninteractive
SHELL [ "/bin/bash", "--login", "-e", "-o", "pipefail", "-c" ]
WORKDIR /tmp

COPY ./${DISTRO}/setup /imagegeneration/installers
RUN bash /imagegeneration/installers/main.sh

RUN for file in /root/.bashrc /root/.profile /etc/bash.bashrc /etc/profile; do \
	echo '[ -f /etc/environment ] && source /etc/environment' >> "$file"; \
	done

ARG BUILD_DATE
ARG BUILD_TAG=ubuntu
ARG BUILD_REF
ARG BUILD_TAG_VERSION
ARG BUILD_OWNER
ARG BUILD_REPO
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
	org.opencontainers.image.vendor="${BUILD_OWNER}" \
	org.opencontainers.image.authors="https://github.com/${BUILD_OWNER}" \
	org.opencontainers.image.url="https://github.com/${BUILD_OWNER}/${BUILD_REPO}/tree/${BUILD_REF}/${DISTRO}/" \
	org.opencontainers.image.source="https://github.com/${BUILD_OWNER}/${BUILD_REPO}" \
	org.opencontainers.image.documentation="https://github.com/${BUILD_OWNER}/${BUILD_REPO}" \
	org.opencontainers.image.version="${BUILD_TAG_VERSION}" \
	org.opencontainers.image.title="${BUILD_TAG}-${TARGETARCH}" \
	org.opencontainers.image.description="Ubuntu CI image for Forgejo Runner / act" \
	org.opencontainers.image.revision="${BUILD_REF}"

USER ${RUNNER}
