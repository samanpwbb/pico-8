pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
 function _init()
 t=0
 shake=0

 dpal=ints("0,1,1,2,1,13,6,4,4,9,3,13,1,13,14")

 dirx=ints("-1,1,0,0,1,1,-1,-1")
 diry=ints("0,0,-1,1,-1,1,1,-1")

 crv_sig=ints("255,214,124,179,233")
 crv_msk=ints("0,9,3,12,6")
 free_sig=ints("0,0,0,0,16,64,32,128,161,104,84,146")
 free_msk=ints("8,4,2,1,6,12,9,3,10,5,10,5")

 --all wall binary signatures
 --in order matching sprites
 wall_sig=ints("251,233,253,84,146,80,16,144,112,208,241,248,210,177,225,120,179,0,124,104,161,64,240,128,224,176,242,244,116,232,178,212,247,214,254,192,48,96,32,160,245,250,243,249,246,252")
 wall_msk=ints("0,6,0,11,13,11,15,13,3,9,0,0,9,12,6,3,12,15,3,7,14,15,0,15,6,12,0,0,3,6,12,9,0,9,0,15,15,7,15,14,0,0,0,0,0,0")

 itm_name=split("twig,stick,club,cane,staff,heavy log,shawl,cloak,robe,cape,gown,regalia,food 1,food 2,food 3,food 4,food 5,food 6,pebble,rock,stone,boulder")
	itm_type=split("wep,wep,wep,wep,wep,wep,arm,arm,arm,arm,arm,arm,fud,fud,fud,fud,fud,fud,thr,thr,thr,thr")
	itm_stat1=ints("1,2,3,4,5,6,0,0,0,0,1,2,1,2,3,4,5,6,1,2,3,4")
	itm_stat2=ints("0,0,0,0,0,0,1,2,3,4,3,3,0,0,0,0,0,0,0,0,0,0")
	itm_minf=ints("1,2,3,4,5,6,1,2,3,4,5,6,1,1,1,1,1,1,1,2,3,4")
	itm_maxf=ints("3,4,5,6,7,8,3,4,5,6,7,8,8,8,8,8,8,8,4,6,7,8")
	itm_desc=split(",,,,,,,,,,,,heals,heals a lot,increases hp,stuns,is cursed,is blessed,,,,")

	mob_name=split("player,slime,rodent,goblin,beast,giant moth,specter,minotaur,dragon")
	mob_ani=ints("240,192,196,200,204,208,212,216,220")
	mob_atk=ints("1,1,2,1,2,3,3,5,5")
	mob_hp=ints("5,1,2,3,6,4,5,14,8")
	mob_los=ints("4,4,4,4,4,4,4,4,4")
	mob_minf=ints("0,1,2,3,4,5,6,7,8")
	mob_maxf=ints("0,3,4,5,6,7,8,8,8")
	mob_spec=split(",,,,slow,stun,curse,slow,")

 startgame()
end

function _update60()
 t+=1
 _upd()
 dofloats()
 dohpwind()
end

function _draw()
 doshake()
 _drw()
 drawind()
 checkfade()
end

function startgame()
 --loop music pattern 1
 poke(0x3101,194)
 music(0)
 tani=0
 fadeperc=1
 btnbuff=-1

 st_meals,st_kills,st_steps,st_killer=0,0,0

 logo_t=240
 logo_y=50

 skipai=false
 win=false
 winfloor=9

 thrdx,thrdy=2,0,-1

 mob={}
 dmob={}
 p_mob=addmob(1,1,1)

 p_t=0

 inv,eqp={},{}
 makeipool()
 foodnames()

 wind={}
 float={}

 talkwind=nil

 hpwind=addwind(5,5,28,13,{})
 _upd=update_game
 _drw=draw_game
 genfloor(0)
 unfog()
 calcdist(p_mob.x,p_mob.y)
end

-->8
--updates
function update_game()
 if talkwind then
  if getbtn()==5 then
   sfx(53)
   talkwind.dur=0
   talkwind=nil
  end
 else
  dobtnbuff()
 	dobtn(btnbuff)
  btnbuff=-1
 end
end

function update_inv()
 if move_mnu(curwind) and curwind==invwind then
  showhint()
 end
 --close window
 if btnp(4) then
  sfx(53)
  if curwind==invwind then
   _upd=update_game
   invwind.dur=0
   statwind.dur=0
   if hintwind then
    hintwind.dur=0
   end
  elseif curwind==usewind then
   usewind.dur=0
   curwind=invwind
  end
 --use item
 elseif btnp(5) then
  sfx(54)
  if curwind==invwind and invwind.cur!=3 then
   showuse()
  elseif curwind==usewind then
   triguse()
  end
 end
end

function update_throw()
 local b=getbtn()
 if b>=0 and b<=3 then
  thrdx=dirx[b+1]
  thrdy=diry[b+1]
 end
 if b==4 then
  _upd=update_game
 elseif b==5 then
  throw()
 end

end

function move_mnu(wnd)
 local moved=false
 if btnp(2) then
  sfx(56)
  wnd.cur-=1
  moved=true
 elseif btnp(3) then
  sfx(56)
  wnd.cur+=1
  moved=true
 end
 wnd.cur=(wnd.cur-1)%#wnd.txt+1
 return moved
end

function update_pturn()
 dobtnbuff()
 p_t=min(p_t+0.2,1)

 if p_mob.mov then
  p_mob:mov()
 end

 if p_t==1 then
 	_upd=update_game
  if trig_step() then
    return
  end

 	if checkend() and not skipai then
   doai()
  end
  skipai=false
 end
end

function update_aiturn()
 dobtnbuff()
 p_t=min(p_t+0.2,1)
 for m in all(mob) do
  if m!=p_mob and m.mov then
   	m:mov(m)
  end
 end
 if p_t==1 then
 	_upd=update_game
  if checkend() then
   --handle stun
   if p_mob.stun then
    p_mob.stun=false
    doai()
   end
  end
 end
end

function update_gover()
 if btnp(❎) then
  sfx(54)
  fadeout()
  startgame()
 end
end

function dobtnbuff()
 if btnbuff==-1 then
	 btnbuff=getbtn()
	end
end

function getbtn()
 for i=0,5 do
	 if btnp(i) then
	 	return i
 	end
 end
 return -1
end

function dobtn(bt)
 if bt<0 then return end
 if logo_t>0 then logo_t=0 end
 if bt<4 then
	 moveplayer(dirx[bt+1],diry[bt+1])
 elseif bt==5 then
  sfx(54)
  showinv()
 end
end

-->8
--draw
function draw_game()
 cls(0)
 -- short circuit if blank
 if fadeperc==1 then return end
 map()
 animap()
 drawlogo()

 --death sequence
 for m in all(dmob) do
  if sin(time()*8)>0 or m==p_mob then
   drawmob(m)
  end
  m.dur-=1
  if m.dur<=0 and m!=p_mob then
   del(dmob,m)
  end
 end

 --mobs
 for i=#mob,1,-1 do
  drawmob(mob[i])
 end
 drawmob(p_mob)

 --throw
 if _upd==update_throw then
  local tx,ty=throwtile()
  local lx1,ly1,lx2,ly2=p_mob.x*8+3+thrdx*4,p_mob.y*8+3+thrdy*4,mid(0,tx*8+3,127),mid(0,ty*8+3,127)

  rectfill(lx1+thrdy,ly1+thrdx,lx2-thrdy,ly2-thrdx,0)
  local thrani=flr(t/7)%2==0

  local pat=thrani and 0b1010010110100101 or 0b0101101001011010
  fillp(pat)

  line(lx1,ly1,lx2,ly2,14)
  fillp()
  oprint8("+",lx2-1,ly2-2,14,0)

  local mb=getmob(tx,ty)
  if mb and thrani then
   mb.flash=1
  end
 end

 --fog
 visbrd(function(x,y)
  if fog[x][y]==1 then
   rectfill2(x*8,y*8,8,8,0)
  end
 end)

 --floating text
 for f in all(float) do
  oprint8(f.txt,f.x,f.y,f.c,0)
 end
end

function drawlogo()

 if logo_t>-100 then
  logo_t-=1

  if logo_t<=0 then
   logo_y+=logo_t/20
  end
  palt(1,true)
  palt(0,false)
  spr(128,36,logo_y,7,2)
  palt()
 end

end

function drawmob(m)
 local c
 if m.flash>0 then
  m.flash-=1
  c=7
 end
 drawspr(getframe(m.ani),m.x*8+m.ox,m.y*8+m.oy,c,m.flp)
end

function draw_gover()
 cls()
 palt(0,false)
 spr(gover_spr,gover_x,30,gover_w,2)
 palt()
 drawstats()
end

function animap()
 tani+=1
 if (tani<15) return
 visbrd(function(x,y)
  tani=0
  local tle=mget(x,y)
  if tle==64 or tle==66 then
   tle+=1
  elseif tle==65 or tle==67 then
   tle-=1
  end
  mset(x,y,tle)
 end)
end

function drawstats()
 color(7)
 cursor(44,50)
 print("steps: "..st_steps)
 print("kills: "..st_kills)
 print("meals: "..st_meals)

 if not win then
  print("defeated by a",36,76)
  print(st_killer.." on floor "..floor,30,82)
 end

 print("press ❎",46,96,5+abs(0.5+sin(time())*2))

end

