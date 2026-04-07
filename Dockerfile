# syntax=docker/dockerfile:1.7

ARG NODE_IMAGE=node:20.5.0-bullseye-slim

FROM ${NODE_IMAGE} AS deps-base
WORKDIR /app
COPY build/package.json build/package-lock.json ./
COPY --chmod=0755 build/build.sh ./

FROM deps-base AS deps-production
ENV NODE_ENV=production
RUN ./build.sh --production

FROM deps-base AS deps-development
ENV NODE_ENV=development
RUN ./build.sh

FROM ${NODE_IMAGE} AS runtime-base
WORKDIR /app
ENV PORT=3000
COPY app/server.js ./
COPY --chmod=0755 app/run.sh ./
ENTRYPOINT ["./run.sh"]
HEALTHCHECK --interval=5s --timeout=3s --start-period=125s --retries=3 \
  CMD ["node", "-e", "const http=require('http');const port=process.env.PORT||3000;const req=http.get({host:'127.0.0.1',port,path:'/healthcheck'},res=>process.exit(res.statusCode===200?0:1));req.on('error',()=>process.exit(1));"]
EXPOSE 3000

FROM runtime-base AS production
ENV NODE_ENV=production
RUN apt-get update \
 && apt-get install -y --no-install-recommends sysstat \
 && rm -rf /var/lib/apt/lists/*
COPY --from=deps-production /app/node_modules ./node_modules
USER node

FROM runtime-base AS staging
ENV NODE_ENV=staging
COPY --from=deps-production /app/node_modules ./node_modules
USER node
CMD ["--debug"]

FROM runtime-base AS development
ENV NODE_ENV=development
COPY --from=deps-development /app/node_modules ./node_modules
USER node