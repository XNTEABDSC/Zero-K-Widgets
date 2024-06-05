-- tables {} are the main element to store information in Lua
-- widget is a table (a box containing pair of key = value) similar to any other table
local version = 0.1
function widget:GetInfo() -- this is a method, pretty much like a function with an hidden parameter (self) refering to the table where the function is stored
    -- this method will return a table whenever it is called, widget:GetInfo()
    return {
        name      = "Area Select",
        desc      = "select units by class around cursor, sample widget for learning, ver " .. version ,
        author    = "Helwor",
        date      = "Dec 2022",
        license   = "free",
        layer     = 0, -- the layer is the position in which this widget will be loaded compared to other widget's layer, layer can be negative
        enabled   = false,  --  loaded by default?
        -- handler   = true, -- to have access to the real widgetHandler, we don't need it in this case
    }
end
 
local debugNames = false -- set this to true to reveal the names of units in the console
local debugKey = false -- set this to true if you want to reveal in console which key code correspond to the key pressed
 
 
-- any widgets got access to some global variable, we used to declare local variable  to access those globals in order to access them faster during runtime
-- we localize the following needed functions
 
local spGetMyTeamID = Spring.GetMyTeamID
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitDefID = Spring.GetUnitDefID -- each unit got a unique defID that tell which unit type they are, 
local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay
local spSelectUnitMap = Spring.SelectUnitMap
local spValidUnitID = Spring.ValidUnitID
local spGetUnitIsDead = Spring.GetUnitIsDead
local spGetUnitPosition = Spring.GetUnitPosition
local min = math.min
local max = math.max
local UnitDefs = UnitDefs
 
local Echo = Spring.Echo -- this is used for debugging, calling Echo('Hello') will write 'Hello' in the infolog and on the console log ingame
 
-- following will be used for drawing
local glLineWidth = gl.LineWidth
local glLineStipple = gl.LineStipple
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glDrawGroundCircle = gl.DrawGroundCircle
local glColor = gl.Color
local glText = gl.Text
--
 
-- we create a table as a catalog of names stored for each classe
-- NOTE: those are my own definition which might not be adequat for you, so you might want to change it
-- NOTE: you could create another class called 'scout' to differentiate scout from raider
local unitClasses = {
    raider = {
        --planefighter = true,
 
        shipscout = true,
        shiptorpraider = true,
        spiderscout = true,
        shieldscout = true,
        cloakraid = true,
        shieldraid = true,
        vehraid = true,
        amphraid = true,
        vehscout = true,
        jumpraid = true,
        hoverraid = true,
        subraider = true,
        tankraid = true,
        gunshipraid = true,
        gunshipemp = true,      
        jumpscout = true,
        tankheavyraid = true,
 
    },
    skirm = {
        cloakskirm = true,
        spiderskirm = true,
        jumpskirm = true,
        shieldskirm = true,
        shipskirm = true,
        amphfloater = true,
        vehsupport = true,
        gunshipskirm = true,
        shieldfelon = true,
        hoverskirm = true,
        hoverdepthcharge = true,
    },
    riot = {
        amphimpulse = true, 
        cloakriot = true,
        shieldriot = true,
        spiderriot = true,
        spideremp = true,
        jumpblackhole = true,
        vehriot = true,
        tankriot = true,
        amphriot = true,
        shiptorpraider = true,
        hoverriot = true,
        gunshipassault = true,
        shipriot = true,
        striderdante = true,
    },
    assault = {
        jumpsumo = true,
        cloakassault = true,
        spiderassault = true,
        tankheavyassault = true,
        tankassault = true,
        shipassault = true,
        amphassault = true,
        vehassault = true,
        shieldassault = true,
        jumpassault = true,
        hoverassault = true,
        hoverheavyraid = true,
        --shipassault = true,
        --bomberprec = true,
        --bomberheavy = true,
        gunshipkrow = true,
        striderdetriment = true,
    },
    arty = {
        cloakarty = true,
        amphsupport = true,
        striderarty = true,
        shieldarty = true,
        jumparty = true,
        veharty = true,
        tankarty = true,
        spidercrabe = true,
        shiparty = true,
        shipheavyarty = true,
        shipcarrier = true,
        hoverarty = true,
        gunshipheavyskirm = true,
        tankheavyarty = true,
        vehheavyarty = true,
    },
    special1 = {
        cloakheavyraid = true,
        vehcapture = true,    
        spiderantiheavy = true,   
        shieldshield = true,
        cloakjammer = true,
        --planescout = true,
    },
    special2 = {
        gunshiptrans = true,    
        shieldbomb = true,
        cloakbomb = true,
        gunshipbomb = true,
        jumpbomb = true,
        gunshipheavytrans = true,
        subtacmissile = true,
        spiderscout = true,
        amphtele = true,
        --bomberdisarm = true,
        striderantiheavy = true,
        striderscorpion = true,
    },
    special3 = {
        cloaksnipe = true,
        amphlaunch = true,
        --planescout = true,
    },
    aa = {
        gunshipaa = true,
        shieldaa = true,
        cloakaa = true,
        vehaa = true,
        hoveraa = true,
        amphaa = true,
        spideraa = true,
        jumpaa = true,
        tankaa = true,
        shipaa = true,
    },
    con = {
        amphcon = true,
        planecon = true,
        cloakcon = true,
        spidercon = true,
        jumpcon = true,
        tankcon = true,
        hovercon = true,
        shieldcon = true,
        vehcon = true,
        gunshipcon = true,
        shipcon = true,
        --planecon = true,
        striderfunnelweb = true,
    },
 
}
-- this catalog is like this for the purpose of the user to edit it easily
-- but in order to do the less work possible during runtime, we find out which defID correspond to which unit type and store them in a table
-- for this we use a for loop that will iterate through the table unitClasses, giving us each pair name of class = class table
-- and we iterate each of those class table to get names in it
-- in that way we know which name belong to which class, and we note their defID in another table called classByDefID
-- defID are unique identifiers for each unit type, they are part of the unit definitions, those defs are stored in globals UnitDefs and UnitDefNames
-- this table will make it pretty fast to check which unit belong to which class during runtime
--, as we will just have to ask Spring to give us the defID of the unit and we will know immediately which class is it thanks to this table
local classByDefID = {}
for className,classTable in pairs(unitClasses) do
    for unitName in pairs(classTable) do
        if UnitDefNames[unitName] then
            local defID = UnitDefNames[unitName].id
            classByDefID[defID]=className
        else
            Echo(unitName .. ' not found')
        end
    end
