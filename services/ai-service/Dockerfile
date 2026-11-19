FROM docker.io/library/golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/ai-service .

FROM docker.io/library/alpine:3.24

RUN apk add --no-cache ca-certificates tzdata wget

WORKDIR /app
COPY --from=builder /out/ai-service /app/ai-service

ENV PORT=8083
EXPOSE 8083

CMD ["/app/ai-service"]
