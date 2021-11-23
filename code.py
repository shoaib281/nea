import tkinter
from tkinter.constants import N, NW
import tkinter.font
import networkingClass
import threading
import launch

window = tkinter.Tk()
width, height = 700, 400
window.update_idletasks()
screenWidth, screenHeight = window.winfo_screenwidth(), window.winfo_screenheight()
x,y = int(screenWidth/2 - width/2), int(screenHeight/2-height/2 - 100)
window.geometry(f"{width}x{height}+{x}+{y}")

placeHolderText = "Enter Username:"
textBoxWidth = 32
textBoxFont = tkinter.font.Font(size=14)
textBox = tkinter.Entry(window,  width = textBoxWidth, font = textBoxFont, justify="center")
textBox.insert(0,placeHolderText)
textBox.place(relx = 0.5, rely = 0.25, anchor="center")

def onClickWindow(arg):
    arg.widget.focus_set()
    if window.focus_get().winfo_class() == "Entry" and textBox.get() == placeHolderText:
        textBox.delete(0,"end")

def validateUsername(args):
    if window.focus_get().winfo_class() == "Entry":
        chosenUsername = textBox.get()
        if len(chosenUsername) > 1:
            if chosenUsername.isalpha():
                textBox.destroy()
                window.title(chosenUsername)
                window.unbind("<Return>")

                print(chosenUsername)
                
                window.frames = []
                window.networking = networkingClass.networkingClass(chosenUsername, window)
                window.networking.selfBroadcast()
                threading.Thread(target=window.networking.loop).start()
                threading.Thread(target=window.networking.listeningLoop).start()

def addUser(self,index):
    frame = tkinter.Frame(window,width=width, height=30)
    
    frame.pack(fill="x", side="top")

    player = self.networking.playerDict[index]

    plrFrame = playerFrame(frame, self.frames, player, window)
    plrFrame.addInviteButton()

    self.frames.append(plrFrame)

class playerFrame():
    def __init__(self,frame, frames, player, window):
        self.frame = frame
        self.frames = frames
        self.player = player
        self.window = window

        self.label = tkinter.Label(self.frame,text = self.player["username"] + ":" + player["status"], font = textBoxFont)
        self.label.place(relx = 0.5, anchor=N)

    def removeInviteButton(self):
        if self.inviteButton:
            self.inviteButton.place_forget()

    def addInviteButton(self):
        self.inviteButton = tkinter.Button(self.frame, text="Invite", command=self.inviteCommand)
        self.inviteButton.place(relx=0, anchor=NW)


    def inviteCommand(self): #client        
        self.player["socketObject"].connect((self.player["address"], self.player["listeningPort"]))
        threading.Thread(target=self.window.networking.listeningAcceptReject, args=(self.player["index"],self)).start()
        self.removeInviteButton()

    def addAcceptReject(self): #server
        difference=25
        self.acceptButton = tkinter.Button(self.frame, text="Accept", command=self.acceptInvite)
        self.acceptButton.place(relx=0.9,x=-difference, anchor=N)

        self.rejectButton = tkinter.Button(self.frame, text="Reject", command=self.rejectInvite)
        self.rejectButton.place(relx=0.9,x = difference, anchor=N)

        self.removeInviteButton()

    def removeAcceptReject(self): 
        if hasattr(self, "acceptButton"):
            self.acceptButton.pack_forget()
            self.acceptButton.destroy()

            self.rejectButton.pack_forget()
            self.rejectButton.destroy()

    def rejectInvite(self): #server
        connection = self.connection
        connection.send(bytes("Reject", "utf-8"))
        self.removeAcceptReject()
        self.addInviteButton()
        self.connection = False

    def clearEverything(self):
        for frame in self.frames:
                    frame.removeAcceptReject()
                    frame.removeInviteButton()

    def acceptInvite(self): #server
        connection = self.connection
        connection.send(bytes("Accept","utf-8"))
        self.connection = False
        self.clearEverything()

        launch.startGame()

    def destroyFrame(self):
        self.frame.pack_forget()
        self.frame.destroy()

window.addUser = addUser
window.bind("<Button-1>",onClickWindow)
window.bind("<Return>",validateUsername)

window.mainloop()