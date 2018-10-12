#!/usr/bin/python3

# sudo ufw allow 8912

import cherrypy
import json
import time
import datetime

def openConfig(filename):
    try:
        return open(filename).read().replace('\n', '')
    except FileNotFoundError:
        return ''

writePassword = openConfig('config/passwordWrite')
readPassword = openConfig('config/passwordRead')
storedData = {}

def getTimeString(): # http://stackoverflow.com/questions/13890935/ddg#13891070
    return datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')

class Datum():
    def __init__(self, ip, port, name, user, status, network, comment):
        self.ip = ip
        self.port = port
        self.name = name
        self.user = user
        self.status = status
        self.network = network
        self.comment = comment
        self.timestamp = getTimeString()

    def asDict(self):
        return {
            'ip':   self.ip,
            'port': self.port,
            'name': self.name,
            'user': self.user,
            'status': self.status,
            'network': self.network,
            'comment': self.comment,
            'timestamp': self.timestamp
        }

    def asJSON(self):
        return json.JSONEncoder().encode(self.asDict())

class MainApp(object):
    def __init__(self):
        pass

    @cherrypy.expose
    def index(self, password='', update=False, ip=None, port=None, name='', user='', status='', network='', comment=''):
        if password == writePassword:
            if update:
                global storedData
                storedData[name] = Datum(ip, port, name, user, status, network, comment)
                print(storedData)
        if password == readPassword:
            if name in storedData:
                return storedData[name].asJSON()
            else:
                print('name', name, 'not in storedData')
        else:
            print('Wrong password:', repr(password), '!=', repr(writePassword))

    @cherrypy.expose
    def list(self, password=''):
        if password == readPassword:
            return json.JSONEncoder().encode([x for x in storedData.keys()])

    @cherrypy.expose
    def test(self):
        return 'DEBUG TEST'

if __name__ == '__main__':
    conf = {'/': {'tools.sessions.on': True}}
    cherrypy.config.update({'server.socket_port': 8912})
    cherrypy.server.socket_host = '0.0.0.0' # Expose publically
    cherrypy.quickstart(MainApp(), '/', conf)
