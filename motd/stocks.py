#!/usr/bin/env python3
"""FlowerOS MOTD - Stocks/Crypto Template"""
import urllib.request,json,sys,os
from datetime import datetime

R='\033[0m';B='\033[1m';D='\033[2m';C='\033[96m';G='\033[92m';Y='\033[93m'
RED='\033[91m';M='\033[95m';BL='\033[94m'

DEFAULTS=['AAPL','MSFT','GOOGL','BTC-USD','ETH-USD']

def stock(sym):
    try:
        url=f"https://query1.finance.yahoo.com/v8/finance/chart/{sym}"
        req=urllib.request.Request(url,headers={'User-Agent':'FlowerOS/1.0'})
        data=json.loads(urllib.request.urlopen(req,timeout=5).read().decode())
        if 'chart' in data and 'result' in data['chart']:
            meta=data['chart']['result'][0]['meta']
            price=meta.get('regularMarketPrice',0)
            prev=meta.get('previousClose',price)
            chg=price-prev;pct=(chg/prev*100)if prev>0 else 0
            return{'sym':sym,'name':meta.get('longName',sym),'price':price,'chg':chg,'pct':pct,'cur':meta.get('currency','USD')}
        return{'error':f'No data for {sym}'}
    except Exception as e:
        return{'error':str(e)}

def price(p,cur='USD'):
    if p>=1000:return f"{cur} {p:,.2f}"
    elif p>=1:return f"{cur} {p:.2f}"
    else:return f"{cur} {p:.4f}"

def change(c,p):
    if c>0:col,sig=G,'▲'
    elif c<0:col,sig=RED,'▼'
    else:col,sig=Y,'▬'
    return f"{col}{sig} {abs(c):.2f} ({abs(p):.2f}%){R}"

def load_syms():
    cfg=os.path.expanduser('~/.config/floweros/stocks.conf')
    if os.path.exists(cfg):
        try:
            syms=[l.strip().upper()for l in open(cfg)if l.strip()and not l.startswith('#')]
            return syms if syms else DEFAULTS
        except:pass
    return DEFAULTS

if len(sys.argv)>1:
    if sys.argv[1]=='add':
        syms=load_syms()+[s.upper()for s in sys.argv[2:]]
        os.makedirs(os.path.expanduser('~/.config/floweros'),exist_ok=True)
        with open(os.path.expanduser('~/.config/floweros/stocks.conf'),'w')as f:
            f.write("# FlowerOS Stocks\n")
            for s in syms:f.write(f"{s}\n")
        print(f"{G}✓ Added: {', '.join(sys.argv[2:])}{R}");sys.exit()
    elif sys.argv[1]=='list':
        print(f"{B}Watchlist:{R}")
        for s in load_syms():print(f"  • {s}")
        sys.exit()
    else:syms=[s.upper()for s in sys.argv[1:]]
else:syms=load_syms()

print(f"\n{B}{C}╔═══════════════════════════════════════════════════════════╗{R}")
print(f"{B}{C}║{R}  {B}🌸 FlowerOS Market Watch{R}                           {B}{C}║{R}")
print(f"{B}{C}╚═══════════════════════════════════════════════════════════╝{R}\n")
print(f"  {B}{BL}Updated:{R} {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

for sym in syms:
    d=stock(sym)
    if 'error' in d:print(f"  {RED}✗ {sym}: {d['error']}{R}");continue
    name=d['name'][:30]
    print(f"  {B}{M}{sym}{R} {D}({name}){R}")
    print(f"  {B}{price(d['price'],d['cur'])}{R}  {change(d['chg'],d['pct'])}\n")

print(f"{D}  motd-stocks add TSLA  # Add symbol{R}")
print(f"{D}  motd-stocks list      # Show watchlist{R}\n")
