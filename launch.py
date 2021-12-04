import os, subprocess
gameMode = True


def startGame(myIp, myPort, plrIp, plrPort):
    currentDir = os.getcwd()
    os.chdir(currentDir + "\Game")
    subprocess.Popen(["lv\love.exe", "Program", myIp, str(myPort), plrIp, str(plrPort)])

if __name__ == "__main__":
    startGame("192.168.0.26", "9432", "192.168.0.26", "9532")
    input()