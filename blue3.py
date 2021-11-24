import socket, re
from uuid import getnode as get_mac
mac = str(hex(get_mac()))[2:]

mac  = re.findall("..", mac)
newmac = ""
for word in mac:
    newmac = newmac + word + ":"

newmac = newmac[:-1]
print(newmac)


port = 4  # Normal port for rfcomm?
buf_size = 1024

s = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
s.bind((newmac, port))
s.listen()

while True:
    print("adfas")
    client, address = s.accept()
    data = s.accept()
    print(data)

    if data:
        s.send(data)
        
