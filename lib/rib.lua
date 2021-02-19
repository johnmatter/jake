Rib = {}
Rib.__index = Rib

-- copy constructor
function Rib:create(r)
    local rib = {}
    setmetatable(rib,Rib)
    rib.x = r.x
    rib.y = r.y
    rib.note = r.note
    rib.brightness = r.brightness
    return rib
end

-- draw rib, with default brightness 3
function Rib:draw(brightness)
    g:led(self.x, self.y, brightness or self.brightness)
end
