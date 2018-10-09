#!/usr/bin/python3

# sudo ufw allow 8912

import cherrypy

def openConfig(filename):
    try:
        return open(filename).read().replace('\n', '')
    except FileNotFoundError:
        return ''

writePassword = openConfig('config/passwordWrite')
readPassword = openConfig('config/passwordRead')
storedIP = ''

class MainApp(object):
    def __init__(self):
        pass

    @cherrypy.expose
    def index(self, password='', update=False, ip=None):
        if password == writePassword:
            if update:
                global storedIP
                storedIP = ip
        if password == readPassword:
            return storedIP
        print(password, writePassword)

    @cherrypy.expose
    def test(self):
        return 'DEBUG TEST'

if __name__ == '__main__':
    conf = {'/': {'tools.sessions.on': True}}
    cherrypy.config.update({'server.socket_port': 8912})
    cherrypy.server.socket_host = '0.0.0.0' # Expose publically
    cherrypy.quickstart(MainApp(), '/', conf)