end
-- once that table is done, we don't need anymore the unitClasses table
unitClasses = nil
 
-- here we define for which keys belong which class
-- name of class here must correspond exactly to name of class in unitClasses
-- NOTE: put your own hotkeys and complete this, not all class are mentionned
-- N_1... represent '1' in main part of US keyboard
local myHotkeys = {
    N_1 = 'raider',
    N_2 = 'skirm',
    N_3 = 'riot',
    N_4 = 'assault',
    N_5 = 'arty',
    N_6 = 'aa'
}
 
-- now we gonna translate those hotkeys into char code through a loop, because when we get called in via KeyPress, we receive char code
-- for this we need to use KEYSYMS table which is a table of translation human->char code and is written in another lua file
-- including this file in our code will give us the table KEYSYMS
include('keysym.lua')
 
-- now we create a table containing paired char code = class name, in the same manner we did for defID of classes earlier
local myHotkeyCodes = {}
 
for key,class in pairs(myHotkeys) do
    local code = KEYSYMS[key]
    if code then
        myHotkeyCodes[code] = class
    else
        Echo(key ..  'is not known in KEYSYMS')
    end
end
-- once done, we can get rid of myHotkeys
myHotkeys = nil
 
-- setting up color for classes
-- I set a bunch of colors I use myself there
local colors = {
     white          = { 1.0,    1,    1, 1.0 },
     black          = { 0.0,    0,    0, 1.0 },
     grey           = { 0.5,  0.5,  0.5, 1.0 },
     red            = { 1.0, 0.25, 0.25, 1.0 },
     darkred        = { 0.8,    0,    0, 1.0 },
     lightred       = {   1,  0.6,  0.6, 1.0 },
     magenta        = { 1.0, 0.25,  0.3, 1.0 },
     rose           = { 1.0,  0.6,  0.6, 1.0 },
     bloodyorange   = { 1.0, 0.45,    0, 1.0 },
     orange         = { 1.0,  0.7,    0, 1.0 },
     darkgreen      = { 0.0,  0.6,    0, 1.0 },
     green          = { 0.0,    1,    0, 1.0 },
     lightgreen     = { 0.5,    1,  0.5, 1.0 },
     lime           = { 0.5,    1,    0, 1.0 },
     blue           = { 0.3, 0.35,    1, 1.0 },
     turquoise      = { 0.3,  0.7,    1, 1.0 },
     lightblue      = { 0.7,  0.7,    1, 1.0 },
     yellow         = { 1.0,    1,  0.3, 1.0 },
     cyan           = { 0.3,    1,    1, 1.0 },
     brown          = { 0.9, 0.75,  0.3, 1.0 },
     purple         = { 0.9,    0,  0.7, 1.0 },
     softviolet     = { 1.0, 0.25,    1, 1.0 },
     violet         = { 1.0,  0.4,    1, 1.0 },
}
-- here you can set different color for each class
local classColor = {
    raider = colors.yellow,
    skirm = colors.cyan,
    riot = colors.red,
    assault = colors.orange,
    arty = colors.green,
    aa = colors.lightblue,
    con = colors.white,
    special1 = colors.brown,
    special2 = colors.rose,
    special3 = colors.turquoise,
}
 
 
------------------
----- PROCESSING
----- we have set every static info, now the dynamic part
-----------------
 
