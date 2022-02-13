local socket = require("socket")

local module = {}

function module:init(myIp, myPort, plrIp, plrPort)
    self.myIp = myIp
    self.myPort = tonumber(myPort)
    self.plrIp = plrIp
    self.plrPort = tonumber(plrPort)

    self.listeningSocket = socket.bind("*", self.myPort) -- listen to port
    self.listeningSocket:settimeout(0)
    self.client = self.listeningSocket:accept()

    if self.client then
        self.client:settimeout(0)
    end

    self.talkSocket = socket.tcp()
    self.talkSocket:connect(self.plrIp, self.plrPort) --create tcp connection to enemyIP and port
end

function module:listen() -- try to listen to enemy
    if self.client then
        local line, error, partial = self.client:receive()
        if line then
            return line
        end
    end
end

function module:send(message) -- esnds enemy message to enemy
    self.talkSocket:send(message.."\n")
end

return module