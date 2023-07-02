#!/usr/bin/env lua
-- <!--- vim : set filetype=lua et sts=2 sw=2 ts=2 : --->
local l=dofile("../lua/lib.lua")
local the,help = l.settings [[

templates: what does it do
(c) 2023 Tim Menzies <timm@ieee.org> BSD-2
  
USAGE: ./template [OPTIONS] [-g ACTIONS]
  
OPTIONS:
  -f  --file    data file                          = ../data/auto93.csv
  -g  --go      start-up action                    = nothing
  -h  --help    show help                          = false
  -s  --seed    random number seed                 = 93716221]]

local o, obj, oo, rnd =  l.o, l.obj, l.oo, l.rnd
-- ## Demos
local egs={all= {"the"}}

function egs.the() oo(the) end

-------------------------------------------------------------------------------
-- ## Start-up
if   not pcall(debug.getlocal,4,1) 
then the=l.cli(the, help); l.run(the,egs) end
return {COL=COL, COLS=COLS, DATA=DATA, NUM=NUM, SYM=SYM}
