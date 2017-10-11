function pulse(req, resp){
    ClearBlade.init({request: req});
    var online = true;
    if(req.params.online !== undefined)
        online = req.params.online;
    var newEvent = {
        event_type: "status",
        entity_type: "user",
        entity_id: req.userEmail,
        data: JSON.stringify({"online": online}),
        timestamp : getUTCTimestamp()
    };
    log(JSON.stringify(newEvent));
    var eventInsertCallback = function (err, data) {
        if (err) {
        	resp.error("insert error : " + JSON.stringify(data));
        } else {
        	resp.success(data);
        }
    };
    var col = ClearBlade.Collection( {collectionName: Collection.event } );
    col.create(newEvent,eventInsertCallback);
    //this inserts the the newPerson item into the collection that col represents
    resp.success("Lifesign recieved");
}