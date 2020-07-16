#!/bin/bash

FILE=/usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
if [ -f "$FILE" ]; then
    echo "$FILE exists."
else 
    echo "$FILE does not exist."
    echo "Please make sure $FILE exists."
    echo "Script stopped without any changes."
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

sudo bbb-conf --stop

echo backup bigbluebutton.properties
sudo cp -rf /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties_old

# Edit the file and change the values of bigbluebutton.web.serverURL and securitySalt.

serverURL_cmd="s#bigbluebutton.web.serverURL=.*#bigbluebutton.web.serverURL=$serverURL#g"
secret_cmd="s#securitySalt=.*#securitySalt=$secret#g"

echo Change values in bigbluebutton.properties

echo "set meetingExpireIfNoUserJoinedInMinutes=15"
sudo sed -i 's/meetingExpireIfNoUserJoinedInMinutes.*/meetingExpireIfNoUserJoinedInMinutes=15/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "set meetingExpireWhenLastUserLeftInMinutes=15"
sudo sed -i 's/meetingExpireWhenLastUserLeftInMinutes.*/meetingExpireWhenLastUserLeftInMinutes=15/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "set bigbluebutton.web.logoutURL=www.corona-school.de"
sudo sed -i 's/bigbluebutton.web.logoutURL.*/bigbluebutton.web.logoutURL=www.corona-school.de/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "set allowStartStopRecording=false"
sudo sed -i 's/allowStartStopRecording=.*/allowStartStopRecording=false/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "set attendeesJoinViaHTML5Client=true"
sudo sed -i 's/attendeesJoinViaHTML5Client=.*/attendeesJoinViaHTML5Client=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "set moderatorsJoinViaHTML5Client=true"
sudo sed -i 's/moderatorsJoinViaHTML5Client=.*/moderatorsJoinViaHTML5Client=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "set lockSettingsDisablePrivateChat=true"
sudo sed -i 's/lockSettingsDisablePrivateChat=.*/lockSettingsDisablePrivateChat=true/g' /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "set bigbluebutton.web.serverURL=${serverURL}"
sudo sed -i $serverURL_cmd /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

echo "set securitySalt=${secret}"
sudo sed -i $secret_cmd /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties

sudo bbb-conf --start

echo Script finished
