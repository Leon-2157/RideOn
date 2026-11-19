FROM docker.io/library/node:20-alpine

WORKDIR /app

COPY package.json package-lock.json next.config.ts postcss.config.mjs tsconfig.json ./
COPY public ./public
COPY src ./src
COPY node_modules ./node_modules
COPY .next ./.next

ENV NODE_ENV=production
ENV PORT=3001
ENV HOSTNAME=0.0.0.0

EXPOSE 3001

CMD ["node", "node_modules/next/dist/bin/next", "start", "-p", "3001", "-H", "0.0.0.0"]

