import tkinter
import tkinter.font

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
                print("You've hit enter! " + chosenUsername)
                window.unbind("<Return>")
                #moveToMainWindow(chosenUsername)


window.bind("<Button-1>",onClickWindow)
window.bind("<Return>",validateUsername)

window.mainloop()
