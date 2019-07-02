#!/usr/bin/env python
# -*- coding:utf-8 -*-

import urllib2
import urllib
import json
import hashlib

'''
real pay four elements check card
'''


user_data = {
    'name': '张爽',
    'id_card': '4290041xxxxxxxx',
    'card_no': '6214830104xxxxxx',
    'phone': '18510258037'
}
url='https://api.9douyu.com/api/checkCard'
secret_key = 'xuN1mFEI3viLXMg7'

def createSign(user_data):

    sorted_data = sorted(user_data.items(),key=lambda item:item[0])
    str = ''
    for val in sorted_data:
        str += val[0] + '=' + val[1] + '&'
    str = str.rstrip('&')
    str += secret_key
    sign = hashlib.md5(str).hexdigest()
    return sign


def checkCard(user_data):

    req = urllib2.Request(url)
    data = urllib.urlencode(user_data)
    #enable cookie
    opener = urllib2.build_opener(urllib2.HTTPCookieProcessor())
    response = opener.open(req, data)
    return json.loads(response.read())


if __name__ == '__main__':
    print '--------jdy four elements check card--------'
    user_data['sign'] = createSign(user_data)
    print 'request data:'
    for key,value in user_data.iteritems():
        print "\t" + key + ' : ' + value

    print '--------------------------------------------'
    response = checkCard(user_data)

    print 'response data:'
    if response['status'] == True:
        msg = response['data']['msg']
    else:
        msg =  response['msg']

    print "\t msg : " + msg
