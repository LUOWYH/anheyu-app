FROM golang:1.21-alpine AS builder
ARG VERSION=unknown
ARG COMMIT=unknown
ARG BUILD_DATE=unknown
ARG TARGETARCH
ARG TARGETPLATFORM
RUN apk add --no-cache gcc g++ musl-dev sqlite-dev git
WORKDIR /src
RUN git clone https://github.com/anzhiyu-c/anheyu-app.git .
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -o anheyu-app ./cmd/anheyu-app

FROM alpine:latest
ARG VERSION=unknown
ARG COMMIT=unknown
ARG BUILD_DATE=unknown
ARG TARGETARCH
LABEL org.opencontainers.image.title="Anheyu App"
LABEL org.opencontainers.image.description="Anheyu App - Self-hosted blog and content management system"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.revision="${COMMIT}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.source="https://github.com/anzhiyu-c/anheyu-app"
LABEL org.opencontainers.image.url="https://github.com/anzhiyu-c/anheyu-app"
LABEL org.opencontainers.image.documentation="https://github.com/anzhiyu-c/anheyu-app/blob/main/README.md"
LABEL org.opencontainers.image.vendor="AnzhiYu"
LABEL org.opencontainers.image.licenses="MIT"
WORKDIR /anheyu
RUN apk update \
    && apk add --no-cache tzdata vips-tools ffmpeg libheif libraw-tools sqlite \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone
ENV AN_SETTING_DEFAULT_ENABLE_FFMPEG_GENERATOR=true \
    AN_SETTING_DEFAULT_ENABLE_VIPS_GENERATOR=true \
    AN_SETTING_DEFAULT_ENABLE_LIBRAW_GENERATOR=true \
    ANHEYU_DATABASE_TYPE=sqlite \
    ANHEYU_DATABASE_PATH=/anheyu/data/anheyu.db
COPY --from=builder /src/anheyu-app ./anheyu-app
COPY --from=builder /src/default_files ./default-data
COPY --from=builder /src/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./anheyu-app ./entrypoint.sh \
    && mkdir -p /anheyu/data \
    && chmod 777 /anheyu/data \
    && echo "🚀 Anheyu App Docker Image Built with SQLite Support!" \
    && echo "📋 Build Information:" \
    && echo "   Version: ${VERSION}" \
    && echo "   Commit:  ${COMMIT}" \
    && echo "   Date:    ${BUILD_DATE}" \
    && echo "   Arch:    ${TARGETARCH}"
EXPOSE 8091 443
ENTRYPOINT ["./entrypoint.sh"]
CMD ["./anheyu-app"]
