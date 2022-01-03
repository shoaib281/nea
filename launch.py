import os, subprocess
import time
import threading
import psutil

gameMode = True

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
        process = subprocess.Popen(["lv\love.exe", "Program", self.myIp, self.myPort, plrIp, str(plrPort)])
        self.pid = process.pid

        threading.Thread(target=self.processCheckLoop).start()

    def processCheckLoop(self):
        while True:
            time.sleep(1)
            
            if not psutil.pid_exists(self.pid):
                self.window.inGame = False
                print("yo")

                break        

if __name__ == "__main__":
    gl = gameLauncher()
    gl.startGame("192.168.0.26", "9432", "192.168.0.26", "9532")
    input()