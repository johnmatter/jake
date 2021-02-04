Rib = {}
Rib.__index = Rib

-- copy constructor
function Rib:create(r)
    local rib = {}
    setmetatable(rib,Rib)
    rib.x = r.x
    rib.y = r.y
    rib.note = r.note
    return rib
end

-- draw rib, with default brightness 3
function Rib:draw(brightness)
    if self:is_initialized() then
        g:led(self.x, self.y, brightness or 3)
    end
end

function Rib:is_initialized()
    return_value = false
    if (self.x~=nil and self.y~=nil) then
        return_value = true
    end
    return return_value
end
