# syntax=docker/dockerfile:1
# Образ со встроенным userver + PostgreSQL-клиентом (см. документацию userver).
FROM ghcr.io/userver-framework/ubuntu-22.04-userver-pg:latest AS builder

WORKDIR /src

COPY CMakeLists.txt ./
COPY src ./src

RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j"$(nproc)"

FROM ghcr.io/userver-framework/ubuntu-22.04-userver-pg:latest

WORKDIR /app

RUN mkdir -p /app/build

COPY --from=builder /src/build/masterclasses-service /app/masterclasses-service
COPY configs/ /app/configs/
COPY static/ /app/static/
COPY scripts/docker-backend-entrypoint.sh /app/docker-backend-entrypoint.sh
RUN chmod +x /app/docker-backend-entrypoint.sh

EXPOSE 80 8081

ENTRYPOINT ["/app/docker-backend-entrypoint.sh"]
CMD ["./masterclasses-service", "-c", "configs/static_config.yaml"]
