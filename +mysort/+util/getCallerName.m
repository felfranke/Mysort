function caller_name = getCallerName()
    caller_name = '';
    dbs = dbstack;
    if ~isempty(dbs)
        try
            caller_name = [dbs(3).name '() in ' dbs(3).file ' Line: '  num2str(dbs(3).line)];
        catch
            caller_name = 'unknown (shell?)';
        end
    end