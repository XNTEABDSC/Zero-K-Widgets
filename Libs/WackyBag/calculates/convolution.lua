if WG.WackyBag.calculates.convolution==nil then
    local convolution={}
    WG.WackyBag.calculates.convolution=convolution


    local function GenConvolutionMatGauss2(sigma)
        local function GaussFn2D(x,y)
            return 1/(math.pi*2*sigma*sigma)*math.exp(-(x*x+y*y)/(2*sigma*sigma))
        end
        -- lazy:)
        local p0=GaussFn2D(0,0)
        local p1=GaussFn2D(0,1)
        local p2=GaussFn2D(1,1)
        local sum=p0+p1*4+p2*4
        p0=p0/sum
        p1=p1/sum
        p2=p2/sum
        return {
            {p2,p1,p2},
            {p1,p0,p1},
            {p2,p1,p2}
        }
    end
    convolution.GenConvolutionMatGauss2=GenConvolutionMatGauss2

    local function Convolution_Mat2(Grid,GridWidth,GridHeight,Mat)
        local function ValidPos(x,z)
            return x>=1 and x<=GridWidth and z>=1 and z<=GridHeight
        end

        local Near1=Mat[2][1]/Mat[2][2]
        local Near2=Mat[1][1]/Mat[2][2]
        
        local function GetMCOrSim(x,z)
            if ValidPos(x,z) then
                return Grid[x][z].mc
            end
            local XDiff,ZDiff=0,0
            if x<=0 then
                XDiff=1-x
                x=1
            end
            if x>GridWidth then
                XDiff=x-GridWidth
                x=GridWidth
            end
            if z<=0 then
                ZDiff=1-z
                z=1
            end
            if z>GridHeight then
                ZDiff=z-GridHeight
                z=GridHeight
            end
            if XDiff>ZDiff then
                local t=XDiff
                XDiff=ZDiff
                ZDiff=t
            end
            
            return Grid[x][z].mc*(Near1^(ZDiff-XDiff))*(Near2^(XDiff))
        end
        local newGrid={}
        for x = 1, GridWidth do
            local newLine={}
            newGrid[x]=newLine
            for z = 1, GridHeight do
                local newmc=0
                for nx = -1, 1 do
                    for nz = -1, 1 do
                        newmc=newmc+GetMCOrSim(nx+x,nz+z)*Mat[nx+2][nz+2]
                    end
                end
                newLine[z]=newmc
            end
        end
        return newGrid
        
    end
    convolution.Convolution_Mat2=Convolution_Mat2
end

return WG.WackyBag.calculates.convolution