function doshake()
 local shakex,shakey=16-rnd(32),16-rnd(32)
 camera(shakex*shake,shakey*shake)
 shake*=0.95
 if (shake<0.05) shake=0
end
-->8
--tools

function getframe(ani)
 return ani[flr(t/15)%#ani+1]
end

function drawspr(_spr,_x,_y,_c,_flip)
	palt(0,false)
 if _c then
  pal(12,_c)
  pal(13,_c)
  pal(11,_c)
  pal(3,_c)
 end
	spr(_spr,_x - (_flip and 1 or 0),_y,1,1,_flip)
	pal()
end

function rectfill2(_x,_y,_w,_h,_c)
 --★
 rectfill(_x,_y,_x+max(_w-1,0),max(_y+_h-1,0),_c)
end

function oprint8(_t,_x,_y,_c,_c2)
 for i=1,8 do
  print(_t,_x+dirx[i],_y+diry[i],_c2)
 end
 print(_t,_x,_y,_c)
end

function dist(fx,fy,tx,ty)
 return sqrt((fx-tx)^2+(fy-ty)^2)
end

function dofade()
 local p,kmax,col,k=flr(mid(0,fadeperc,1)*100)
 for j=1,15 do
  col=j
  kmax=flr((p+j*1.46)/22)
  for k=1,kmax do
   col=dpal[col]
  end
  pal(j,col,1)
 end
end

function checkfade()
 if fadeperc>0 then
  fadeperc=max(fadeperc-0.04,0)
  dofade()
 end
end

function wait(_wait)
 repeat
  _wait-=1
  flip()
 until _wait<0
end

function fadeout(_wait)
 if (_wait==nil) _wait=0
 repeat
  fadeperc=min(fadeperc+0.04,1)
  dofade()
  flip()
 until fadeperc==1
 wait(_wait)
end

function blankmap(_dflt)
 local ret={}
 if(_dflt==nil) _dflt=0

 for x=0,15 do
  ret[x]={}
  for y=0,15 do
   ret[x][y]=_dflt
  end
 end
 return ret
end

function getrnd(arr)
 return arr[1+flr(rnd(#arr))]
end

function visit(cb,xmin,xmax,ymin,ymax)
 for x=xmin,xmax do
  for y=ymin,ymax do
   cb(x,y)
  end
 end
end

function visbrd(cb)
 return visit(cb,0,15,0,15)
end

function copymap(x,y)
 local tle
 visbrd(function(_x,_y)
  tle=mget(x+_x,_y+y)
  mset(_x,_y,tle)
  if tle==15 then
   p_mob.x,p_mob.y=_x,_y
  end
 end)
end

function arrtoint(arr)
 ret={}
 for i in all(arr) do
  add(ret,tonum(i))
 end
 return ret
end

function ints(v)
 return arrtoint(split(v))
end

function rndint(mn,mx)
 local val=flr(rnd(1+mx-mn))+mn
 return val
end
-->8
--gameplay

function moveplayer(dx,dy)
 local destx,desty=p_mob.x+dx,p_mob.y+dy
 local tle=mget(destx,desty)

 if iswalkable(destx,desty,"checkmobs") then
  sfx(63)
  mobwalk(p_mob,dx,dy)
  st_steps+=1
  p_t=0
 	_upd=update_pturn
 else
  --not walkable
  mobbump(p_mob,dx,dy)
  p_t=0
  _upd=update_pturn

  local mob=getmob(destx,desty)
  if mob then
	  hitmob(p_mob,mob)
 	else
  	if fget(tle,1) then
	   trig_bump(tle,destx,desty)
	  else
	   skipai=true
  	end
 	end
 end
 unfog()
end

function trig_bump(tle, destx, desty)
 if tle==7 or tle==8 then
 	--vase
 	sfx(59)
 	mset(destx,desty,5)
 	if rnd(3)<1 and floor>0 then
   --add monster if unlucky
   if rnd(5)<1 then
    addmob(getrnd(mobpool),destx,desty)
    sfx(60)
   end

   if freeinvslot()==0 then
    showmsg("inventory full!",60)
    sfx(60)
   else
    local itm=getrnd(fipool_com)
   	takeitem(itm)
    showmsg(itm_name[itm].."!",60)
    sfx(61)
   end
 	end

 elseif tle==6 then
  --tablet
  if floor==winfloor then
   win=true
  elseif floor==0 then
   sfx(54)
   showtalk(split("do not disturb!,this is a sanctuary,for peaceful monsters"))
  end
 elseif tle==10 or tle==12 then
 	--chest
  if freeinvslot()==0 then
   showmsg("inventory full",60)
   skipai=true
  else
   local itm=getrnd(fipool_com)
   if tle==12 then
    itm=getitm_rar()
   end
  	sfx(61)
  	mset(destx,desty,tle-1)
   showmsg(itm_name[itm].."!",60)
  	takeitem(itm)
  end
 elseif tle==13 then
	 --door
 	sfx(62)
 	mset(destx,desty,1)
 end
end

function trig_step()
 local tle=mget(p_mob.x,p_mob.y)

 if tle==14 then
  sfx(55)
  p_mob.bless=0
  fadeout()
  genfloor(floor+1)
  floormsg()
  return true
 end
 return false
end

function getmob(x,y)
 for m in all(mob) do
  if m.x==x and m.y==y then
   return m
  end
 end
 return false
end

function iswalkable(x,y,mode)
 local mode=mode or ""
 if inbounds(x,y) then
  local tle=mget(x,y)
  if mode=="sight" then
   return not fget(tle,2)
  end
  if not fget(tle,0) then
   if mode=="checkmobs" then
    return not getmob(x,y)
   end
   return true
  end
 end
 return false
end

function inbounds(x,y)
 return not (x<0 or y<0 or x>15 or y>15)
end

function hitmob(atkm,defm)
 local dmg=atkm.atk

 if defm.bless<0 then
  dmg*=2
 elseif defm.bless>0 then
  dmg=flr(dmg/2)
 end
 defm.bless=0

 dmg-=defm.defmin+flr(rnd(defm.defmax-defm.defmin+1))
 dmg=max(0,dmg)
 defm.hp-=dmg
 defm.flash=10

 sfx(58)
 addfloat("-"..dmg,defm.x*8,defm.y*8,14)

 shake=defm==p_mob and 0.07 or 0.03

 if defm.hp<=0 then
  if defm != p_mob then
   st_kills+=1
  else
   st_killer=atkm.name
  end

  defm.dur=15
  add(dmob,defm)
  del(mob,defm)
 end
end

function healmob(mb,hp)
 hp=min(mb.hpmax-mb.hp,hp)
 mb.hp+=hp
 mb.flash=10

 sfx(51)
 addfloat("+"..hp,mb.x*8,mb.y*8,14)
end

function stunmob(mb)
 mb.stun=true
 mb.flash=10
 addfloat("stun",mb.x*8,mb.y*8,14)
 sfx(51)
end

function blessmob(mb,val)
 mb.bless=mid(-1,1,mb.bless+val)
 mb.flash=10
 local txt=val>0 and "bless" or "curse"
 addfloat(txt,mb.x*8,mb.y*8,14)

 --hit ghost
 if mb.spec=="curse" and val>0 then
  add(dmob,mb)
  del(mob,mb)
  mb.dur=10
 end
 sfx(51)

end

function checkend()
 if win then
  music(24)
  gover_spr,gover_x,gover_w=165,40,5
  showgover()
  return false
 elseif p_mob.hp<=0 then
  music(22)
  gover_spr,gover_x,gover_w=161,44,4
  showgover()
  return false
 end
 return true
end

function showgover()
 fadeout(1)
 wind,_drw,_upd={},draw_gover,update_gover
end


function los(x1,y1,x2,y2)
 local frst,sx,sy,dx,dy=true
 if dist(x1,y1,x2,y2)==1 then
  return true
 end

 if y1>y2 then
  x1,x2,y1,y2=x2,x1,y2,y1
 end
 sy,dy=1,y2-y1

 if x1<x2 then
  sx,dx=1,x2-x1
 else
  sx,dx=-1,x1-x2
 end

 local err,e2=dx-dy

 while not(x1==x2 and y1==y2) do
  if not frst and iswalkable(x1,y1,"sight")==false then
   return false
  end
  frst=false
  e2=err+err
  if e2>-dy then
   err-=dy
   x1+=sx
  end
  if e2<dx then
   err+=dx
   y1=y1+sy
  end
 end
 return true
end

function unfog()
 local px,py=p_mob.x,p_mob.y
 for x=0,15 do
  for y=0,15 do

   if fog[x][y]==1 and dist(px,py,x,y)<=p_mob.los and los(px,py,x,y) then
    unfogtile(x,y)
   end
  end
 end
end

function unfogtile(x,y)
 fog[x][y]=0
 --note:can be out of p_mob.los
 if iswalkable(x,y,"sight") then
  for i=1,4 do
   local tx,ty=x+dirx[i],y+diry[i]
   if inbounds(tx,ty) and not iswalkable(tx,ty,"sight") then
    fog[tx][ty]=0
   end
  end
 end
end

function calcdist(tx,ty)
 local cand,step,candnew={},0
 distmap=blankmap(-1)
 add(cand, {x=tx,y=ty})
 distmap[tx][ty]=0
 repeat
  step+=1
	 candnew={}
	 for c in all(cand) do
	  for d=1,4 do
	   local dx=c.x+dirx[d]
	   local dy=c.y+diry[d]
	   if inbounds(dx,dy) and distmap[dx][dy]==-1 then
  	  distmap[dx][dy]=step
     if iswalkable(dx,dy) then
 	    add(candnew,{x=dx,y=dy})
	    end
	   end
	  end
	 end
  cand=candnew
 until #cand==0
end

function updatestats()
 if eqp[1] then
  p_mob.atk=1+itm_stat1[eqp[1]]
 end
 if eqp[2] then
  p_mob.defmin=0+itm_stat1[eqp[2]]
  p_mob.defmax=0+itm_stat2[eqp[2]]
 end
end

function eat(itm,mb)
 local effect=itm_stat1[itm]

 if not itm_known[itm] then
  showmsg(itm_name[itm]..itm_desc[itm],60)
  itm_known[itm]=true
 end

 if mb==p_mob then st_meals+=1 end
 if effect==1 then
  --heal
  healmob(mb,1)
 elseif effect==2 then
  --heal more
  healmob(mb,3)
 elseif effect==3 then
  --hp up
  mb.hpmax+=1
 elseif effect==4 then
  --stun
  stunmob(mb)
 elseif effect==5 then
  --curse
  blessmob(mb,-1)
 elseif effect==6 then
  --bless
  blessmob(mb,1)
 end
end

function throw()
 local itm,tx,ty=inv[thrslt],throwtile()
 sfx(52)
 if inbounds(tx,ty) then
  local mb=getmob(tx,ty)
  if mb then
   if itm_type[itm]=="fud" then
    eat(itm,mb)
   else
    sfx(58)
    printh(itm_stat1[itm])
    printh(itm)
    hitmob({atk=itm_stat1[itm]},mb)
   end
  end
 end
 mobbump(p_mob,thrdx,thrdy)

 inv[thrslt]=nil
 p_t=0
 _upd=update_pturn
end

function throwtile()
 local tx,ty=p_mob.x,p_mob.y
 repeat
  tx+=thrdx
  ty+=thrdy
 until not iswalkable(tx,ty,"checkmobs")
 return tx,ty
end
-->8
--ui

function addwind(_x,_y,_w,_h,_txt)
 return add(wind,{x=_x,
                  y=_y,
                  w=_w,
                  h=_h,
                  txt=_txt})
end

function drawind()
 for w in all(wind) do
  local wx,wy,ww,wh=w.x,w.y,w.w,w.h
  rectfill2(wx,wy,ww,wh,0)
  rect(wx+1,wy+1,wx+ww-2,wy+wh-2,14)
  wx+=4
  wy+=4
  clip(wx,wy,ww-8,wh-8)

  if w.cur then
   wx+=6
  end

  for i=1,#w.txt do
   local t,c=w.txt[i],14
   if w.col and w.col[i] then
    c=w.col[i]
   end

   print(t,wx,wy,c)
   if i==w.cur then
    spr(255,wx-5+(sin(time())/2),wy)
   end
   wy+=6
  end

  -- clear clip to draw btn outside
  clip()

  if w.dur then
   w.dur-=1
   if w.dur<=0 then
    local dif=w.h/4
    w.y+=dif/2
    w.h-=dif
    if w.h<3 then
     del(wind,w)
    end
   end
  else
   if w.btn then
    oprint8("❎",wx+ww-15,wy-0.5+sin(time()),14,0)
   end
  end
 end
end

function showmsg(txt,dur)
 local wid=(#txt+2)*4+7
 local w=addwind(63-wid/2,50,wid,13,{" "..txt})
 w.dur=dur
end

function showtalk(txt)
 talkwind=addwind(16,50,94,#txt*6+7,txt)
 talkwind.btn=true
end

function addfloat(_txt,_x,_y,_c)
 add(float, {txt=_txt,x=_x,y=_y,c=_c,ty=_y-7,t=0})
end

function dofloats()
 for f in all(float) do
  f.y+=(f.ty-f.y)/10
  f.t+=1
  if f.t>50 then
   del(float,f)
  end
 end
end

function dohpwind()
  hpwind.txt[1]="♥"..p_mob.hp.."/"..p_mob.hpmax
  local hpy=5
  if p_mob.y<8 then
   hpy=110
  end
  hpwind.y+=(hpy-hpwind.y)/5
end

function showinv()
 local txt,col,itm,eqt={},{}
 _upd=update_inv

 for i=1,2 do
  itm,eqt=eqp[i]
  if itm then
   eqt=itm_name[itm]
   add(col,7)
  else
   eqt=i==1 and "[weapon]" or "[armor]"
   add(col,2)
  end
  add(txt,eqt)
 end

 add(txt,"………………")
 add(col,14)

 for i=1,6 do
  itm=inv[i]
  if itm then
   add(txt,itm_name[itm])
   add(col,7)
  else
   add(txt,"...")
   add(col,2)
  end
 end

 invwind=addwind(5,17,84,62,txt)
 invwind.cur=1
 invwind.col=col

 local txt="ok    "
 if p_mob.bless<0 then
  txt="curse "
 elseif p_mob.bless>0 then
  txt="bless "
 end

 statwind=addwind(5,5,84,13,{txt.."atk:"..p_mob.atk.." def:"..p_mob.defmin.."-"..p_mob.defmax})
 curwind=invwind
end

function showuse()
 local itm=invwind.cur<3 and eqp[invwind.cur] or inv[invwind.cur-3]
 if itm==nil then return end
 local typ,txt=itm_type[itm],{}

 if invwind.cur>3 and (typ=="wep" or typ=="arm") then
  add(txt,"equip")
 end

 if typ=="fud" then
  add(txt,"eat")
 end

 if typ=="thr" or typ=="fud" then
  add(txt,"throw")
 end
 add(txt,"trash")

 usewind=addwind(84,invwind.cur*6+11,36,7+#txt*6,txt)
 usewind.cur=1
 curwind=usewind
end

function triguse()
 local verb,i,back=usewind.txt[usewind.cur],invwind.cur,true
 local itm=i<3 and eqp[i] or inv[i-3]

 if verb=="trash" then
  if i<3 then
   eqp[i]=nil
  else
   inv[i-3]=nil
  end
 elseif verb=="equip" then
  local slot=itm_type[itm]=="wep" and 1 or 2
  inv[i-3]=eqp[slot]
  eqp[slot]=itm
 elseif verb=="eat" then
  eat(itm,p_mob)
  inv[i-3]=nil
  p_mob.mov=nil
  p_t=0
  _upd=update_pturn
  back=false
 elseif verb=="throw" then
  _upd,thrslt,back=update_throw,i-3,false
 end

 updatestats()
 usewind.dur=0

 if back then
  del(wind,invwind)
  del(wind,statwind)
  showinv()
  invwind.cur=i
 else
  invwind.dur=0
  statwind.dur=0
  if hintwind then
   hintwind.dur=0
  end
  p_t=0
 end
end

function floormsg()
 showmsg("floor "..floor,120)
end

function showhint()
 if hintwind then
  hintwind.dur=0
  hintwind=nil
 end

 if invwind.cur>3 then
  local itm=inv[invwind.cur-3]
  if itm and itm_type[itm]=="fud" then
   local txt=itm_known[itm] and itm_name[itm]..itm_desc[itm] or "???"
   hintwind=addwind(5,78,#txt*4+7,13,{txt})
  end
 end
end

-->8
--mobs
function addmob(typ,mx,my)
 local m={
  x=mx,
  y=my,
  ox=0,
  oy=0,
  flp=false,
  stun=false,
  bless=0,
  charge=1,
  spec=mob_spec[typ],
  lastmoved=false,
  ani={},
  flash=0,
  defmin=0,
  defmax=0,
  hp=mob_hp[typ],
  hpmax=mob_hp[typ],
  atk=mob_atk[typ],
  los=mob_los[typ],
  task=ai_wait,
  name=mob_name[typ]
 }

 for i=0,3 do
  add(m.ani,mob_ani[typ]+i)
 end
 add(mob,m)
 return m
end

function mobwalk(mb,dx,dy)
 mb.x+=dx
 mb.y+=dy

 mobflip(mb,dx)
 mb.sox,mb.soy=-dx*8,-dy*8
 mb.ox,mb.oy=mb.sox,mb.soy
 mb.mov=mov_walk
end

function mobbump(mb,dx,dy)
 mobflip(mb,dx)
 mb.sox,mb.soy=dx*8,dy*8
 mb.ox,mb.oy=0,0
 mb.mov=mov_bump
end

function mobflip(mb,dx)
 mb.flp=dx==0 and mb.flp or dx<0
end

function mov_walk(self)
 local tme=1-p_t
 self.ox=self.sox*tme
 self.oy=self.soy*tme
end

function mov_bump(self)
 local tme=p_t>0.5 and 1-p_t or p_t
 self.ox=self.sox*tme
 self.oy=self.soy*tme
end

function doai()
 local moving=false
 for m in all(mob) do
  if m!=p_mob then
   m.mov=nil
   if m.stun then
    m.stun=false
   else
    m.lastmoved=m.task(m)
    moving=m.lastmoved or moving
   end
  end
 end
 if moving then
  _upd=update_aiturn
  p_t=0
 else
  p_mob.stun=false
 end
end

function ai_wait(m)
 if cansee(m,p_mob) then
  --aggro
  m.task=ai_atk
  m.tx,m.ty=p_mob.x,p_mob.y
  addfloat("!",m.x*8+2,m.y*8,14)
  return true
 end
 return false
end

function ai_atk(m)
 if dist(m.x,m.y,p_mob.x,p_mob.y)==1 then
  --attack
  dx,dy=p_mob.x-m.x,p_mob.y-m.y

  --some monsters stun
  if m.spec=="stun" and m.charge>0 then
   stunmob(p_mob)
   m.charge-=1
  elseif m.spec=="curse" and m.charge>0 then
   hitmob(m,p_mob)
   blessmob(p_mob,-1)
   m.charge-=1
  else
   --others dmg
   hitmob(m,p_mob)
  end
  sfx(57)

  mobbump(m,dx,dy)
  return true
 else
  --move
  --update los
  if cansee(m,p_mob) then
   m.tx,m.ty=p_mob.x,p_mob.y
  end

  if m.x==m.tx and m.y==m.ty then
   --drop aggro
   m.task=ai_wait
   addfloat("?",m.x*8+2,m.y*8,10)
  else
   if m.spec=="slow" and m.lastmoved then
    return false
   end
   --move to player
   local bdst,cand=999,{}
   calcdist(m.tx,m.ty)
   for i=1,4 do
    local dx,dy=dirx[i],diry[i]
    local tx,ty=m.x+dx,m.y+dy
    if iswalkable(tx,ty,"checkmobs") then
     local dst=distmap[tx][ty]
     if dst<bdst then
      cand={}
      bdst=dst
     end

     if dst==bdst then
      add(cand,i)
     end
    end
   end
   if #cand>0 then
    local c=getrnd(cand)
    mobwalk(m,dirx[c],diry[c])
    return true
   end
  end
 end
 return false
end

function cansee(m1,m2)
 return dist(m1.x,m1.y,m2.x,m2.y)<=m1.los and los(m1.x,m1.y,m2.x,m2.y)
end

function placemobs()
 mobpool={}

 for i=2,#mob_name do
  if mob_minf[i]<=floor and mob_maxf[i]>=floor then
   add(mobpool,i)
  end
 end

 if #mobpool==0 then return end

 local minmons=ints("3,5,7,9,10,11,12,13")
 local maxmons=ints("6,8,11,14,16,18,20,22")
 local placed,rpot=0,{}

 for r in all(rooms) do
  add(rpot,r)
 end

 --add mobs to rooms
 repeat
  local r=getrnd(rpot)
  placed+=infestroom(r)
  del(rpot,r)
 until #rpot==0 or placed>=maxmons[floor]

 --extra mobs
 if placed<minmons[floor] then
  repeat
   local x,y
   local m=mget(x,y)
   repeat
    x,y=rndint(0,16),rndint(0,16)
   until iswalkable(x,y,"checkmobs")
   addmob(getrnd(mobpool),x,y)
   placed+=1
  until placed>=minmons[floor]
 end

end

function infestroom(r)
 if r.nospawn then return 0 end
 local target,x,y=min(5,2+rndint(0,r.w*r.h/6-1))

 for i=1,target do
  repeat
   x=r.x+rndint(0,r.w)
   y=r.y+rndint(0,r.h)
  until iswalkable(x,y,"checkmobs")
  addmob(getrnd(mobpool),x,y)
 end

 return target
end

-----------------------
--items
-----------------------

function takeitem(itm)
 local i=freeinvslot()
 if i==0 then return false end
 inv[i]=itm
 return true
end

function freeinvslot()
 for i=1,6 do
  if not inv[i] then
   return i
  end
 end
 return 0
end

function makeipool()
 ipool_rar={}
 ipool_com={}

 for it=1,#itm_name do
  local t=itm_type[it]
  if t=="wep" or t=="arm" then
   add(ipool_rar,it)
  else
   add(ipool_com,it)
  end
 end
end

function makefipool()
 fipool_rar={}
 fipool_com={}

 for it in all(ipool_rar) do
  if itm_minf[it]<=floor
   and itm_maxf[it]>=floor then
   add(fipool_rar,it)
  end
 end

 for it in all(ipool_com) do
  if itm_minf[it]<=floor
   and itm_maxf[it]>=floor then
   add(fipool_com,it)
  end
 end

end

function getitm_rar()
 if #fipool_rar>0 then
  local itm=getrnd(fipool_rar)
  del(fipool_rar,itm)
  del(ipool_rar,itm)
  return itm
 else
  return getrnd(fipool_com)
 end
end

function foodnames()
 local fud,fu=split("seeds ,fruit ,berry ,nut ,bean ,slime ,leaf ,sprig ,fungus ,herb ,sprout ,tuber ")
 local adj,ad=split("slimy,leafy,firm,fruity,nutty,sweet,bitter,sour,oily,herbal,weird,aromatic,fresh,dry,moist")

 itm_known={}
 for i=1,#itm_name do
  if itm_type[i]=="fud" then
   itm_name[i]=rnd(9)
   fu,ad=getrnd(fud),getrnd(adj)
   del(fud,fu)
   del(adj,ad)
   itm_name[i]=ad.." "..fu
   itm_known[i]=false
  end
 end
end
-->8
--gen
function genfloor(f)
 floor=f
 makefipool()

 -- clear mobs
 mob={}
 add(mob,p_mob)

 if floor==1 then
  st_steps=0
  --update music
  poke(0x3101,66)
 end

 if floor==0 then
  copymap(16,1)
  fog=blankmap(0)
 elseif floor==winfloor then
  copymap(32,1)
  fog=blankmap(0)
 else
  fog=blankmap(1)
  mapgen()
  unfog()
 end
end

function mapgen()
 repeat
  --fill map with obstacles
  copymap(48,0)
	 --globals
	 rooms={}
	 roomap=blankmap(0)
	 doors={}
  --generate fns
	 genrooms()
  mazeworm()
  placeflags()
  carvedoors()
 until #flaglib==1

 carvescuts()
 startend()
 fillends()
 prettywalls()
 placedoors()
 placechests()
 placemobs()
 decorooms()
end

function snapshot()
 cls()
 map()
 for i=0,2 do
  flip()
 end
end

----------------
--rooms
----------------

function genrooms()
 local rmax=4
 sizes,xbase,ybase=ints("7,5,3"),rndint(0,1),rndint(0,1)
 repeat
  local r={
   x=0,y=0,
   w=getrnd(sizes),
   h=getrnd(sizes)
  }
  if placeroom(r) then
   rmax-=1
  else
   deli(sizes,1)
  end
 until #sizes==0 or rmax<=0
end

function placeroom(r)
 local cand,c={}

 visit(function(x,y)
   if x%2!=xbase and y%2!=ybase and doesroomfit(r,x,y) then
    add(cand,{x=x,y=y})
   end
  end,
  0,16-r.w,0,16-r.h)

 if #cand==0 then return false end
 c=getrnd(cand)
 r.x=c.x
 r.y=c.y

 add(rooms,r)

 visit(function(x,y)
   mset(x+r.x,y+r.y,1)
   roomap[x+r.x][y+r.y]=#rooms
  end,
  0,r.w-1,0,r.h-1)

 return true
end

function doesroomfit(r,x,y)
 for _x=-1,r.w do
  for _y=-1,r.h do
   if iswalkable(_x+x,_y+y) then
    return false
   end
  end
 end
 return true
end

----------------
-- maze
----------------

function mazeworm()
 repeat
	 local cand={}
	 visbrd(
	  function(x,y)
	   if cancarve(x,y,false) and not nexttoroom(x,y) then
	    add(cand,{x=x,y=y})
	   end
	  end)

	 if #cand>0 then
	  local c=getrnd(cand)
	  digworm(c.x,c.y)
	 end
 until #cand<=1

 --carve out excess chunks
 --todo: can cut this?
 repeat
  local cand={}
  visbrd(function(x,y)
   if cancarve(x,y,false) and not nexttoroom(x,y) then
    add(cand,{x=x,y=y})
   end
  end)
  if #cand>0 then
	  local c=getrnd(cand)
	  mset(c.x,c.y,1)
	 end
 until #cand==0
end

function digworm(x,y)
 local dr,step=rndint(1,4),0

 repeat
  mset(x,y,1)
  if not cancarve(x+dirx[dr],y+diry[dr],false) or (rnd()<0.5 and step>=2) then
   local cand={}
   for i=1,4 do
    if cancarve(x+dirx[i],y+diry[i],false) then
     add(cand,i)
    end
   end
   if #cand==0 then
    dr=8
   else
    step=0
    dr=getrnd(cand)
   end
  end
  x+=dirx[dr]
  y+=diry[dr]
  step+=1
 until dr==8

end

function cancarve(x,y,walk)
 if not inbounds(x,y) then return false end
 local walkable=iswalkable(x,y)
 local walk=walk==nil and walkable or walk

 if walkable==walk then
  return sigarray(getsig(x,y),crv_sig,crv_msk)!=0
 end
 return false
end

function bcomp(sig,match,mask)
 local mask=mask or 0
 return sig|mask==match|mask
end

function getsig(x,y)
 --binary digit 4 some reason
 local sig, digit=0
 for i=1,8 do
  local dx,dy=x+dirx[i],y+diry[i]
  if iswalkable(dx,dy) then
   digit=0
  else
   digit=1
  end
  sig=bor(sig,shl(digit,8-i))
 end
 return sig
end

function sigarray(sig,arr,marr)
 for i=1,#arr do
  if bcomp(sig,arr[i],marr[i]) then
   return i
  end
 end
 return 0
end

----------------
-- doorways
----------------

function placeflags()
 local curf=1
 flgs,flaglib=blankmap(0),{}
 visbrd(function(x,y)
  if iswalkable(x,y) and flgs[x][y]==0 then
   growflag(x,y,curf)
   add(flaglib,curf)
   curf+=1
  end
 end)
end

function growflag(x,y,flg)
 local cand,candnew={{x=x,y=y}}
 flgs[x][y]=flg

 repeat
  candnew={}
  for c in all(cand) do
   flgs[c.x][c.y]=flg
   for d=1,4 do
    local dx,dy=c.x+dirx[d],c.y+diry[d]
    if iswalkable(dx,dy) and flgs[dx][dy]!=flg then
     flgs[dx][dy]=flg
     add(candnew,{x=dx,y=dy})
    end
   end
  end
  cand=candnew
 until #cand==0
end

function carvedoors()
 local x1,y1,x2,y2,found,drs,f1,f2=1,1,1,1

 repeat
  drs={}
  visbrd(function(x,y)
   if not iswalkable(x,y) then
    local sig=getsig(x,y)
    found=false
    --is 1 space gap btwn rooms
    if bcomp(sig,0b11000000,0b00001111) then
     x1,y1,x2,y2,found=x,y-1,x,y+1,true
    elseif bcomp(sig,0b00110000,0b00000000) then
     x1,y1,x2,y2,found=x+1,y,x-1,y,true
    end
    f1=flgs[x1][y1]
    f2=flgs[x2][y2]
    if found and f1!=f2 then
     add(drs,{x=x,y=y,f=f1,f2=f2})
    end
   end
  end)

	 if #drs>0 then
	  local d=getrnd(drs)
 	 add(doors,d)
   mset(d.x,d.y,1)
	  growflag(d.x,d.y,d.f)
   del(flaglib,d.f2)
	 end
 until #drs==0

end

function carvescuts()
 local x1,y1,x2,y2,found,cut,drs=1,1,1,1,false,0,{}

 repeat
  drs={}
  visbrd(function(x,y)
   if not iswalkable(x,y) then
    local sig=getsig(x,y)
    found=false
    --is 1 space gap btwn rooms?
    if bcomp(sig,0b11000000,0b00001111) then
     x1,y1,x2,y2,found=x,y-1,x,y+1,true
    elseif bcomp(sig,0b00110000,0b00000000) then
     x1,y1,x2,y2,found=x+1,y,x-1,y,true
    end

    if found then
     calcdist(x1,y1)
     if distmap[x2][y2]>20 then
      add(drs,{x=x,y=y})
     end
    end
   end
  end)

	 if #drs>0 then
	  local d=getrnd(drs)
	  if isdoor(d.x,d.y) then
 	  add(doors,d)
   end
   mset(d.x,d.y,1)
   cut+=1
	 end
 until #drs==0 or cut>=3
end

function fillends()
 local filled,tle
 repeat
 	filled=false

  visbrd(function(x,y)
   local tle=mget(x,y)
   if cancarve(x,y,true) and tle!=14 and tle!=15 then
    filled=true
    mset(x,y,2)
   end
  end)
 until not filled
end

function isdoor(x,y)
 local sig=getsig(x,y)
 if bcomp(sig,0b11000000,0b00001111) or bcomp(sig,0b00110000,0b00001111) then
  return nexttoroom(x,y)
 end
 return false
end

function nexttoroom(x,y,dirs)
 local dirs=dirs or 4
	for i=1,dirs do
	 if inbounds(x+dirx[i],y+diry[i]) and
	    roomap[x+dirx[i]][y+diry[i]]!=0 then
 	 return true
	 end
 end
 return false
end

function placedoors()
 for d in all(doors) do
  local dx,dy=d.x,d.y
  local m=mget(dx,dy)
  if (m==1 or m==62)
   and isdoor(dx,dy)
   and not bytile(dx,dy,13) then
   mset(dx,dy,13)
  end
 end
end

----------------
-- decoration
----------------

function startend()
 local high,low,px,py=0,9999

 repeat
  px,py=flr(rnd(16)),flr(rnd(16))
 until iswalkable(px,py)

 calcdist(px,py)
 visbrd(function(x,y)
  local tmp=distmap[x][y]
  if iswalkable(x,y) and tmp>high then
   px,py,high=x,y,tmp
  end
 end)

 calcdist(px,py)
 high=0
 visbrd(function(x,y)
  local tmp=distmap[x][y]
  if tmp>high and cancarve(x,y) then
   ex,ey,high=x,y,tmp
  end
 end)
 mset(ex,ey,14)

 visbrd(function(x,y)
  local tmp=distmap[x][y]
  if tmp>=0 then
   local score=starscore(x,y)
   tmp=tmp-score
	  if tmp<low and score>=0 then
	   px,py,low=x,y,tmp
	  end
  end
 end)

 --don't spawn mob with stairs
 if roomap[px][py]>0 then
  rooms[roomap[px][py]].nospawn=true
 end
 mset(px,py,15)
 p_mob.x,p_mob.y=px,py
end

function starscore(x,y)
 if roomap[x][y]==0 then
  if nexttoroom(x,y,8) then
   return -1
  end
  if freestanding(x,y)>0 then
   return 5
  end
  if cancarve(x,y) then
   return 0
  end
 else
  local src=freestanding(x,y)
  if src>0 then
   return src<=8 and 3 or 0
  end
 end
 return -1
end

function freestanding(x,y)
 return sigarray(
  getsig(x,y),
  free_sig,
  free_msk)
end

function bytile(x,y,tle)
 for i=1,4 do
  if inbounds(x+dirx[i],y+diry[i]) and mget(x+dirx[i],y+diry[i])==tle then
   return true
  end
 end
 return false
end

function prettywalls()
  visbrd(function(x,y)
   local tle=mget(x,y)
   if tle==2 then
    local ntle=sigarray(getsig(x,y),wall_sig,wall_msk)
    tle=ntle==0 and 3 or 15+ntle
    mset(x,y,tle)
   elseif tle==1 then
    if not iswalkable(x,y-1) then
     mset(x,y,62)
    end
   end
  end)
end

function decorooms()
 local baseopts=ints("1,1,70,69,68")
 local mx=2
 function plant(r,tx,ty,x,y)
  local opts=baseopts
  if mx>0 and rnd()<0.5 and x>0 and y>0 and x<r.w-1 and y<r.h-1 then
   opts=ints("81,82,83")
   mx-=1
  end
  mset(tx,ty,getrnd(opts))
 end

 function vase(r,tx,ty,x,y)
  local opts=baseopts
  if not bcomp(getsig(tx,ty),0,0b00001111) then
   opts=ints("1,70,68,7,7,8")
  end
  mset(tx,ty,getrnd(opts))
 end

 function shroom(r,tx,ty,x,y)
  local opts=baseopts
  if rnd()<0.33 then
   opts=ints("84,84,85,85,86,7")
  end
  mset(tx,ty,getrnd(opts))
 end

 local funcs,fn={plant,shroom},vase
 for r in all(rooms) do
  visit(function(x,y)
   if not bytile(r.x+x,r.y+y,13) and mget(r.x+x,r.y+y)==1 then
    fn(r,r.x+x,r.y+y,x,y)
    decotorch(r,r.x+x,r.y+y,x,y)
   end
  end,
  0,r.w-1,0,r.h-1)
  mx=2
  fn=getrnd(funcs)
 end
end

function decotorch(r,tx,ty,x,y)
 if y%2==0 or bytile(tx,ty,13) or iswalkable(tx,ty,'checkmobs') then
  return false
 end
 if x==0 then
  mset(tx,ty,64)
 elseif x==r.w-1 then
  mset(tx,ty,66)
 end
end

function placechests()
 local chestdice,rms,rare,place=ints("0,1,1,1,2,3"),{},true
 place=getrnd(chestdice)

 --make a copy or rooms as rms
 for r in all(rooms) do
  add(rms,r)
 end

 while place>0 and #rms>0 do
  local r=getrnd(rms)
  place-=1
  placechest(r,rare)
  rare=false
  del(rms,r)
 end
end

function placechest(r,rare)
 local x,y
 repeat
  x,y=r.x+rndint(1,r.w-2),
  r.y+rndint(1,r.h-2)
 until mget(x,y)==1
 mset(x,y,rare and 12 or 10)
end

__gfx__
000000000000000000000000007d700000000000000000000aaaaa0000aaa00000aaa00000000000000000000000000000a9a0000aaaaa000aaaaa0001111110
00000000001000000000000007ded7000000000000010000900000a00a000a000a000a000066600000aaa0006666666099aaa9a0900000a0900000a010000000
007007000000000000000000007d70000000000000000000009a90000a000a000a000a0006000600099a9a0060000060900000a0909aa0a0900000a010000000
000770000000100000000000b30b03b00000000000000000900000a000aaa00099aaa0a00666660009aaaa0060000060900900a09099a0a0900000a010000010
0007700000000000000000000b0b0b0000000000a110001090a9a0a00a99aa009a99aaa00000000009000900666666609aa0aaa0909aa0a0900009a010000110
00700700010000000000000000b3b00000000000aa1100a0900000a009aaaa0099aaaaa00666660009aaaa0000000000900000909099a0a0900099a010001110
00000000000001000000000030030030000000000aa1090099aaaaa0009aa000099aaa000666660009aaaa00666666609aaaaaa0909aa0a0900999a001111110
00000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03b0000000000000000003b0b3000000000003b010000000000b300000000000000b300000000000000330000003b000000000000003b000000b30000003b000
0330b33033333bb0333b03303b00bbb0bb3b03300000333000b33300333b000000033bb0333333b033b3333033333330bb333330333330003bb33bb000033b30
0003b33033bbb3303333b00000b333303333b00000033bb0003333003b33b000000333303bb33330bb33333033333330b333b330b33b30003333333000033330
000b3000300300000003b000000b30000003b00000033000000330000003b00000033000000b3030000bb00000033000003330000003b0000300003000033000
000b30000000000000033000010b30000003b000000b30000003b0000003b000000330300003300000033000000b3000000330000003b0000000000000033000
3003303000030300030b30000003300030033000000330300003b0000303300000033300030333000003b000000b3000300330000303300003000300000b3000
0003300030001030301330000003330003033000000330000003b0003003300000033000300330103003b030300b30300003303030033000303000100003b030
00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
0003b0000bb3bb000003b0300003300000033000033000000003300000003b00000b3000000330000003b000000330000003b000000330000003300000000000
030b300033333bb00003300000033bb033333000333bbb303333333033333330bbb33bb0bbb330000bb33330333333b01003333033bb333033b3300033bb3330
000b3000333033b00003b0000000b3b033bb0000b333333033333b30333b3330333333303333b00003333330333333300003333033333330b333b000333333b0
00033000b30003300003b0000000003000300000033000300003b0000000b3000003000000033000000330000003b00000033000000300300003300000033000
300b30003b0003300003b000100000000000000000000000000bb000001000000000000000033000000330003003b0000003b000000000000003300000033000
0003300033333330000b3030000030003003000003003000030b30003003000003003000030b300000033030030330000003b00003003000030b300003033000
000330000333330000033000000300300300001010030030300b30000030003000000300300b300003033000000330301003303030000300300b300030033030
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003b00000000000000bb000000000001003b00000033000000b30000003300000033b000bb30000000b30000000000000330000000330000300300010101010
0003bb303bbb333033bb30003333bb300003b000000333b0000b3000bbb330000000bb30b3300000300b333033333bb0333333303b3330001030030001010101
0000333033b3b33033b3000033bb3330000bb00000003bb000033000333300000000033033000000000333303bbb33303bbbb330333b30000000000010101010
00030300030010300300300003010000000b3000100003000003b000000300103000003030000030000330000003300000000000000330000000001001010101
00000000000000000000000000000000000b30000000000000333b0000000000bb00000000000330000330000003300000000000000b30000000000010101010
0000003003000300003000000103003000033000000003000033330030000000b33000000000b3300303b0000303300000303000000bb0000100000001010101
100303000030100003010300300030000003300100000030000330000303000003330000000333000003b00030033030010300100303b0000000010010101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101
07000100000001000000007000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000700000000000000600000007000000000000001001000000000000000000000000000000000000000000000000000000000000000000000000000000
c6000000c70000000100006c0100007c010000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000
aa000000aa000000000000aa000000aa0003000000000000000d0000000000000000000000000000000000000000000000000000000000000000000000000000
9000100090001000000000090000000900b0b0000030300000b0b000000000000000000000000000000000000000000000000000000000000000000000000000
90000000900000000000100900001009000b00001003000000030000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000007d700000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b0b00007ded7000b303b00000001000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000b0000007d700000b0b00010000000000d000000dd0000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b00300b0b30b03b0b30b03b0000d000000ddd0000dddd000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b030b000b0b0b000b0b0b0000ddd000000700000dddd000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b3b00000b3b00000b3b000000700001007000000770000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000300000003000000030010000700000007000000770010000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000300000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003330000333b0003333b0000333bb000333b3003333b0000033300000000000000000000000000000000000000000000000000000000000000000000000000
00033030033333b0033033b003333330033333b00333333000333300000000000000000000000000000000000000000000000000000000000000000000000000
00033333033000000330033033300000333000003330033003333b00000000000000000000000000000000000000000000000000000000000000000000000000
000033b3033003303333b330033b0000033b0000033003b003b33000000000000000000000000000000000000000000000000000000000000000000000000000
0000033b033b3330033033000b3333b003333bb00b3003300b330000000000000000000000000000000000000000000000000000000000000000000000000000
0000000030333300033003b000333330003333300bb00b3030000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003330003333bb000333b0003b00bb0003b3bb003333b0000033300000000000000000000000000000000000000000000000000000000000000000000000000
0003333003b333b0033333b0033003b0033333b0033033b000333000000000000000000000000000000000000000000000000000000000000000000000000000
000b333300033000333003300b300330333000000330033003300300000000000000000000000000000000000000000000000000000000000000000000000000
000033b3000330000330033303330330033b00003333b33003b30000000000000000000000000000000000000000000000000000000000000000000000000000
0000033b00033300033b3330033003300b3333b0033033000b330000000000000000000000000000000000000000000000000000000000000000000000000000
000000003003b000003333000300003000333330033003b030000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000300000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000333b0000333b0003000030033b3bb0000000000aaaa9900aa00aa000aaa99000000000000000000000000000000000000000000000000000000000
00000000033333b00333333003300330033333b0000000000a9aaa900aa00aa00aaaaaa090000000000000000000000000000000000000000000000000000000
000000000330000033300330033303303330000000000000000aa0000aaaaaa00aa0000000000000000000000000000000000000000000000000000000000000
0000000003300330033033b00b300330033b000000000009000aa00009aaaaa00aa9a00009000000000000000000000000000000000000000000000000000000
00333000033b33300b300330033003b00b3333b00000009a900aa0000aa00a9009aaaa909a900000000000000000000000000000000000000000000000000000
00333300303333000bb00b3003b00bb00333333000000009000a90000a90099000aaaaa009000000000000000000000000000000000000000000000000000000
00b33330000000000000000000000000000003000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000
00033b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000033b000333b0003b00bb000333b3003333b000000000000a9a9900aaaa9000aaaa90000000000000000000000000000000000000000000000000000000000
00000000033333b0033003b0033333b0033033b0000000000aaaaa900aaaaaa00aaaaa9000000000000000000000000000000000000000000000000000000000
00000000333003300b3003303330000003300330000000000aa000000aa00aa00aa00aa000000000000000000000000000000000000000000000000000000000
0000000003300333033b0330033b00003333b330000000000aa900000aa00a900aa00aa000000000000000000000000000000000000000000000000000000000
00000000033b33300033330003333bb003303300000000000aaaaa9009a00aa00aaaaaa000000000000000000000000000000000000000000000000000000000
00000000003333000003300000333330033003b00000000000aaaaa00a9009a009aaaa0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00000000c0000000000000c00000000c0c0000c0c000000000000000c0c000bb000000bb000000bb000000000000000cc0000000cc00000cc00000cc0000
00ccc000000cc000000c000000cc0000000ccc00000ccc00000c0c000000cc000bb730000bb730000bb7300000bb000000cccc0000ccccc000cccc000ccccc00
0ccccc0000cccc0000ccc0000cccc0000007c7c00007c7c0000ccc000007c7c000bb000000bb000000bb00000bb730000cc707c00cc707c00cc707c00ccc7070
cc7c7cc00c7c7cc00ccccc00cc7c7c0000cc0cc000cc0cc000c7c7c000cc0cc00c000b000c000b000c000b0000bb0000cccc0cc0cccc0cc0cccc0cc0ccccc0c0
ccc0ccc0ccc0ccc0cc7c7cc0ccc0ccc00ccccc000ccccc000ccc0cc00ccccc000cccc0000cccc0000cccc0000c000b00ccccccc0ccccccc0ccccccc0ccccccc0
ccccccc0ccccccc0ccc0ccc0ccccccc00cccc0000cccc0000cccc0000cccc000ccccc000cccc00000cccc000ccccc000cc0cccc0c0ccccc0cc0cccc0ccc0ccc0
0ccccc000ccccc000ccccc000ccccc000ccc0c000ccc0c0000cccc000ccc0c00cccc0000ccc000000ccc0000cccc00000cc0cc00000ccc000cc0cc000ccc0000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c000c00c00000c000000000c00000c00000c000000c00000000000000000c000c0cc0c00c0cc0c00c0cc0c0000000000bbbb0300bbbb3000bbbb03000000030
c07b70c00c000c000c000c000c000c00000ccc00000cc0000000c0000000cc000cccccc00cccccc00cccccc00c0cc0c0bb7b0030bb7b0030bb7b00300bbbb030
c0bbb0c0c07b70c0c0bbb0c0c0bbb0c00c0c0c000c0c0c00000ccc000c0cc00000c7c700007c7c0000c7c7000cccccc0bbbb0330bbbb0330bbbb0330bb7b0030
0c030c000cbbbc00c07b70c00c7b7c0000cc7c0000cc7c000c0c0c0000ccc7000b0cc0000b0cc0000b0cc00000c7c700000bb030000bb030000bb030bbbb0330
c03330c0000300000c333c00003330000c0ccc000c0ccc0000cc7c000c0ccc000bb000c00bb000c00bb000c00b0cc0c00b30bb000b30bb000b30bb00000bb000
0033300000333000c03330c000333000c0c0c0c0c0c0c0c00c0ccc00c0c0c0c0bbbbbb000bbbbb000bbbbb000bbb0b00bbb30bb0bbb30bb0bbb30bb00b30bbb0
000000000033300000000000000000000c0c00000c0c0000c0c0c0c00c0c0000bbbbb0000bbbb000000bbb000bbbb0000bbbbb000bbbbb000bbbbb00bbb3bbb0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccc00000ccc00000ccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
ccc0c000ccc0c000ccc0c0000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
ccccc050ccccc050ccccc005ccc0c005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000
ccc0c050ccc0c050ccc0c050ccccc050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
cccc0c00cccc0c00cccc00c0ccc0c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
ccccc000ccccc000ccccc000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000cc0500cccc0500ccc05000ccc0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888eeeeee888eeeeee888eeeeee888eeeeee888eeeeee888777777888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee88eee88ee888ee88ee888ee88ee8e8ee88ee888ee88ee8eeee88778887788888888888888888ff888ff888222222888222822888882282888888222888
888eeee8eee8eeeee8ee8eeeee8ee8eee8e8ee8eee8eeee8eee8eeee87777787788888e88888888888ff888ff888282282888222888888228882888888288888
888eeee8eee8eee888ee8eeee88ee8eee888ee8eee888ee8eee888ee8777778778888eee8888888888ff888ff888222222888888222888228882888822288888
888eeee8eee8eee8eeee8eeeee8ee8eeeee8ee8eeeee8ee8eee8e8ee87777787788888e88888888888ff888ff888822228888228222888882282888222288888
888eee888ee8eee888ee8eee888ee8eeeee8ee8eee888ee8eee888ee877777877888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee877777777888888888888888888888888888888888888888888888888888888888888888
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616161111611161161616161616161116111611171111171111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116661661166111611161166616161666161116111666171111171111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116111616161111611161111616661616161116111116171111171111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116111616166611611161166616661616166616661661117111711111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111116161666116616661666166111711eee1e1e1ee111ee1eee1eee11ee1ee1117116161111161611711111111111111111111111111111111111111111
1111111116161161161116161616161617111e111e1e1e1e1e1111e111e11e1e1e1e171116161111161611171111111111111111111111111111111111111111
1111111116161161166616611661161617111ee11e1e1e1e1e1111e111e11e1e1e1e171111611111166611171111111111111111111111111111111111111111
1111111116661161111616161616161617111e111e1e1e1e1e1111e111e11e1e1e1e171116161171111611171111111111111111111111111111111111111111
1111111111611666166116661616166611711e1111ee1e1e11ee11e11eee1ee11e1e117116161711166611711111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111eee1eee11111bbb11bb1bbb1bbb11711616111116161171111111111ccc11111eee1e1e1eee1ee1111111111111111111111111111111111111
11111111111111e11e1111111bbb1b111b1111b11711161611111616111717771777111c111111e11e1e1e111e1e111111111111111111111111111111111111
11111111111111e11ee111111b1b1b111bb111b117111161111116661117111111111ccc111111e11eee1ee11e1e111111111111111111111111111111111111
11111111111111e11e1111111b1b1b1b1b1111b117111616117111161117177717771c11111111e11e1e1e111e1e111111111111111111111111111111111111
1111111111111eee1e1111111b1b1bbb1bbb11b111711616171116661171111111111ccc111111e11e1e1eee1e1e111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111e1111ee11ee1eee1e111111116616661166111116661611166611111166166616661166166611661171161611111616117111111ccc1111
11111111111111111e111e1e1e111e1e1e11111116111161161111111161161116111777161116111161161111611611171116161111161611171111111c1111
11111111111111111e111e1e1e111eee1e111111166611611611111111611611166111111611166111611666116116111711116111111666111711111ccc1111
11111111111111111e111e1e1e111e1e1e111111111611611616117111611611161117771616161111611116116116161711161611711116111711711c111111
11111111111111111eee1ee111ee1e1e1eee1111166116661666171111611666166611111666166611611661166616661171161617111666117117111ccc1111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111eee11ee1eee1111166611111cc1111117171616166616111611111111661666116611111ee111ee11111111111111111111111111111111
11111111111111111e111e1e1e1e11111161177711c1111117771616161616111611111116111161161111111e1e1e1e11111111111111111111111111111111
11111111111111111ee11e1e1ee111111161111111c1111117171616166616111611111116661161161111111e1e1e1e11111111111111111111111111111111
11111111111111111e111e1e1e1e11111161177711c1117117771666161616111611111111161161161611111e1e1e1e11111111111111111111111111111111
11111111111111111e111ee11e1e1111166611111ccc171117171666161616661666166616611666166611111eee1ee111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111eee1eee1111166611661166166616661171116616661166111116161666161116111111116616661166177116661177111116161666
1111111111111111111111e11e111111161616111616166616161711161111611611111116161616161116111111161111611611171111611117111116161616
1111111111111111111111e11ee11111166116111616161616661711166611611611111116161666161116111111166611611611171111611117111116161666
1111111111111111111111e11e111111161616111616161616111711111611611616117116661616161116111111111611611616171111611117117116661616
111111111111111111111eee1e111111166611661661161616111171166116661666171116661616166616661666166116661666177116661177171116661616
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111666161116661111166611111cc11ccc111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111611611161117771161117111c11c11111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111611611166111111161177711c11ccc111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111611611161117771161117111c1111c111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111161166616661111166611111ccc1ccc111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111eee1eee1eee1eee1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111e1e1e1e1e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111ee11ee11ee11eee1ee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111e1e1e1e1e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111eee1e1e1eee1e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111eee1ee11ee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111ee11e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111eee1e1e1eee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111eee1e1e1eee1111111117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111117711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111bbb1bbb1bbb1bb11bbb17771171166616111666117111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111b1b1b1b11b11b1b11b117777111116116111611111711111111111111111111111111111111111111111111111111111111111111111111
11111111111111111bbb1bb111b11b1b11b117711711116116111661111711111111111111111111111111111111111111111111111111111111111111111111
11111111111111111b111b1b11b11b1b11b111171711116116111611111711111111111111111111111111111111111111111111111111111111111111111111
11111111111111111b111b1b1bbb1b1b11b11b1b1171116116661666117111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111eee1eee1111166616111666111111111ccc11111eee1e1e1eee1ee111111111111111111111111111111111111111111111111111111111
111111111111111111e11e11111111611611161117771777111c111111e11e1e1e111e1e11111111111111111111111111111111111111111111111111111111
111111111111111111e11ee11111116116111661111111111ccc111111e11eee1ee11e1e11111111111111111111111111111111111111111111111111111111
111111111111111111e11e111111116116111611177717771c11111111e11e1e1e111e1e11111111111111111111111111111111111111111111111111111111
11111111111111111eee1e111111116116661666111111111ccc111111e11e1e1eee1e1e11111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111116661611166611111bbb1b111bbb11711bbb1bb11bb111711ccc117111711111111111111111111111111111111111111111111111111111
111111111111111111611611161117771b111b111b1b17111b1b1b1b1b1b1711111c111711171111111111111111111111111111111111111111111111111111
111111111111111111611611166111111bb11b111bb117111bb11b1b1b1b171111cc111711171111111111111111111111111111111111111111111111111111
111111111111111111611611161117771b111b111b1b17111b1b1b1b1b1b1711111c111711171111111111111111111111111111111111111111111111111111
111111111111111111611666166611111b111bbb1b1b11711b1b1b1b1bbb11711ccc117111711111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111bbb11bb1bbb1bbb117116161111161611111666161116661171111111111111111111111111111111111111111111111111111111111111
11111111111111111bbb1b111b1111b1171116161111161611111161161116111117111111111111111111111111111111111111111111111111111111111111
11111111111111111b1b1bbb1bb111b1171111611111166611111161161116611117111111111111111111111111111111111111111111111111111111111111
11111111111111111b1b111b1b1111b1171116161171111611711161161116111117111111111111111111111111111111111111111111111111111111111111
11111111111111111b1b1bb11bbb11b1117116161711166617111161166616661171111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1ee11ee1117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e1e1e1e111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111ee11e1e1e1e111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e1e1e1e111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1e1e1eee117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888828282228222888282828222822288888888888888888888888888888888888882228282822282888882822282288222822288866688
82888828828282888888828288828282882882828882888288888888888888888888888888888888888882888282828882888828828288288282888288888888
82888828828282288888822282228222882882228822882288888888888888888888888888888888888882228222822282228828822288288222822288822288
82888828828282888888888282888282882888828882888288888888888888888888888888888888888888828882888282828828828288288882828888888888
82228222828282228888888282228222828888828222822288888888888888888888888888888888888882228882822282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000050505000303030103010307020205050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000000000000000000000000000202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000001010101010000010100000001010101010101010000000101000000010101010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001010100000000000000000000010101010101000000000000010000010101010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001010000000000000000000000010101010101000001010101010101010101010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001010100000000000001000001000101010100000101010101010101010101010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000013331133333333113314010000010001011011111111111111120000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001010020073e3e3e3e3e3e0e2201010000000010243e3e3e3e3e3e06220100000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000204501014601010145220000000000002003010101010125332e0000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000020010101014501010122000000000000301201010101013e3e231200000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000204053010601450142220000000000003e3a33332701010101032000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000002045010101460101012201000000010010243e3e3e01010101133200000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000200701010101010107220100000000002003010101012533332e3e00000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000303131120101103131320000000000003012010101013e3e0f220000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000100013e3e3e200f45223e3e3e0000010100013e3031313131313131320001010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001010100000023313124000001000101010101013e3e3e3e3e3e3e3e3e0001010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000101010100003e3e3e3e000000010101010101010000000100000000000101010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001010101000000000000000001010101010101010000000000000000010101010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011600000217502705021150200002135000000210402104021250000002105000000215500000000000211401175017050111500105011350010500105001050112500105001050010501135001000000000000
01160000215101d510195251a535215351d520195151a5152151221515215252252521525215150e51511515205141c510195251c535205351c520195151c5152051220515205252152520525205150d51510515
0116000000000215101d510195151a515215151d510195151a5152151221515215152251521515215150e51511515205141c510195151c515205151c510195151c5152051220515205152151520515205150d515
01160000150051d00515015150151a0251a0151d0151d015220252201521025210151d0251d0151502515015140201402214025140151400514004140050d000100140c0100d0201003014030150201401210015
011600000217502705021150200002135000000000000000021250000000000000000215500000000000211405175001050511500105051350010500105001050512500105001050010505135000000000000000
01160000215141d510195251a525215251d520195151a5152151221515215202252021525215150e52511515205141d5101852519525205251d520185151951520512205151c5201d52020525205151052511515
0116000000000215141d510195151a515215151d510195151a5152151221515215102251021515215150e51511515205141d5101851519515205151d510185151951520512205151c5101d510205152051510515
01160000000002000015015150151a0251a0151d0251d015220252201521015210151d0251d01526015260152502025012250152501518000000000000000000100000d02011030140401505014040190301d010
011600000717502005071150200007135000000000000000071250000000000000000715500000000000711403175001050311500105031350010500105001050312500105001050010503155000000000000000
01160000091750200509115020000913500000000000000009125000000000000000091550000000000091140a175001050a115001050a1250010504105001050a125001050910500105041350c1000912500100
01160000225121f5201a5251f515225251f5201a5151f515215122151222525215251f5251f5150e52513515225141f5101b5251f525225251f5201b5151f515215122151222525215251f5251f5150f52513515
01160000215141c510195251d515215251c520195151d5152151222510215201f51021512215150d52510515205141d5101a52516515205151d5201a5151651520522205151d515205251f5251d5151c52519515
0116000000000225121f5101a5151f515225151f5101a5151f515215122151222515215151f5151f5150e51513515225141f5101b5151f515225151f5101b5151f515215122151222515215151f5151f5150f515
0116000000000215141c510195151d515215151c510195151d5152151222510215101f51021510215150d51510515205141d5101a51516515205151d5101a5152051520510205151d515205151f5151d5151c515
01160000000000000022015220151f0251f0151a0151a01522025220151f0151f01519020190221a0251a0151f0201f0221f0151f01518000000000000000000000000f010130201603015030160321502013015
011600001902519015220252201521015210151c0251c015220252201521025210151c0221c0151d0251d01520020200222001520015110051a0151d015220152601226012280102601625010250122501025015
011600000217509035110150203502135090351101502104021250000002105000000212511035110150211401175080351001501035011350803510015001050112500105001050010501135100351001500000
0116000002175090351101502035021350903511015021040212500000021050000002155110351101502114051750c0351401505035051350c03514015001050512500105001050010505135140351401500000
01160000071750e0351601507035071350e0351601502104071250000002105000000715516035160150711403175160351301503035031351603513015001050312500105001050010503135160351601500000
0116000009175100351101509035091351003511015021040912500000021050000009155100350d015091140a17510035110150a0350a1351003511015001050a12500105001050010509135150350d01509020
0116000002215020451a7051a7050e70511705117050e7050e71511725117250e7250e53511535115450e12501215010451a6001a70001205012051a3001a2001071514725147251072510535155351554514515
0116000002215020451a7051a7050e70511705117050e7050e71511725117250e7250e53511535115450e12505215050451a6001a70001205012051a3001a2001171514725147251172511535195351954518515
0116000007215070451a7051a7050e70511705117050e705137151672516725137251353516535165451312503215030451a6001a70001205012051a3001a2001371516725167250d7250f535165351654513515
0116000009215090451a7051a7050e70511705117050e7050d715157251572510725115351653516545157250a2150a0451a6001a70001205012051a3001a2000e71510725117250e7250d5350e5351154510515
0116000021005210051d00515015150151a0151a0151d0151d015220152201521015210151d0151d01515015150151401014012140151401518000000000000000000100100c0100d01010010140101501014010
0116000000000000002000015015150151a0151a0151d0151d015220152201521015210151d0151a01526015260152501019015190151900518000000000000000000000000d0101101014010150101401019010
0116000000000000000000022015220151f0151f0151a0151a01522015220151f0151f01519010190121a0151a0151f0101f012130151300518000000000000000000000000f0101301016010150101601215010
01160000190051901519015220152201521015210151c0151c015220152201521015210151c0121c0151d0151d015200102001220015200051d0051a015220152901029012260102801628010280122801528005
01160000097140e720117300e730097250e7251173502735057240e725117350e735097450e7401174002740087400d740107200d720087350d7351072501725047240d725107250d725087350d7301074001740
01160000097240e720117300e730097450e745117350e735117240e725117350e735097450e740117400e740087400d740117200d720087350d735117250d725117240d725117250d725087350d730117400d740
011600000a7240e720137300e7300a7450e745137350e735137240e725137350e7350a7450e740137400e7400a7400f740137200f7200a7350f735137250f725137240f725137250f7250a7350f730137400f740
0116000010724097201073009730107450974510735097351072409725107350973510745097401074009740117400e740117200e720117350e735117250e725117240e725117250e725097350d730107400d740
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0113000029700297002670026700257002570022700227000000026700217000e7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000255011555165501555016555115550d5500a5500e5500e5520e5520e5521400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300001170015700197001a700117001670019700197001a7001a70025700257002570025700257002570025700197021970219702000000000000000000000000000000000000000000000000000000000000
001300000d2200c2200b220154000000000000000000000029720287302672626745287402173029720217322673026732267350210526702267020e705021050000000000000000000000000000000000000000
0113000000000000000000000000000000000000000000000e1100d1200a1300e1350d135091000a120091300e1220e1200e1200e1000e1020e10200000000000000000000000000000000000000000000000000
0113000000000000000000000000000000000000000000000a14300000000000a060090600a000090000900002072020720207202005020020200500000000000000000000000000000000000000000000000000
011200001b0001f0002200023000220001f0002000022000230002700023000200001f000200001f0001b0001f00022000200002200023000270001d000200001f0001f0001f0001f00000000000000000000000
011200001f5001f5001b5001b50022500225002350023500225002250020500205001f5001f500205002050022500225002350023500255002550023500235002250022500225002250000000000000000000000
01120000030000300003000130000700007000080000800008000170000b0000b0000a0000a0000a0000f00003000030000800008000080001100005000050000300003000030000300003000030000300000000
011200001e0201e0201e032210401a0401e0401f0301f0321f0301f0301e0201e0201f0201f020210302103022030220322902029020290222902228020280202602026020260222602200000000000000000000
011200001a7041a70415534155301a5321a5301c5401c5401c5451a540155401554516532165301a5301a5351f5401f54522544225402254222545215341f5301e5441e5401e5421e54500000000000000000000
01120000110250e000120351500015045150000e0550e00512045150051503515005130251500516035260051a0452100513045210051604526005100251f0050e0500e0520e0520e0500c000000000000000000
0002000031530315302d500315003b5303b5302e5000050031530315302e5002d50039530395302d5000050031530315303153031530315203152000500005000050000500005000050000500005000050000500
000100003101031010300102f0102d0202c0202a02028030270302503023050210501e0501d0501b05018050160501405012050120301103011010110100e0100b01007010000000000000000000000000000000
00010000240102e0202b0202602021010210101a01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000024010337203372033720277103a7103a71000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000096201163005620056150160000600006001160011600116001160001620006200a6100a6050a6000a6000f6000f6000f6000f6000060000600026100261002615016000160005600056000160001600
00010000145201a520015000150001500015000150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000211102114015140271300f6300f6101c610196001761016600156100f6000c61009600076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100001b61006540065401963018630116100e6100c610096100861000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f5302b5302e5302e5303250032500395002751027510285102a510005000050000500275102951029510005000050000500005002451024510245102751029510005000050000500005000050000500
0001000024030240301c0301c0302a2302823025210212101e2101b2101b21016210112100d2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100020000200
0001000024030240301c0301c03039010390103a0103001030010300102d010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000210302703025040230301a030190100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000d720137200d7100c40031200312000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00424344
01 00031843
00 04071947
00 080e1a4e
00 090f1b4f
00 10010243
00 11050647
00 120a0c4e
00 130b0d4f
00 001c0344
00 041d0744
00 081e0e44
00 091f0f44
00 00145c44
00 04155d44
00 08165e44
02 13175f44
00 41424344
00 41424344
00 41424344
00 41424344
00 68696744
04 2a2b2c44
00 6d6e6f44
04 30313244

