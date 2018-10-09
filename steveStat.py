#!/usr/bin/python3

# sudo ufw allow 8912

import cherrypy
import json

def openConfig(filename):
    try:
        return open(filename).read().replace('\n', '')
    except FileNotFoundError:
        return ''

writePassword = openConfig('config/passwordWrite')
readPassword = openConfig('config/passwordRead')
storedData = {}

class Datum():
    def __init__(self, ip, port, name):
        self.ip = ip
        self.port = port
        self.name = name

    def asDict(self):
        return {
            'ip':   self.ip,
            'port': self.port,
            'name': self.name
        }

    def asJSON(self):
        return json.JSONEncoder().encode(self.asDict())

class MainApp(object):
    def __init__(self):
        pass

    @cherrypy.expose
    def index(self, password='', update=False, ip=None, port=None, name=''):
        if password == writePassword:
            if update:
                global storedData
                storedData[name] = Datum(ip, port, name)
                print(storedData)
        if password == readPassword:
            return storedData[name].asJSON()
        print('Wrong password:', repr(password), '!=', repr(writePassword))

    @cherrypy.expose
    def test(self):
        return 'DEBUG TEST'

if __name__ == '__main__':
    conf = {'/': {'tools.sessions.on': True}}
    cherrypy.config.update({'server.socket_port': 8912})
    cherrypy.server.socket_host = '0.0.0.0' # Expose publically
    cherrypy.quickstart(MainApp(), '/', conf)
