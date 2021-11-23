import os, subprocess
gameMode = True


def startGame():
    currentDir = os.getcwd()
    os.chdir(currentDir + "\Game")
    subprocess.Popen(["lv\love.exe", "Program"])

if __name__ == "__main__":
    startGame()
    input()