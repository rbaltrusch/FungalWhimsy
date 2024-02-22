ErrorUtil = {}

function ErrorUtil.call_or_exit(callable, enabled)
    if not enabled then
        return callable()
    end

    local success, err = pcall(callable)
    if not success then
        love.window.showMessageBox("A fatal error occured", err, "error", true)
        love.event.quit(1)
    end
end
