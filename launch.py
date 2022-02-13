import os, subprocess
import time
import threading
import psutil

class gameLauncher():
    def __init__(self, myIp, myPort, window):
        currentDir = os.getcwd()
        os.chdir(currentDir + "\Game")

        self.myIp = str(myIp)
        self.myPort = str(myPort)
        self.window = window

    def startGame(self, plrIp, plrPort):

        self.window.inGame = True

        print("okay, launched...")
        #launches game
        process = subprocess.Popen(["lv\love.exe", "Program", self.myIp, self.myPort, plrIp, str(plrPort)])
        self.pid = process.pid #gets code of file launched

        threading.Thread(target=self.processCheckLoop).start()

    #keeps checking if file launched stil exists
    def processCheckLoop(self):
        while True:
            time.sleep(1)
            
            if not psutil.pid_exists(self.pid):
                self.window.inGame = False #informs game it doesnt
                break        