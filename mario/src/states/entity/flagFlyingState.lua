flagFlyingState = Class{__includes = BaseState}


function flagFlyingState:init(flag)
    self.flag = flag
    self.flagColor = math.random(1, 4) * 3 + 4
    self.animation = Animation {
        frames = {self.flagColor, self.flagColor + 1, self.flagColor + 2},
        interval = 0.5
    }
    self.flag.currentAnimation = self.animation
end

function flagFlyingState:update(dt)
    self.flag.currentAnimation:update(dt)
end