#!/usr/bin/env python
import time
import os
import webbrowser

"""Youtube bot that takes a url, refresh rate, and browser and views the URL 5 times"""

url = str(input("Enter the video url: "))
rate = input("Enter the refresh rate(seconds : ")
brow = input("Enter your default browser in ->\"browser here \"<-  : ")


# Give video 5 views
i = 0
while i < 5:
    os.system(" killall -9 " + brow)
    time.sleep(int(rate))
    webbrowser.open(url)
    print('Successfully Viewd')
    i += 1
