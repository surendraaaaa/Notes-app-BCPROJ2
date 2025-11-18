# STAGE 1 - BUILD STAGE
# base image for node project
FROM node:22-alpine AS builder

# create work directory /app
WORKDIR /app

# Copy only required files to install dependencies (for Node its package*.json)
COPY package*.json ./

# why npm ci and not npm install? because npm ci is fast and it consider lock file and make sure required version of dependencies are installed
RUN npm ci 

# copy source code to working directory
COPY . .

# build the application
RUN npm run build

# STAGE 2 - SERVE FRONTEND WITH NGINX
# use nginx base image to serve application on nginx
FROM nginx:alpine

# in Node when we build the application static files are created in the /build folder so only copy that folder to nginx folder
COPY --from=builder /app/build /usr/share/nginx/html

# copy nginx.conf file
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 to serve frontend on port 80
EXPOSE 80

# start nginx, deamon off means dont run application in back ground run it on web server
CMD ["nginx", "-g", "daemon off;"]
