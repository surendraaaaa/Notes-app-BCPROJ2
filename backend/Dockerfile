# BACKEND DOCKERFILE

# use node alpine image as a BASE IMAGE to reduce size of the docker image
FROM node:22-alpine

# create /app workdirectory inside the container
WORKDIR /app

# Copy only package*.json to install dependecies
COPY package*.json ./

# install the dependencies using command npm ci
RUN npm ci

# Copy source code to working directory
COPY . . 

# Expose port 5000 for backend
EXPOSE 5000

# start the backend
CMD ["node", "server.js"]