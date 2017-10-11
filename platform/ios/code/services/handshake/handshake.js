function handshake(req, resp){
    
    var finishHandshake = function(userEmail){
        // Login the relevant user and return auth token
        ClearBlade.loginUser(userEmail, userPass, function(err, creds) {
            if(err) {
                resp.error("User login failure: " + JSON.stringify(creds));
            } else {
                pullState(creds, resp);
            }
        });
    };
    
    var lookupDeviceUser = function(device){
            var userEmail = device.name+"@iphone";
            if(device.user !== null){
                ClearBlade.loginUser(userEmail, userPass, function(err, body) {
                    if(err) {
                        // User DNE.. generate user
                        log("ERR! Device has specified user but user \""+device.user+"\" DNE");
                        resp.error("User login failure: " + JSON.stringify(body));
                    } else {
                        log("Device user \""+device.user+"\" logged in sucessfully");
                        finishHandshake(userEmail);
                    }
                });
            } else {
                // User is null.. generate new user
                ClearBlade.registerUser(userEmail, userPass, function(err, body) {
                    if(err) {
                        log("ERR! failed user registration");
                        resp.error("Register user failure: " + JSON.stringify(body));
                    } else {
                        log("New user registered");
                        log(JSON.stringify(body));
                        // Update the device
                        var changes = {
                            "user" : body.userid
                        };
                        
                        ClearBlade.updateDevice(device.name, changes, true, function(err, data) {
                            if(err){
                                resp.error("Unable to update device: " + JSON.stringify(data));
                            }
                            finishHandshake(userEmail);
                        });
                    }
                });
            }
    };
    
    var lookupDevice = function(deviceKey){
        ClearBlade.getDeviceByName(deviceKey, function(err, data) {
            if(err){
                log(deviceKey+" DNE, creating new device");
                // Device DNE, create new device and new user
                var newDevice = {
                    "name"     : deviceKey,
                    "type"     : "iphone",
                    "state"    : "connected",
                    "enabled"  : true,
                    "allow_key_auth": true,
                    "allow_certificate_auth": true,
                    "altitude" : null,
                    "positon"  : null,
                    "location" : null,
                    "user"     : null
                };
                ClearBlade.createDevice(deviceKey, newDevice, true, function(err, data) {
                    if(err){
                        log("ERR! creating device-> "+deviceKey);
                        resp.error("Unable to create device: " + JSON.stringify(data));
                    }
                    log("Device "+deviceKey+" created");
                    lookupDeviceUser(data);
                });
            }
            else{
                // Device exists.. extract and login relevant user
                log("Device "+deviceKey+" exists");
                lookupDeviceUser(data);
            }
        });
    };
    
    
    
    // Lookup device
    
    // If no device. add device and new user
    
    // login user and return user token
    
    // Validate Request
    if(req.params.device === undefined || !req.params.device.length)
        resp.error("Device key is required");
    
    // Init an anon user to lookup device/user
    ClearBlade.init({
        systemKey: req.systemKey,
        systemSecret: req.systemSecret,
        callback: function(err, body) {
            if(err) {
                resp.error("CB init failed");
            } else {
                lookupDevice(req.params.device);
            }
        }
    });
}