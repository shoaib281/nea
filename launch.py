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
        self.isLinux = platform.system() == "Linux"

        os.chdir(
                os.path.dirname(__file__)
            )

    def startGame(self, plrIp, plrPort):

        self.window.inGame = True

        print("okay, launched...")
        print(os.getcwd())
        #launches game
        if self.isLinux:
            process = subprocess.Popen(["love Game/Program " +  self.myIp + " " + str(self.myPort) + " " + plrIp + " " + str(plrPort)],shell=True)
        else:
            process = subprocess.Popen(["Game\lv\love.exe", "Game\Program",  self.myIp, str(self.myPort), plrIp, str(plrPort)])
        self.pid = process.pid
        self.process = psutil.Process(pid=self.pid)

        threading.Thread(target=self.processCheckLoop).start()

    #keeps checking if file launched stil exists
    def processCheckLoop(self):
        while True:
            time.sleep(1)
            if self.isLinux:
                if self.process.status() == "terminated" or self.process.status() == "zombie":
                    print("No longer in game")
                    self.window.inGame = False #informs game it doesnt
                    break        
            if not self.isLinux:
                if not psutil.pid_exists(self.pid):
                    self.window.inGame = False
                    break
