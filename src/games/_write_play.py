#!/usr/bin/env python3
"""Write play.c -- workaround for shell escaping issues."""
import os, textwrap

path = os.path.join(os.path.dirname(__file__), "play.c")

src = textwrap.dedent(r'''
// play.c - FlowerOS Game Launcher v0.2-beta (src/games/play.c)
// Active-window menu. Alt-screen, raw mode, arrow keys, fork+exec.
// Build: gcc -O2 -std=c11 -Wall -Wextra -o flower-play play.c

#define _POSIX_C_SOURCE 200809L
#include "fos_term.h"

typedef struct { const char *name,*binary,*desc,*icon,*ver; } GameReg;
#define NGAMES 3
static const GameReg G[NGAMES]={
 {"Chess","flower-chess","alpha-beta \xc2\xb7 num/sym/gui","\xe2\x99\x9b","v0.0.2"},
 {"Colony","flower-colony","hex survival \xc2\xb7 build","\xe2\x9a\x93","v0.0.1"},
 {"Tower Defense","flower-td","flowers vs creeps \xc2\xb7 15 stages","\xe2\x9c\xbf","v0.0.2"},
};
static const char FACE[]={'^','^','~','^'};
static const char *LEGS[]={"   / \\       ","  _/ \\       ","   / \\       ","   / \\_      "};
static const int GROW[]={1,4,7};

static void draw(int sel,int f){
 ft_go(1,1);
 printf(FT_MAG FT_BLD
  "  \xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
  "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
  "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
  "\xe2\x95\x90" FT_RST "\n");
 printf(FT_MAG FT_BLD "    \xe2\x9c\xbf  FlowerOS Games" FT_RST
  FT_DIM "  \xc2\xb7  v0.2-beta" FT_RST "\033[K\n");
 printf(FT_MAG FT_BLD
  "  \xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
  "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
  "\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90\xe2\x95\x90"
  "\xe2\x95\x90" FT_RST "\n");
 printf("\n");
 for(int r=0;r<10;r++){
  printf("  ");
  switch(r){
   case 0:printf(FT_MAG "    .~.      " FT_RST);break;
   case 1:printf(FT_MAG "  .(   ).    " FT_RST);break;
   case 2:printf(FT_MAG " (" FT_CYA " .~. " FT_MAG ")>   " FT_RST);break;
   case 3:printf(FT_MAG "  `-(  )-'   " FT_RST);break;
   case 4:printf(FT_MAG "    `-'      " FT_RST);break;
   case 5:printf(FT_DIM "    _|_      " FT_RST);break;
   case 6:printf(FT_DIM "  .(" FT_CYA "%c" FT_DIM ")." FT_MAG ">     " FT_RST,FACE[f]);break;
   case 7:printf(FT_DIM "   |=|       " FT_RST);break;
   case 8:printf(FT_DIM " %s" FT_RST,LEGS[f]);break;
   case 9:printf(FT_DIM "  o   o      " FT_RST);break;
  }
  int gi=-1,desc=0;
  for(int g=0;g<NGAMES;g++){
   if(GROW[g]==r){gi=g;break;}
   if(GROW[g]+1==r){gi=g;desc=1;break;}
  }
  if(gi>=0&&!desc){
   if(gi==sel) printf(FT_GRN FT_BLD "\xe2\x96\xb8 %s  %-15s %s" FT_RST,G[gi].icon,G[gi].name,G[gi].ver);
   else printf(FT_DIM "  %s  " FT_RST "%-15s " FT_DIM "%s" FT_RST,G[gi].icon,G[gi].name,G[gi].ver);
  } else if(gi>=0&&desc){
   if(gi==sel) printf(FT_GRN "     %s" FT_RST,G[gi].desc);
   else printf(FT_DIM "     %s" FT_RST,G[gi].desc);
  }
  printf("\033[K\n");
 }
 printf("\n");
 printf(FT_DIM
  "  \xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80"
  "\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80"
  "\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80"
  "\xe2\x94\x80" FT_RST "\n");
 printf("  " FT_YEL " \xe2\x86\x91\xe2\x86\x93" FT_DIM " Navigate   "
  FT_YEL "\xe2\x8f\x8e" FT_DIM " Play   "
  FT_YEL "1-3" FT_DIM " Quick   "
  FT_YEL "q" FT_DIM " Quit" FT_RST "\033[K\n");
 fflush(stdout);
}

int main(void){
 ft_init(); ft_raw(); ft_alt(1); ft_cursor(0); ft_clear();
 int sel=0,f=0,dirty=1;
 long long la=ft_ms();
 for(;;){
  FKey k=ft_key();
  switch(k.type){
  case FK_UP:   if(sel>0){sel--;dirty=1;} break;
  case FK_DOWN: if(sel<NGAMES-1){sel++;dirty=1;} break;
  case FK_ENTER:{
   int rc=ft_launch(G[sel].binary); dirty=1;
   if(rc==127){draw(sel,f);ft_go(17,3);
    printf(FT_RED "  \xe2\x9c\x97 %s not found" FT_RST "\033[K",G[sel].binary);
    fflush(stdout);ft_sleep(2000);}
   break;}
  case FK_ESC: goto done;
  case FK_CHAR:
   if(k.ch=='q'||k.ch=='Q'||k.ch==3) goto done;
   if(k.ch>='1'&&k.ch<='0'+NGAMES){
    sel=k.ch-'1';dirty=1;draw(sel,f);fflush(stdout);
    int rc=ft_launch(G[sel].binary);dirty=1;
    if(rc==127){draw(sel,f);ft_go(17,3);
     printf(FT_RED "  \xe2\x9c\x97 %s not found" FT_RST "\033[K",G[sel].binary);
     fflush(stdout);ft_sleep(2000);}
   } break;
  default:break;
  }
  long long now=ft_ms();
  if(now-la>=250){f=(f+1)%4;la=now;dirty=1;}
  if(ft__resized){ft__resized=0;ft_clear();dirty=1;}
  if(dirty){draw(sel,f);dirty=0;}
  ft_sleep(25);
 }
done:
 ft_end();
 printf(FT_DIM "  FlowerOS \xc2\xb7 Bye!\n" FT_RST "\n");
 return 0;
}
''').lstrip('\n')

with open(path, 'w', newline='\n') as f:
    f.write(src)

print(f"Wrote {len(src)} bytes to {path}")
