from os import truncate, utime
import socket
import threading
from tkinter.font import families

class networkingClass():
    def __init__(self, username, window):

        self.username = username
        self.window = window
        self.broadcastSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.broadcastSocket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST,1)
        self.broadcastTime = 1
        self.broadcastPort = 8734

        self.invitePort = 8735
        self.inviteSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.inviteSocket.bind(("", self.invitePort))
        self.inviteSocket.listen()

        self.listeningBroadcastSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.listeningBroadcastSocket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        self.listeningBroadcastSocket.bind(("", self.broadcastPort))

        self.playerDict = {}
        
    def selfBroadcast(self):
        threading.Timer(self.broadcastTime, self.selfBroadcast,[]).start()
        
        self.broadcastSocket.sendto(bytes(self.username,"utf-8"),("<broadcast>",self.broadcastPort))

    def newDataToDict(self, data):
        username, address = data
        username = username.decode("utf-8")
        ip, port = address

        print(username, ip, port)

        index = username + ":"  + ip

        

        if not index in self.playerDict:

            playerSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            playerSocket.connect((ip, self.invitePort))


            self.playerDict[index] = {
                "address":  ip,
                "username": username,
                "port": port,
                "status": "active",
                "invitedMe": False,
                "socketObject": playerSocket,
                "invitedByMe": False
            } 

            self.window.updateWindow(self,username)
        

    def loop(self):
        while True:
            self.newDataToDict(self.listeningBroadcastSocket.recvfrom(1024))
            
            
            

            

        


