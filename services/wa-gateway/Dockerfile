FROM docker.io/library/node:20-alpine

WORKDIR /app

COPY package.json package-lock.json ./
COPY node_modules ./node_modules
COPY db-auth.js server.js ./

RUN mkdir -p /app/session

ENV NODE_ENV=production
ENV WHATSAPP_GATEWAY_PORT=3100
ENV SESSION_DIR=/app/session

EXPOSE 3100

CMD ["node", "server.js"]
