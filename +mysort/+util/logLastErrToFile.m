
function logLastErrToFile(filename)
    errStr = mysort.util.buildLastErrString();
    mysort.util.logToFile(filename, mysort.util.escapeString(errStr));