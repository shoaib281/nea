import socket
import threading
import time
import random
from launch import gameLauncher

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
        self.listeningBroadcastSocket.bind(("0.0.0.0", self.broadcastPort))
        
        self.listeningInviteSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.listeningPort = self.findNearestPort(9342)
        self.listeningInviteSocket.listen()

        self.myIp = socket.gethostbyname(socket.gethostname())

        self.window.launcher = gameLauncher(self.myIp, self.listeningPort + 10, self.window)

        print(self.myIp, self.listeningPort)

        self.killDetection = 5
        

        self.playerDict = {}

    def findNearestPort(self,basePort):
        port = basePort

        while True:
            works = True
            try:
                self.listeningInviteSocket.bind((socket.gethostname()+".local", port))
            except:
                works = False
            if works:
                print("done", port)
                return port

            port = port + 1
        
    #broadcasts itself and kills inactive players from UI
    def selfBroadcast(self):
        threading.Timer(self.broadcastTime, self.selfBroadcast,[]).start()
        self.checkKill()

        self.broadcastSocket.sendto(bytes(self.username + ":" + str(self.listeningPort),"utf-8"),("<broadcast>",self.broadcastPort))

    #listens for invite responses
    def listeningAcceptReject(self, index, frame):
        sock = self.playerDict[index]["socketObject"]
        response = sock.recv(1024).decode("utf-8")
        print("Received a response: ", response, " from: ", index)

        frame.addInviteButton()


        if response == "Accept" and not self.window.inGame:

            self.window.launcher.startGame(self.playerDict[index]["address"], self.playerDict[index]["listeningPort"] + 10)


        sock.close()
        self.playerDict[index]["socketObject"] = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    #listens for invites
    def listeningLoop(self): #server, broadcast
        while True:
            clientSocket, address = self.listeningInviteSocket.accept()
            address, port = address

            targetPlayer = False

            for key,player in self.playerDict.items():
                if address == player["address"] and player["username"] != self.username:
                    targetPlayer = key
                    break

            if targetPlayer:
                for frame in self.window.frames:
                    if targetPlayer == frame.player["index"]:
                        frame.addAcceptReject()
                        frame.connection = clientSocket 
                        frame.index = targetPlayer
                        break

    #deletes items that haven't received a broadcast in a while, polayer probably exited
    def checkKill(self):
        for player in list(self.playerDict):
            playerTime = self.playerDict[player]["lastUpdate"]
            
            if int(time.time()) - playerTime > self.killDetection:
                for frame in self.window.frames:
                        if player == frame.player["index"]:

                            frame.destroyFrame()
                            del self.playerDict[player]
                            break

    #handles received broadcasts
    def newDataToDict(self, data):

        username, address = data
        username = username.decode("utf-8")

        username, listeningPort = username.split(":")
        listeningPort = int(listeningPort)
        ip, port = address

        player = username + ":"  + ip

        if not player in self.playerDict:

            playerSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

            self.playerDict[player] = {
                "index": player,
                "address":  ip,
                "username": username,
                "listeningPort": listeningPort,
                "status": "active",
                "socketObject": playerSocket,
                "lastUpdate": int(time.time())
            } 

            self.window.addUser(self.window, player)
        else:
            self.playerDict[player]["lastUpdate"] = int(time.time())
        
    #listens for broadcasts
    def broadcastListeningLoop(self):
        while True:
            self.newDataToDict(self.listeningBroadcastSocket.recvfrom(1024))
