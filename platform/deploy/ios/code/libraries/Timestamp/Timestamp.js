function fmtDigits(d) {
    if(0 <= d && d < 10) return "0" + d.toString();
    if(-10 < d && d < 0) return "-0" + (-1*d).toString();
    return d.toString();
}

var getUTCTimestamp = function(){ 
    var now = new Date();
    return now.getUTCFullYear() + "-" + fmtDigits(1 + now.getUTCMonth()) + "-" + fmtDigits(now.getUTCDate()) + " " + fmtDigits(now.getUTCHours()) + ":" + fmtDigits(now.getUTCMinutes()) + ":" + fmtDigits(now.getUTCSeconds());
};