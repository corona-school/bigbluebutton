// Init
attachMeteorMessageListener(function (msg) {
    updateWebcamProtection();
});

/**
 * The Meteor variable is not defined at the beginning.
 * This function waits for the varaible to be defined.
 * @param callback Meteor that is 100% defined
 */
function fetchMeteor(callback) {
    if (typeof Meteor !== "undefined") {
        callback(Meteor);
    } else {
        setTimeout(fetchMeteor, 250);
    }
}

/**
 * Create a change listener to update the webcam visibility
 */
function attachMeteorMessageListener(onMeteorMessage) {
    fetchMeteor(function (meteorInstance) {
        meteorInstance.connection._processOneDataMessageSuper = meteorInstance.connection._processOneDataMessage;
        meteorInstance.connection._processOneDataMessage = function (msg, updates) {
            meteorInstance.connection._processOneDataMessageSuper(msg, updates);
            onMeteorMessage(msg);
        };
    });
}

/**
 * Update the camera visibility of all users based on the locked state
 */
function updateWebcamProtection() {
    // Get user states (username and locked state)
    let users = getUsers();
    let clientUser = getClientUser();
    if (clientUser === null)
        return;

    let isClientModerator = clientUser.role === "MODERATOR";

    // Update state of all users
    for (let index in users) {
        let user = users[index];
        let locked = user.locked;
        let isModerator = user.role === "MODERATOR";

        if (user.connectionStatus === "online" && clientUser.userId !== user.userId) {
            // Update camera state based on locked and moderator state
            setCameraVisible(user.name, !locked || isModerator || isClientModerator);
        }
    }
}

/**
 * Get all online users with their locked state
 * @return {[]}
 */
function getUsers() {
    if (typeof Meteor !== 'undefined') {
        let collectionSource = Meteor.connection._stores["users"];

        // Undefined check for the collection source
        if (typeof collectionSource !== 'undefined') {
            return collectionSource._getCollection().find().fetch();
        }
    }

    return [];
}

/**
 * Get user info of the current client (me)
 * @return {[]}
 */
function getClientUserId() {
    if (typeof Meteor !== 'undefined') {
        let collectionSource = Meteor.connection._stores["local-settings"];

        // Undefined check for the collection source
        if (typeof collectionSource !== 'undefined') {
            let clientSettings = collectionSource._getCollection().find().fetch();

            if (clientSettings.length === 0) {
                return null;
            } else {
                return clientSettings[0].userId;
            }
        }
    }

    return [];
}

/**
 * Get the client user (me)
 * @returns {*|Promise<Response>}
 */
function getClientUser() {
    let clientId = getClientUserId();
    if (clientId === null)
        return null;

    let users = getUsers();
    for (let index in users) {
        let user = users[index];

        // If the user has the same id
        if (user.userId === clientId) {
            return user;
        }
    }

    // Client user not online?
    return null;
}

/**
 * Change the camera visibility of the target user
 * @param targetUserName The name of the target user
 * @param visible Boolean state of the camera visibility
 */
function setCameraVisible(targetUserName, visible) {
    // Search for all webcam items
    $("div[class^='videoListItem-']").each(function (i, element) {

        // Get username of the webcam item
        let userNameSpan = $("span", element).filter(function () {
            return this.className.match(/\buserName-/);
        });

        // Use dropdown instead if userNameSpan is not available (If more than 2 cameras are visible)
        if (userNameSpan === undefined || userNameSpan.length === 0) {
            userNameSpan = $("span", element).filter(function () {
                return this.className.match(/\bdropdownTrigger-/);
            });
        }

        let userName = userNameSpan[0].innerHTML;

        // Is the username equals to the target?
        if (targetUserName === userName) {
            // Get current webcam image
            let webCamItem = $(element);

            // Change state of webcam visibility
            if (visible) {
                webCamItem.css('display', 'block');
            } else {
                webCamItem.css('display', 'none');
            }
        }
    });
}