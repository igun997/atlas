# Build stage
FROM node:lts-alpine AS build
WORKDIR /build

# Install openssl, libc6, and their development libraries
RUN apk add --no-cache openssl openssl-dev libc6-compat

# Install modules without lock files
COPY package.json /build/
RUN yarn install --no-lockfile

# Build
COPY . /build
RUN yarn db:generate
RUN yarn build

# Regenerate node modules as production without lock files
RUN rm -rf ./node_modules
RUN yarn install --production --no-lockfile

# Bundle stage
FROM node:15-alpine AS production

WORKDIR /app

# Copy from build stage
COPY --from=build /build/node_modules ./node_modules
COPY --from=build /build/package.json ./
COPY --from=build /build/public ./public
COPY --from=build /build/prisma ./prisma
COPY --from=build /build/.next ./.next

# Start script
USER node
EXPOSE 3000
CMD ["yarn", "start:prod"]
