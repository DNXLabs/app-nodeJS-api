FROM node:10-alpine as base

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm config set depth 0 \
    && npm install --production

# ---- Builder ----
FROM base AS build-deps
ENV NODE_ENV=development
COPY . .
RUN npm install --no-optional \
    && npx babel --copy-files --include-dotfiles src -d dist --extensions ".js,.jsx"

# ---- Release ----
FROM base
ARG BUILD_ENV=development
ENV NODE_ENV=${BUILD_ENV}
ENV BUILD_ENV=${BUILD_ENV}
COPY --from=build-deps /app/dist .

# ---- Config ----
EXPOSE 80 443 2222
CMD ["node", "server.js"]