-- variables 
local myTeamID = Spring.GetMyTeamID() -- our team ID can change during the game
local classCalled = false -- the class name called by press of key 
local mySelection = {} -- table storing the units we gonna select
local radius = 650 -- radius of area
local x,y,z = 0,0,0 -- position of mouse in the world
local vsx, vsy -- size of game window
 
---------- updating teamID
local MyNewTeamID = function()
    myTeamID = Spring.GetMyTeamID()
end
-- all those callin will run the same function that update our team ID
widget.TeamChanged = MyNewTeamID
widget.PlayerChanged = MyNewTeamID
widget.Playeradded = MyNewTeamID
widget.PlayerRemoved = MyNewTeamID
widget.TeamDied = MyNewTeamID
----------
 
 
 
-- we make two separate function, one for gathering the units under our area of cursor, the other to effectively select the units
local UpdateFutureSelection = function()
    -- collecting units in area
    local mx,my = spGetMouseState() -- we get the coords of the mouse on screen
    local _,pos = spTraceScreenRay(mx,my,true,false,false,false) -- translate the screen position into world position
    if not pos then
        return
    end
    x,y,z = pos[1],pos[2],pos[3]
    local units = spGetUnitsInCylinder(x,z,radius,myTeamID)
    -- we keep only units that are of the chosen class
    for i,id in ipairs(units) do
        if spValidUnitID(id) and not spGetUnitIsDead(id) then
            if not mySelection[id] then
                local defID = spGetUnitDefID(id)
                if classByDefID[defID] == classCalled then
                    mySelection[id] = true
                end
                if debugNames then
                    Echo(id,'unit name: '..UnitDefs[defID].name)
                end
            end
        end
    end
end
local Select = function()
    for id in pairs(mySelection) do
        if not spValidUnitID(id) or spGetUnitIsDead(id) then
            mySelection[id] = nil
        end
    end
    if next(mySelection) then
        spSelectUnitMap(mySelection)
    end
end
 
 
-- the Engine Spring will call us when a key is pressed if we declare the method KeyPress
-- same for release with KeyRelease
-- that way we can do some work if we recognize our hotkey has been pressed
function widget:KeyPress(key,mods,isRepeat)
    if isRepeat then
        return
    end
    if debugKey then
        Echo('key pressed: '.. key)
    end
    classCalled = myHotkeyCodes[key]
    if classCalled then
        mySelection = {}
        UpdateFutureSelection()
        return true -- returning true on this will block the normal action of that key
    end
end
 
function widget:KeyRelease(key,mods)
    if classCalled then
        Select()
        classCalled = false
    end
end
 
-- changing the radius of area with mouse wheel
function widget:MouseWheel(up,value)
    if not classCalled then
        return
    end
    if up then
        radius = min(3000, radius*(1+0.1*value))    
    else
        radius = max(40, radius*(1+0.1*value))      
    end
    return true
end
 
 
 
 
-- Update call-in is called everytime the game is redrawn (afaik), we use this call in to recheck which units fall into our area around the cursor
function widget:Update()
    if not classCalled then
        return
    end
    UpdateFutureSelection()
end
 
 
-- DRAWING
-- in DrawScreen and DrawWorld call-in, we can run some drawing function
function widget:DrawWorld()
    if not classCalled then
        return
    end
    glColor(classColor[classCalled] or colors.white)
    glLineStipple(true)
    glLineWidth(1.5)
    -- draw the circle of area selection
    glPushMatrix()
    glDrawGroundCircle(x, y, z, radius, 40) -- draws a simple circle on the ground.
    glPopMatrix()
    -- draw little circles around each unit about to get selected
    for id in pairs(mySelection) do
        if spValidUnitID(id) and not spGetUnitIsDead(id) then   
            local ux,_,uz,_,uy = spGetUnitPosition(id,true)
            glPushMatrix()
            glDrawGroundCircle(ux, uy, uz, 40, 40)
            glPopMatrix()
        else
            mySelection[id] = nil
        end
    end
    -- after drawing round, we set everything to default
    glLineWidth(1)
    glColor(1,1,1,1)
    glLineStipple(false)
end
function widget:GetViewSizes(x,y)
    vsx,vsy = x,y
end
 
function widget:DrawScreen()
    if not classCalled then
        return
    end
    glColor(classColor[classCalled] or colors.white)
    glText(classCalled, vsx/2 - 100,150, 25)
    glColor(1,1,1,1)
end
 
 
 
-- this call-in is called once at the loading sequence of all widgets
function widget:Initialize()
    vsx,vsy = Spring.GetViewSizes()
end
 
 
-- memorize the radius size over games
 
function widget:SetConfigData(data)
    if not data.area_select_radius then
        return
    end
    -- update 'radius' with saved value
    radius = data.area_select_radius
end
 
function widget:GetConfigData()
    -- save the radius value on widget exit
    return {area_select_radius = radius}
end