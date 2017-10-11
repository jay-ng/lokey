var pullState = function(creds, resp){
    
    ClearBlade.init({
        systemKey: CREDS.SYSTEM.KEY,
        systemSecret: CREDS.SYSTEM.SECRET,
        useUser: creds
    });

    
    log("Pulling State for user:");
    var state = {};
    var seed = Seed.standard;
    state = seed;
    state.user.creds = creds;
    state.user.username = "";
    log("State generated: ");
    log(JSON.stringify(state));
    
    var user = ClearBlade.User();
    user.getUser(function(err, data) {
        if(err)
            resp.error("Invalid credentials");
        log("set user info: "+ JSON.stringify(data));
        state.user.username = data.username;
    });
    
    resp.success(state);
    
    
    // Fetch user's device
    
    
    
    
    // Fetch user's locations
    
    // Fetch locations' building 
    
    // Determine nearby locations (if current user position is provided)
    
    // Fetch relevant connections
    
    // Fetch all related coordinates
    
    // TODO: Create user specific placeholder locations/connections/devices 
    
};






var syncChanges = function(req,resp){
    ClearBlade.init({request: req});
    
    var user = ClearBlade.User();
    user.getUser(function(err, data) {
        if(err)
            resp.error("Invalid credentials");
        
        var userUpdates = {}; // Object containing all changes to user object (Only a single user per request)
        
        // Parse through all changes and format for relevant insert/update
        for(var c in req.params.changes){
            var change = req.params.changes[c];
            
            // Identify user changes
            if(change.entityType === "user"){
                for(var attrKey in change.data){
                    userUpdates[attrKey] = change.data[attrKey];
                }
            }
            
        }
        
        
        if(Object.keys(userUpdates).length){
            log(JSON.stringify(userUpdates));
            user.setUser(userUpdates, function(err, result){
                
                if(err){
                    resp.error("ERR! updating user: " + JSON.stringify(result));
                }
                
                log("User updated");
                log(JSON.stringify(result));
            });
        }
        
        log("Events to sync: ");
        var eventAddCallback = function(err, body){
               if(err){log("ERR! Unable to insert event "+ JSON.stringify(body));}
               else{
                   log("successful event logged -> "+ JSON.stringify(body));
               }
           };
        
        // Parse through events, formatting and inserting into event collection
        if(req.params.events !== undefined){
           var eventCollection = ClearBlade.Collection( {collectionName: Collection.event } );
           var newEvent = {};
           
           for(var e in req.params.events){
               event = req.params.events[e];
               newEvent = {};
               // Event is a status
               if(event.type == "status"){
                   newEvent = {
                        event_type: event.type,
                        entity_type: event.entityType,
                        entity_id: event.id,
                        data: event.data,
                        timestamp : fmtUTCTimestamp(event.timestamp)
                    };
               }
               
               if(Object.keys(newEvent).length > 0)
                eventCollection.create(newEvent,eventAddCallback);
           }
        }
        resp.success("changes synced");
    });
};

var pushState = function(state, resp){

};