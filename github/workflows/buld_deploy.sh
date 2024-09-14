name: Build, Push, and Deploy Docker Image to EC2

on:
  push:
    branches:
      - master  # Trigger the workflow on push to the main branch

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest

    steps:
      # Step 1: Checkout the code
      - name: Checkout code
        uses: actions/checkout@v3

      # Step 2: Log in to DockerHub
      - name: Log in to DockerHub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # Step 3: Build the Docker image
      - name: Build Docker image
        run: |
          docker build -t ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest .

      # Step 4: Push Docker image to DockerHub
      - name: Push Docker image
        run: |
          docker push ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest

      # Step 5: SSH to EC2 and deploy the Docker container
      - name: Deploy to EC2
        uses: appleboy/ssh-action@v0.1.4
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          port: 22
          script: |
            # Pull the latest image
            docker pull ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest
            
            # Check if the container is running and stop/remove it if it exists
            if [ "$(docker ps -q -f name=my-app)" ]; then
              echo "Stopping and removing existing container..."
              docker stop my-app
              docker rm my-app
            fi
            
            # Run the container
            echo "Starting a new container..."
            docker run -d --name my-app -p 80:80 ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest
