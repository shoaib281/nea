local socket = require("socket")

local module = {}

function module:init(myIp, myPort, plrIp, plrPort)
    self.myIp = myIp
    self.myPort = tonumber(myPort)
    self.plrIp = plrIp
    self.plrPort = tonumber(plrPort)

    self.listeningSocket = socket.bind("*", self.myPort) -- self.myIp
    self.listeningSocket:settimeout(0)
    self.client = self.listeningSocket:accept()

    if self.client then
        self.client:settimeout(0)
    end

    self.talkSocket = socket.tcp()
    self.talkSocket:connect(self.plrIp, self.plrPort)
end

function module:listen()
    if self.client then
        local line, error, partial = self.client:receive()
        if line then
            return line
        end
    end
end

function module:send(message)
    --self.talkSocket:connect(self.plrIp, self.plrPort)
    self.talkSocket:send(message.."\n")
end

return module