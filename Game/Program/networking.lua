local socket = require("socket")

local module = {}

function module:init(myIp, myPort, plrIp, plrPort)
    self.myIp = myIp
    self.myPort = tonumber(myPort)
    self.plrIp = plrIp
    self.plrPort = tonumber(plrPort)

	print(myIp, myPort, plrIp, plrPort)

    self.listeningSocket = socket.bind("*", self.myPort) -- self.myIp
    self.listeningSocket:settimeout(0)
    self.client = self.listeningSocket:accept()

	print("listening scoket name: ", self.listeningSocket:getsockname())

    if self.client then
        self.client:settimeout(0)
    end

    self.talkSocket = socket.tcp()
	self.talkSocketReady = self.talkSocket:connect(self.plrIp, self.plrPort)
end

function module:listen()
    if self.client then
        local line, error, partial = self.client:receive()
        if line then
			print("Received a message: ", line)
            return line
        end
    end
end

function module:send(message)
    --self.talkSocket:connect(self.plrIp, self.plrPort)
    self.talkSocket:send(message.."\n")
	print("sending", message)
	print("tcp soc name: ", self.talkSocket:getsockname())
	print("talkSocket: ", self.talkSocket:getpeername())
end

return module
