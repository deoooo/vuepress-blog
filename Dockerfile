FROM node:12 as base
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm build

FROM nginx:alpine as production

COPY --from=base /app/public /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
