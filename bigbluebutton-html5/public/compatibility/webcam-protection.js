// Load jquery
var script = document.createElement('script');
script.src = "https://ajax.googleapis.com/ajax/libs/jquery/1.6.3/jquery.min.js";
document.getElementsByTagName('head')[0].appendChild(script);

// Init
attachMutationObserver();

/**
 * Create a document change listener to update the webcam visibility
 */
function attachMutationObserver() {
    // Create document mutation listener
    var mutationObserver = new MutationObserver(function(mutations) {

        // Search for the right event type
        mutations.forEach(function(mutation) {
            // Update the protection only for childList types to avoid a infinity loop
            if (mutation.type == "childList") {

                // Update the protection
                updateWebcamProtection();
            }
        });
    });

    // Listen for document changes
    mutationObserver.observe(document.documentElement, {
        attributes: true,
        characterData: true,
        childList: true,
        subtree: true,
        attributeOldValue: true,
        characterDataOldValue: true
    });
}


/**
 * Update the camera visibility of all users based on the locked state
 */
function updateWebcamProtection() {
    // Get user states (username and locked state)
    let userStates = getUserStates();

    // The first user is always me
    let skipUser = true;

    // Update state of all users
    for (let username in userStates) {
        let locked = userStates[username];

        // Skip the user because thats me! We don't want to hide our own camera.
        if (skipUser) {
            skipUser = false;
            continue;
        }

        // Update camera state based on locked and moderator state
        setCameraVisible(username, !locked || isModerator());
    }
}

/**
 * Is the current client a moderator?
 * @return {boolean}
 */
function isModerator() {
   let flag = false;

    // Search for user list
    $("div[class^='userListColumn-']").each(function(i, element) {

        // Is a settings button in the user list?
        let isModerator = $("button", element).filter(function() {
            return this.className.match(/\boptionsButton-/);
        }).length === 1;

        // Return the result
        flag = true;
    });

    return flag;
}

/**
 * Get all online users with their locked state
 * @return {map}
 */
function getUserStates() {
    let users = [];

    // Search for user items in the online list
    $("div[class^='userName-']").each(function(i, element) {
        // Get the username of the entry item
        let username = $(element).children().children()[0].innerHTML.replace("&nbsp;", "");

        // Get lock state of the user item
        let locked = $(element).children().next().children().children().length == 1;

        // Save to map
        users[username] = locked;
    });

    return users;
}


/**
 * Change the camera visibility of the target user
 * @param targetUserName The name of the target user
 * @param visible Boolean state of the camera visibility
 */
function setCameraVisible(targetUserName, visible) {
    // Search for all webcam items
    $("div[class^='videoListItem-']").each(function(i, element) {

        // Get username of the webcam item
        let userName = $("span", element).filter(function() {
            return this.className.match(/\buserName-/);
        })[0].innerHTML;

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