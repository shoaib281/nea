import os, subprocess
import time
import threading
import psutil
import platform

class gameLauncher():
    def __init__(self, myIp, myPort, window):
        self.myIp = str(myIp)
        self.myPort = str(myPort)
        self.window = window

    def startGame(self, plrIp, plrPort):

        self.window.inGame = True

        print("okay, launched...")
        #launches game
        if platform.system() == "Linux":
            process = subprocess.Popen(["love Game/Program " +  self.myIp + " " + str(self.myPort) + " " + plrIp + " " + str(plrPort)],shell=True)
        else:
            process = subprocess.Popen(["Game/lv/love.exe Game/Program " +  self.myIp + " " + str(self.myPort) + " " + plrIp + " " + str(plrPort)],shell=True)
        self.process = psutil.Process(pid=process.pid)

        threading.Thread(target=self.processCheckLoop).start()

    #keeps checking if file launched stil exists
    def processCheckLoop(self):
        while True:
            time.sleep(1)
            print("checking if in game", self.process.status()) 
            if self.process.status() == "terminated" or self.process.status() == "zombie":
                print("No longer in game")
                self.window.inGame = False #informs game it doesnt
                break        
