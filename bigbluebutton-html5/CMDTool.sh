#!/bin/bash

usage() {
set +x
cat 1>&2 << EOF
Script for Setup, Build and Start BigBlueButton HTML5 Development Client
Script need to be executed as root on Ubuntu 16.04

USAGE:
    wget -qO- https://raw.githubusercontent.com/corona-school/bigbluebutton/corona-school/bigbluebutton-html5/CMDTool.sh | bash -s -- [OPTIONS]

OPTIONS:
    -h      Print help
    -s      Setup HTML5 Development Client (Creates user and pulls repo)
    -i      Install HTML5 Development Client (Installs dependencies and setups development environment)
    -u      User for HTML5 Development Client (Required for -s, -i, -r & -b)
    -g      Git Repository of BigBlueButton (Required for -s)
    -b      Branch of Git Repository
    -r      Run HTML5 Development Client
    -c      Stop HTML5 Development Client
    -p      Build HTML5 Development Client for production

EXAMPLES:
Setup & Install HTML5 Development Client
    -s -i -u bbb -b corona-school -g "https://github.com/corona-school/bigbluebutton.git"

Run HTML5 Development Client
    -r -u bbb

Build HTML5 Development Client & Start HTML5 Production Client
    -p
    sudo systemctl start bbb-html5
EOF
}

err() {
    echo $1
    echo "Do -h for more information"
    exit 1
}

main() {
while builtin getopts "hsu:g:b:ircp" opt "${@}"; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        s)
            SETUP=true
            ;;
        u)
            USER_=$OPTARG
            ;;
        g)
            REPO=$OPTARG
            ;;
        b)
            BRANCH=$OPTARG
            ;;
        i)
            INSTALL=true
            ;;
        r)
            RUN=true
            ;;
        c)
            STOP=true
            ;;
        p)
            BUILD=true
            ;;
        :)
            err "Missing option argument for -$OPTARG"
            ;;
        \?)
            err "Invalid option: -$OPTARG" >&2
            ;;
    esac
done

if [[ -z $SETUP && -z $INSTALL && -z $RUN && -z $STOP && -z $BUILD ]]; then
    usage
    exit 0
fi
if [ ! -z $SETUP ]; then
    if [ -z $USER_ ]; then
        err "-s requires -u [option]"
    fi
    if [ -z $REPO ]; then
        err "-s requires -g [option]"
    fi
fi
if [ ! -z $INSTALL ]; then
    if [ -z $USER_ ]; then
        err "-i requires -u [option]"
    fi
fi
if [ ! -z $START ]; then
    if [ -z $USER_ ]; then
        err "-r requires -u [option]"
    fi
fi
if [ ! -z $BUILD ]; then
    if [ -z $USER_ ]; then
        err "-p requires -u [option]"
    fi
fi

if [ ! -z $SETUP ]; then
    setup $USER_ $REPO $BRANCH
fi
if [ ! -z $INSTALL ]; then
    install $USER_
fi
if [ ! -z $RUN ]; then
    run $USER_
fi
if [ ! -z $STOP ]; then
    cancel
fi
if [ ! -z $BUILD ]; then
    build $USER_
fi
}

setup() {
if ! id -u $1 >/dev/null 2>&1; then
    useradd -m $1
    echo "Enter password for user $1"
    passwd $1
    fi
adduser $1 sudo
sudo -i -u $1 bash << EOF
    cd ~
    mkdir dev
    cd dev
    git clone $2
    cd bigbluebutton
    if [ ! -z $3 ]; then
        git checkout $3
    fi
EOF
}

install() {
cd "/home/$1/"
apt-get install git-core ant ant-contrib openjdk-8-jdk-headless
apt-get install screen
sudo -i -u $1 bash << EOF
    cd ~
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> ~/.profile
    source ~/.profile
EOF
cd "/home/$1/"
export SDKMAN_DIR="/usr/local/sdkman" && curl -s "https://get.sdkman.io" | bash
source "/usr/local/sdkman/bin/sdkman-init.sh"
sdk install gradle 5.5.1
sdk install grails 3.3.9
sdk install sbt 1.2.8
sdk install maven 3.5.0
sudo -i -u $1 bash << EOF
    cd ~/dev/bigbluebutton/bigbluebutton-html5/
    curl https://install.meteor.com/ | sh
    meteor update --allow-superuser --release 1.8
    wsUrl="$(grep 'wsUrl' /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml | xargs)"
    sed -i "s|wsUrl.*|$wsUrl|" private/config/settings.yml
EOF
cd "/home/$1/dev/bigbluebutton/bigbluebutton-html5/"
sudo -i -u $1 bash << EOF
    cd ~/dev/bigbluebutton/bigbluebutton-html5/
    meteor npm install
EOF
}

run() {
systemctl stop bbb-html5
sudo -i -u $1 bash << EOF
    cd ~/dev/bigbluebutton/bigbluebutton-html5/
    screen -d -m -S bbb-html5-dev npm start
EOF
}

cancel() {
kill $(ls -laR /var/run/screen/ | grep bbb-html5-dev | cut -d " " -f 11 | cut -d "." -f 1)
}

build() {
systemctl stop bbb-html5
sudo -i -u $1 bash << EOF
    cd ~/dev/bigbluebutton/bigbluebutton-html5/
    meteor build --server-only ./meteorbundle
EOF
tar -xzvf /home/$1/dev/bigbluebutton/bigbluebutton-html5/meteorbundle/*.tar.gz -C "/usr/share/meteor"
}

main "$@" || exit 1

