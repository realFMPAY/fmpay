# How to build, run, push and pull the docker image of fmpay
## 1. Register your docker ID
Lead your browser to the site: https://hub.docker.com/signup to register your
docker ID, in a similar process as that of most ID registrations.
## 2. Download git and docker
Download ‘git’ with the following command:
sudo apt install git
Download and activate ‘docker’ with the following command:

```bash
$ sudo apt update
$ sudo apt install docker.io
$ sudo systemctl start docker
$ sudo systemctl enable docker
```

## 3. Download code of fmpay
Download the code of fmpay with the following command:git clone https://github.com/realFMPAY/fmpay.git
## 4. Build the image
Cd into directory 'fmpay' and type in the following command so that you can
build your own docker image of fmpay:

```bash
$ build-docker-image/build.sh
```

At some point during the running of the command, your will be asked to tell
the process some information on the image about to be built:
1. your docker ID
2. the name of the repo
3. the name of the image

1. Your docker ID specifies the docker account where the image can be pushed
when you push it. Just input the ID you have just registered in step 1.
2. The name of the repo specifies which repo in your docker ID should the
image be pushed to when you push it. Just name it as you wish. If the repo doesn’t
exist, it will be automatically created when you push the image.
3. The name of the image helps you distinguish this image from others in the
same repo, just name it as you wish.

## 5. Run the image
Type in the following command so that you can see the information on the
docker image you have just built:

```bash
$ docker images
```

Type in the following command to run the image:

```bash
$ docker run –name mycontainer fmpay/fmpay:beta
```

### Run TPS tester
Type in the following command to run the TPS tester

```bash
$ docker exec -it mycontainer /bin/bash
$ ./demo/tester.sh
```

Note that <your docker ID>, <repo name> and <image name> are ones that
you have specified in step 4. 

## 6. Push the image
Type in the following command so that you can push the image to your
docker ID on hub.docker.com:

```bash
$ docker push <your docker ID>/<repo name>:<image name>
```

Note that the 3 parameters are the same as those in step 5.

## 7. Pull the image
Type in the following command so that you can pull down the image you
have just pushed to dockerhub in step 6 to your local machine.

```bash
$ docker pull <your docker ID>/<repo name>:<image name>
```

If you want to run it, just do it the same way as specified in step 5.