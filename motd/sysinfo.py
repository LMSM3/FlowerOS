#!/usr/bin/env python3
"""
FlowerOS MOTD - System Information Template
Displays CPU, GPU, Memory, Disk stats with beautiful formatting
"""
import os, sys, subprocess, platform
from datetime import datetime

# ANSI Colors
R='\033[0m';B='\033[1m';D='\033[2m';C='\033[96m';G='\033[92m';Y='\033[93m'
RED='\033[91m';M='\033[95m';BL='\033[94m'

def cpu_info():
    try:
        model="Unknown";load=os.getloadavg();cores=os.cpu_count() or 1
        if os.path.exists('/proc/cpuinfo'):
            for line in open('/proc/cpuinfo'):
                if 'model name' in line:model=line.split(':')[1].strip()[:50];break
        pct=min((load[0]/cores)*100,100)
        return{'model':model,'cores':cores,'load':load,'pct':pct}
    except:return{}

def gpu_info():
    try:
        result=subprocess.run(['nvidia-smi','--query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total','--format=csv,noheader,nounits'],capture_output=True,text=True,timeout=2)
        if result.returncode==0:
            parts=[p.strip() for p in result.stdout.strip().split(',')]
            if len(parts)>=5:return{'name':parts[0],'temp':parts[1],'util':parts[2],'mem_used':parts[3],'mem_total':parts[4]}
    except:pass
    return None

def mem_info():
    try:
        info={}
        for line in open('/proc/meminfo'):
            parts=line.split(':')
            if len(parts)==2:info[parts[0].strip()]=int(parts[1].strip().split()[0])
        total=info.get('MemTotal',0)/1024/1024
        avail=info.get('MemAvailable',0)/1024/1024
        used=total-avail;pct=(used/total*100)if total>0 else 0
        return{'total':total,'used':used,'avail':avail,'pct':pct}
    except:return{}

def disk_info():
    try:
        s=os.statvfs('/');total=(s.f_blocks*s.f_frsize)/(1024**3)
        free=(s.f_bavail*s.f_frsize)/(1024**3);used=total-free
        pct=(used/total*100)if total>0 else 0
        return{'total':total,'used':used,'free':free,'pct':pct}
    except:return{}

def uptime():
    try:
        secs=float(open('/proc/uptime').readline().split()[0])
        d=int(secs//86400);h=int((secs%86400)//3600);m=int((secs%3600)//60)
        if d>0:return f"{d}d {h}h {m}m"
        elif h>0:return f"{h}h {m}m"
        else:return f"{m}m"
    except:return"Unknown"

def bar(pct,w=20):
    filled=int(w*pct/100);b='█'*filled+'░'*(w-filled)
    c=G if pct<50 else Y if pct<80 else RED
    return f"{c}{b}{R}"

# Main Display
print(f"\n{B}{C}╔═══════════════════════════════════════════════════════════╗{R}")
print(f"{B}{C}║{R}  {B}🌸 FlowerOS System Information{R}                      {B}{C}║{R}")
print(f"{B}{C}╚═══════════════════════════════════════════════════════════╝{R}\n")

print(f"  {B}{BL}System:{R} {platform.node()}")
print(f"  {B}{BL}Uptime:{R} {uptime()}")
print(f"  {B}{BL}Time:{R}   {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

cpu=cpu_info()
if cpu:
    print(f"  {B}{M}CPU:{R} {cpu['model']}")
    print(f"  {B}{M}Cores:{R} {cpu['cores']} | {B}Load:{R} {cpu['load'][0]:.2f} {cpu['load'][1]:.2f} {cpu['load'][2]:.2f}")
    print(f"  {bar(cpu['pct'])} {cpu['pct']:.1f}%\n")

gpu=gpu_info()
if gpu:
    print(f"  {B}{G}GPU:{R} {gpu['name']}")
    print(f"  {B}{G}Usage:{R} {gpu['util']}% | {B}Temp:{R} {gpu['temp']}°C | {B}VRAM:{R} {gpu['mem_used']}/{gpu['mem_total']} MB\n")

mem=mem_info()
if mem:
    print(f"  {B}{Y}Memory:{R} {mem['used']:.1f} GB / {mem['total']:.1f} GB")
    print(f"  {bar(mem['pct'])} {mem['pct']:.1f}%\n")

disk=disk_info()
if disk:
    print(f"  {B}{C}Disk:{R} {disk['used']:.1f} GB / {disk['total']:.1f} GB")
    print(f"  {bar(disk['pct'])} {disk['pct']:.1f}%\n")
