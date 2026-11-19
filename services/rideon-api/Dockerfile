FROM docker.io/library/golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/rideon-api .

FROM docker.io/library/alpine:3.24

RUN apk add --no-cache ca-certificates tzdata wget && mkdir -p /app/uploads

WORKDIR /app
COPY --from=builder /out/rideon-api /app/rideon-api

ENV PORT=8080
EXPOSE 8080

CMD ["/app/rideon-api"]

