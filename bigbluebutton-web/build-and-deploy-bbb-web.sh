#!/bin/bash

# check if path is correct

path=`pwd`
actualFolder=${path##*/}

if [ "$actualFolder" != "bigbluebutton-web" ]; then
    echo "Your not in the correct folder. Please run the script in bigbluebutton/bigbluebutton-web"
    exit;
fi

bbbConfSecret=`sudo bbb-conf --secret`
set -- $bbbConfSecret
serverURL=${2}
secret=${4}

# remove /bigbluebutton/ from serverURL, because it will be added
# set the Internal Field Separator to /
IFS='/'
urlSplitted=$serverURL
set -- $urlSplitted
# reset Internal Field Seperator to |
IFS='|'
serverURL="${1}//${3}"

echo Welcome to bbb-web production script
echo You\'ll be asked to enter your sudo pwd
echo Please make sure your serverURL and secret from bbb-conf --secret is set correctly
echo your serverURL \(without /bigbluebutton/ at the end\):
echo $serverURL
echo your secret:
echo $secret
while true; do
    read -p "Is that correct? (yes/no)" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo Please check your bbb-conf --secret and run this script again.; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo building bbb-common-message
./deploy.sh

echo developing BBB-Web

# Edit the file and change the values of bigbluebutton.web.serverURL and securitySalt.

serverURL_cmd="s#bigbluebutton.web.serverURL=.*#bigbluebutton.web.serverURL=$serverURL#g"
secret_cmd="s#securitySalt=.*#securitySalt=$secret#g"

echo Change values in bigbluebutton.properties
echo "set meetingExpireIfNoUserJoinedInMinutes=15"
sed -i 's/meetingExpireIfNoUserJoinedInMinutes.*/meetingExpireIfNoUserJoinedInMinutes=15/g' grails-app/conf/bigbluebutton.properties

echo "set meetingExpireWhenLastUserLeftInMinutes=15"
sed -i 's/meetingExpireWhenLastUserLeftInMinutes.*/meetingExpireWhenLastUserLeftInMinutes=15/g' grails-app/conf/bigbluebutton.properties

echo "set bigbluebutton.web.logoutURL=www.corona-school.de"
sed -i 's/bigbluebutton.web.logoutURL.*/bigbluebutton.web.logoutURL=www.corona-school.de/g' grails-app/conf/bigbluebutton.properties

echo "set allowStartStopRecording=false"
sed -i 's/allowStartStopRecording=.*/allowStartStopRecording=false/g' grails-app/conf/bigbluebutton.properties

echo "set attendeesJoinViaHTML5Client=true"
sed -i 's/attendeesJoinViaHTML5Client=.*/attendeesJoinViaHTML5Client=true/g' grails-app/conf/bigbluebutton.properties

echo "set moderatorsJoinViaHTML5Client=true"
sed -i 's/moderatorsJoinViaHTML5Client=.*/moderatorsJoinViaHTML5Client=true/g' grails-app/conf/bigbluebutton.properties

echo "lockSettingsDisablePrivateChat=true"
sed -i 's/lockSettingsDisablePrivateChat=.*/lockSettingsDisablePrivateChat=true/g' grails-app/conf/bigbluebutton.properties

echo "set bigbluebutton.web.serverURL=${serverURL}"
sed -i $serverURL_cmd grails-app/conf/bigbluebutton.properties

echo "set securitySalt=${secret}"
sed -i $secret_cmd grails-app/conf/bigbluebutton.properties

sudo chmod -R ugo+rwx /var/bigbluebutton
sudo chmod -R ugo+rwx /var/log/bigbluebutton
mkdir -p ~/.sbt/1.0
rm -f ~/.sbt/1.0/global.sbt
(echo "resolvers += \"Artima Maven Repository\" at \"http://repo.artima.com/releases\"
updateOptions := updateOptions.value.withCachedResolution(true)") > ~/.sbt/1.0/global.sbt

echo deploy bbb-common-web
./deploy.sh

echo stop bbb-web service
sudo service bbb-web stop

echo build bbb-web
./build.sh

echo deploying bbb-web
grails assemble
mkdir -p exploded && cd exploded
jar -xvf ../build/libs/bigbluebutton-0.10.0.war
cp ../run-prod.sh .
sudo cp -R /usr/share/bbb-web /usr/share/bbb-web-old
sudo rm -rf /usr/share/bbb-web/assets/ /usr/share/bbb-web/META-INF/ /usr/share/bbb-web/org/ /usr/share/bbb-web/run-prod.sh  /usr/share/bbb-web/WEB-INF/
sudo cp -R . /usr/share/bbb-web/
sudo chown bigbluebutton:bigbluebutton /usr/share/bbb-web
sudo chown -R bigbluebutton:bigbluebutton /usr/share/bbb-web/assets/ /usr/share/bbb-web/META-INF/ /usr/share/bbb-web/org/ /usr/share/bbb-web/run-prod.sh /usr/share/bbb-web/WEB-INF/

echo Script finished
