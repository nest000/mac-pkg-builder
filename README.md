# mac-pkg-builder

## folder structure
* /app/bin should contains the binary of the application
* /app/resources should contains logo-dark.png, logo-light.png and welcome.html
* /app/scripts can optionally contains a post-install.sh shell script which is triggered after installation routine

## arguments
* app name as arg1
* app version as arg2
* install path as arg3, this is the target application where the APP will be installed through the pkg installer

## result
the built package will be saved into /app/dist as pkg file