 """
 Author  - pyCity
 Date    - 1st Febuary 2019
 Version - 1.0
 
 Usage:         python gbot.py <keywords>
 
 Description:   Google a keyword and open the top 5 results
                on separate tabs in the web browser
 """
 
 import webbrowser
 import requests
 import bs4
 import sys
 
 
 def main():
     if len(sys.argv) > 1:
         keyword = " ".join(sys.argv[1:])
     else:
         print("Usage: python gbot.py python reverse tcp")
         sys.exit()
 
     result = requests.get("http://google.com/search?q=" + keyword)
     result.raise_for_status()
 
     soup = bs4.BeautifulSoup(result.text)
     links = soup.select(".r a")
 
     # Change this if you would like to open more than 5 tabs
     numTabs = min(5, len(links))
 
     for i in range(numTabs):
         webbrowser.open("http://google.com" + links[i].get("href"))
 
 main()
