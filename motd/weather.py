#!/usr/bin/env python3
"""FlowerOS MOTD - Weather Template"""
import urllib.request,json,sys
from datetime import datetime

R='\033[0m';B='\033[1m';D='\033[2m';C='\033[96m';G='\033[92m';Y='\033[93m'
RED='\033[91m';M='\033[95m';BL='\033[94m'

ICONS={'Clear':'☀️','Sunny':'☀️','Partly cloudy':'⛅','Cloudy':'☁️','Overcast':'☁️',
       'Mist':'🌫️','Fog':'🌫️','Light rain':'🌦️','Rain':'🌧️','Heavy rain':'⛈️',
       'Thunderstorm':'⛈️','Snow':'❄️','Light snow':'🌨️','Sleet':'🌨️'}

def icon(c):
    for k,v in ICONS.items():
        if k.lower() in c.lower():return v
    return'🌡️'

def temp(t):
    t=int(t)
    c=BL if t<0 else C if t<10 else G if t<20 else Y if t<30 else RED
    return f"{c}{t}°C{R}"

def wind(s,d):
    arrows={'N':'↓','NE':'↙','E':'←','SE':'↖','S':'↑','SW':'↗','W':'→','NW':'↘'}
    return f"{arrows.get(d,'•')} {int(s)} km/h {d}"

loc=sys.argv[1]if len(sys.argv)>1 else""
try:
    url=f"https://wttr.in/{loc}?format=j1"if loc else"https://wttr.in/?format=j1"
    req=urllib.request.Request(url,headers={'User-Agent':'FlowerOS/1.0'})
    data=json.loads(urllib.request.urlopen(req,timeout=5).read().decode())
    
    cur=data['current_condition'][0]
    area=data['nearest_area'][0]
    fc=data['weather'][:3]
    
    print(f"\n{B}{C}╔═══════════════════════════════════════════════════════════╗{R}")
    print(f"{B}{C}║{R}  {B}🌸 FlowerOS Weather Report{R}                         {B}{C}║{R}")
    print(f"{B}{C}╚═══════════════════════════════════════════════════════════╝{R}\n")
    
    aname=area.get('areaName',[{}])[0].get('value','Unknown')
    country=area.get('country',[{}])[0].get('value','')
    print(f"  {B}{BL}Location:{R} {aname}, {country}")
    print(f"  {B}{BL}Updated:{R} {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
    
    cond=cur['weatherDesc'][0]['value']
    print(f"  {B}{M}Current:{R} {icon(cond)} {cond}")
    print(f"  {B}{M}Temperature:{R} {temp(cur['temp_C'])} (feels {temp(cur['FeelsLikeC'])})")
    print(f"  {B}{M}Humidity:{R} {cur['humidity']}% | {B}Pressure:{R} {cur['pressure']} hPa")
    print(f"  {B}{M}Wind:{R} {wind(cur['windspeedKmph'],cur['winddir16Point'])}\n")
    
    print(f"  {B}{Y}3-Day Forecast:{R}\n")
    for day in fc:
        dt=datetime.strptime(day['date'],'%Y-%m-%d').strftime('%a, %b %d')
        mx,mn=day['maxtempC'],day['mintempC']
        cd=day['hourly'][4]['weatherDesc'][0]['value']
        print(f"  {B}{dt}:{R}")
        print(f"    {icon(cd)} {cd}")
        print(f"    ↑ {temp(mx)} / ↓ {temp(mn)}\n")
        
except Exception as e:
    print(f"\n{RED}✗ Weather unavailable: {e}{R}\n")
