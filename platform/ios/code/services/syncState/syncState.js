function syncState(req, resp){
    log("Yo");
    log(JSON.stringify(req));
    if(req.params.method === undefined)
        resp.error("sync method missing");
    

    switch(req.params.method){
        case "pull": 
            log("State Pull");
            pullState();
            break;
        case "sync": 
            log("State Sync");
            syncChanges(req,resp);
            break;
        case "push":
            log("State Push");
            break;
        default: 
            resp.error("invalid state method");
            break;
    }

}