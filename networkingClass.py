import socket
import threading
import time

class networkingClass():
    def __init__(self, username, window):

        self.username = username
        self.window = window
        self.broadcastSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.broadcastSocket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST,1)
        self.broadcastTime = 1
        self.broadcastPort = 8734

        self.listeningBroadcastSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.listeningBroadcastSocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, socket.SO_BROADCAST)
        self.listeningBroadcastSocket.bind(("", self.broadcastPort))
        

        self.playerDict = {}

        self.timeToKill = 50
        
    def selfBroadcast(self):
        threading.Timer(self.broadcastTime, self.selfBroadcast,[]).start()
        
        self.broadcastSocket.sendto(bytes(self.username,"utf-8"),("<broadcast>",self.broadcastPort))

    def checkKill(self, player):
        playerTime = self.playerDict[player].time
        if int(time.time()) < playerTime + self.timeToKill:
            print("player should be dead")


    def newDataToDict(self, data):
        username, address = data
        username = username.decode("utf-8")
        ip, port = address

        print(username, ip, port)

        player = username + ":"  + ip
        if not player in self.playerDict:

            playerSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            #playerSocket.connect((ip, self.invitePort))


            self.playerDict[player] = {
                "address":  ip,
                "username": username,
                "port": port,
                "status": "active",
                "invitedMe": False,
                "socketObject": playerSocket,
                "invitedByMe": False,
                "timeInvited": int(time.time())
            } 

            self.window.addUser(self.window, player)
        

    def loop(self):
        while True:
            self.newDataToDict(self.listeningBroadcastSocket.recvfrom(1024))
            
            
            

            

        


