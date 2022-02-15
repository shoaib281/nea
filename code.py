import tkinter
from tkinter.constants import N, NW
import tkinter.font
import networkingClass
import threading #multitasking
import launch

#creates window
window = tkinter.Tk()
window.title("Matchmaking")
width, height = 700, 400
window.update_idletasks()
screenWidth, screenHeight = window.winfo_screenwidth(), window.winfo_screenheight()
x,y = int(screenWidth/2 - width/2), int(screenHeight/2-height/2 - 100) 
window.geometry(f"{width}x{height}+{x}+{y}")

#creates textbox
placeHolderText = "Enter Username:"
textBoxWidth = 32
textBoxFont = tkinter.font.Font(size=14)
textBox = tkinter.Entry(window,  width = textBoxWidth, font = textBoxFont, justify="center") 
textBox.insert(0,placeHolderText)
textBox.place(relx = 0.5, rely = 0.25, anchor="center")

#widget clicked made active
def onClickWindow(arg): 
    arg.widget.focus_set()
    if window.focus_get().winfo_class() == "Entry" and textBox.get() == placeHolderText:
        textBox.delete(0,"end")

#validates usernamne
def validateUsername(args):
    if window.focus_get().winfo_class() == "Entry":
        chosenUsername = textBox.get()
        if len(chosenUsername) > 1:
            if chosenUsername.isalpha():
                textBox.destroy()
                window.unbind("<Return>")

                print(chosenUsername)
                
                window.frames = []
                window.networking = networkingClass.networkingClass(chosenUsername, window)
                window.networking.selfBroadcast()
                window.inGame = False
                threading.Thread(target=window.networking.broadcastListeningLoop).start()
                threading.Thread(target=window.networking.listeningLoop).start()

#add user to player list
def addUser(self,index):
    frame = tkinter.Frame(window,width=width, height=30)
    
    frame.pack(fill="x", side="top")

    player = self.networking.playerDict[index]

    plrFrame = playerFrame(frame, self.frames, player, window)
    if player["username"] != self.networking.username:
        plrFrame.addInviteButton()

    self.frames.append(plrFrame)

#class for each playerframe
class playerFrame():
    def __init__(self,frame, frames, player, window):
        self.frame = frame
        self.frames = frames
        self.player = player
        self.window = window

        self.label = tkinter.Label(self.frame,text = self.player["username"] + ":" + player["status"], font = textBoxFont)
        self.label.place(relx = 0.5, anchor=N)

    #removes invite button upon invite
    def removeInviteButton(self):
        if hasattr(self, "inviteButton"):
            self.inviteButton.place_forget()

    #receive invite resopnse, you can invite them again, adds invite button
    def addInviteButton(self):
        self.inviteButton = tkinter.Button(self.frame, text="Invite", command=self.inviteCommand)
        self.inviteButton.place(relx=0, anchor=NW)

    #invites a player over network and listens for response, removes invite button
    def inviteCommand(self): #client        
        self.player["socketObject"].connect((self.player["address"], self.player["listeningPort"]))
        threading.Thread(target=self.window.networking.listeningAcceptReject, args=(self.player["index"],self)).start()
        self.removeInviteButton()

    #if receive invite remove invite button add accept reject
    def addAcceptReject(self): #server
        difference=25
        self.acceptButton = tkinter.Button(self.frame, text="Accept", command=self.acceptInvite)
        self.acceptButton.place(relx=0.9,x=-difference, anchor=N)

        self.rejectButton = tkinter.Button(self.frame, text="Reject", command=self.rejectInvite)
        self.rejectButton.place(relx=0.9,x = difference, anchor=N)

        self.removeInviteButton()

    #removes accept reject, usually when invite accepted or rejected
    def removeAcceptReject(self): 
        if hasattr(self, "acceptButton"):
            self.acceptButton.pack_forget()
            self.acceptButton.destroy()

            self.rejectButton.pack_forget()
            self.rejectButton.destroy()

    #sends rejcet response removes accept reject adds invite back
    def rejectInvite(self): #server
        connection = self.connection
        connection.send(bytes("Reject", "utf-8"))
        self.removeAcceptReject()
        self.addInviteButton()
        self.connection = False

    #launches game when accept
    def acceptInvite(self): #server
        if not self.window.inGame:
            print("yo")

            connection = self.connection
            connection.send(bytes("Accept","utf-8"))
            connection.close()
            self.connection = False

            self.removeAcceptReject()
            self.addInviteButton()

            plrIndex = self.index
            
            self.window.launcher.startGame(self.window.networking.playerDict[plrIndex]["address"],self.window.networking.playerDict[plrIndex]["listeningPort"] + 10)

    #used if player leaves
    def destroyFrame(self):
        self.frame.pack_forget()
        self.frame.destroy()

window.addUser = addUser
window.bind("<Button-1>",onClickWindow)
window.bind("<Return>",validateUsername)

window.mainloop()