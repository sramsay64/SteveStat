#!/usr/bin/python3

# sudo ufw allow 8912

import cherrypy

writePassCode = 'icebound-snobby-shivery-dirties'
readPassCode = ''
storedIP = ''

class MainApp(object):
    def __init__(self):
        pass

    @cherrypy.expose
    def index(self, passcode='', update=False, ip=None):
        if passcode == writePassCode:
            if update:
                global storedIP
                storedIP = ip
        if passcode == readPassCode:
            return storedIP
        print(passcode, writePassCode)

    @cherrypy.expose
    def test(self):
        return 'DEBUG TEST'

if __name__ == '__main__':
    conf = {'/': {'tools.sessions.on': True}}
    cherrypy.config.update({'server.socket_port': 8912})
    cherrypy.server.socket_host = '0.0.0.0' # Expose publically
    cherrypy.quickstart(MainApp(), '/', conf)
