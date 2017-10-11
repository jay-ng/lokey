var pullState = function(creds, resp){
    log("Pulling State for user:");
    var state = {};
    var seed = Seed.standard;
    state = seed;
    state.user.creds = creds;
    state.user.username = "";
    log("State generated: ");
    log(JSON.stringify(state));
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
	    log("Sync changes for user : ");
	    log(JSON.stringify(data));
	    log("changes: ");
	    
	    
	    log(JSON.stringify(req.params.changes));
	    resp.success("Changes succesfully synced");
	});
};

var pushState = function(state, resp){

};