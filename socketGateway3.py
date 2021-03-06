#!/usr/bin/python
from websocket_server import WebsocketServer
import threading
import time
import json
import socket

threads = []
clients = {}

def client_left(client, server):
    msg = {'message':"client left"}
    try:
        clients.pop(client['id'])
    except:
        print ("Error in removing client %s" % client['id'])
    for cl in clients.values():
        server.send_message(cl, str(msg))
    #server.send_message(clients[1],str(clients))

def client_left1(client, server):
    msg = "Client (%s) left" % client['id']
    try:
        clients.pop(client['id'])
    except:
        print ("Error in removing client %s" % client['id'])
    #for cl in clients.values():
    msg={"command":"removeClient","socketID":client['id']}
    destination=getRoot()
    print ("destination is : "+str(destination))
    msg.update({'socketID':client['id']})
    for cl in clients:
        if cl == int(destination):
            cl = clients[cl]
            server.send_message(cl, str(msg).encode('utf-8'))


# new client i gonder servere
def new_client(client, server):
    msg = "New client (%s) connected" % client['id']
    msg=clients
    #for cl in clients.values():
        #server.send_message(cl, msg)
        #print "Bu da client type: "+str(type(cl))+", and client: "+str(cl)
    clients[client['id']] = client
    print ("Connect olanlar: "+str(clients))

def getRoot():
    result=''
    for i in clients:
        if clients[i]['address'][0]=='127.0.0.1':
            result=i
    #return int(result)
    return 1


def msg_received1(client, server, msg):
    #msg1 = "Client (%s) : %s" % (client['id'], msg)
    if msg != "":
        # add this to try except
        try:
            msg=json.loads(str(msg).encode('utf-8'))
            print ("Full Message >: "+str(msg))
            if client['id']==getRoot():
                destination=msg['destinationSocket']
                for cl in clients:
                    if cl == int(destination):
                        cl = clients[cl]
                        server.send_message(cl, str(msg).replace("u'","'").replace("'","\""))
            else:
                destination=getRoot()
                print ("destination is : "+str(destination))
                msg.update({'socketID':client['id']})
                for cl in clients:
                    if cl == int(destination):
                        cl = clients[cl]
                        server.send_message(cl, str(msg).encode('utf-8'))
        except Exception as desc:
            print ("Message format some problem: "+str(msg)+",  "+str(desc))


server = WebsocketServer(host='0.0.0.0',port=8001)
server.set_fn_client_left(client_left1)
server.set_fn_new_client(new_client)
server.set_fn_message_received(msg_received1)
server.run_forever()
