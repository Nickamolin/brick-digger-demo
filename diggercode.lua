-- game code --

function spawnBrick(brickIndex)

    bricks[brickIndex] = {x = brickSpawnX, y = brickSpawnY, health = flr(rnd(8)) + 1, points = 0}

    bricks[brickIndex].points = bricks[brickIndex].health

    bricks[brickIndex].numTag = 0
    bricks[brickIndex].tag = ""

    brickSpawnX += brickSize

    if brickSpawnX > 127 then
        brickSpawnX = 0
        brickSpawnY += brickSize

        if gameStarted then
            sfx(1)
        end
    end

end

function _init()
    -- game started
    gameStarted = false

    screenSize = 128

    xButtonPressed = false
    oButtonPressed = false

    -- set up world attributes
    gravity = 0.2
    bounceMultiplier = 0.9
    timeMultiplier = 1
    friction = 0.7
    minBounceSpeed = 0

    brickSize = 16
    ballSize = 6
    tileSize = 8
    ballBuffer = (tileSize - ballSize) / 2

    maxSpeed = 16
    maxCharge = maxSpeed
    availableCharge = maxCharge / 4 - 0.1
    rechargeRate = 0.15
    charging = false
    defaultChargeRate = 0.6
    chargeRate = defaultChargeRate
    horizontalCharge = 0
    verticalCharge = 0

    -- set up player
    player = {x = screenSize/2 - tileSize/2, y = screenSize/2 - tileSize/2}
    player.trail = {{x = player.x, y = player.y} , {x = player.x, y = player.y}}

    player.speed = {x = 0, y = 0}

    player.damage = 0

    player.flame = 0

    score = 0

    square = false

    -- set up bricks
    bricks = {}

    numSections = 2
    maxBricksOnScreen = 20
    maxBricks = numSections * maxBricksOnScreen

    brickSpawnX = 0
    brickSpawnY = 128

    for i = 1, maxBricks do
        -- bricks[i] = {x = brickSpawnX, y = brickSpawnY, health = flr(rnd(7)) + 1}

        -- brickSpawnX += brickSize

        -- if brickSpawnX > 127 then
        --     brickSpawnX = 0
        --     brickSpawnY += brickSize
        -- end

        spawnBrick(i)
    end

    worldBottom = brickSpawnY - 1

    -- set up flame particles
    numParticles = 32
    currentParticleIndex = 1

    particles = {}

    for i = 1, numParticles do 
        particles[i] = {x = 0, y = 0, speed = {x = 0, y = 0}, color = player.flame}
    end

    -- set up power ups (PUs)

    powerUpCount = 0
    powerUps = {}
    powerUpDuration = 30

    scoreMultiplier = 1
    maxDamage = false

    powerUpSpawnChance = 16 -- higher, the rarer they get, cant be less then 5

    numPUParticles = 16
    currentPUParticleIndex = 1

    PUparticles = {}

    for i = 1, numPUParticles do 
        PUparticles[i] = {x = -2, y = -2, speed = {x = 0, y = 0}, color = 8}
    end

    -- render effects

    flashCurrentFrame = 0
    flashFrameLength = 8
    flashOn = false

    -- set up title screen

    titleShow = true
    titleFlash = true
    
    titleCounter = 1
    titleAnimationRate = 15
    gameTimeStart = 0
    titleFlashDuration = 5

    arrowBuffer = 0

    tinyBrickPicker = 0

end

-- power up types:
--          0: 2x score multiplier
--          1: 4x score multiplier
--          2: maxCharge

function handle_title_screen()

    if gameStarted == false then
        gameTimeStart = time()
    else
        titleShow = false
    end

    if time() - gameTimeStart < titleFlashDuration then
        titleCounter += 1

        if titleCounter > titleAnimationRate then
            titleCounter = 1

            tinyBrickPicker = flr(rnd(8))

            if arrowBuffer == 0 then
                arrowBuffer = 1
            else
                arrowBuffer = 0
            end

            if titleFlash == true then
                titleFlash = false
            else
                titleFlash = true
            end
        end
    else
        titleShow = false
        titleFlash = false
    end

end

function spawn_power_up(inputX, inputY, inputType)
    powerUpCount += 1

    powerUps[powerUpCount] = {x = inputX, y = inputY, type = inputType, sitting = true, active = false, startTime = 0}

    -- if powerUps[powerUpCount].type == 2 then

    --     powerUps[powerUpCount].numParticles = 16
    --     powerUps[powerUpCount].currentParticleIndex = 1

    --     powerUps[powerUpCount].particles = {}

    --     for i = 1, powerUps[powerUpCount].numParticles do 
    --         powerUps[powerUpCount].particles[i] = {x = 0, y = 0, speed = {x = 0, y = 0}}
    --     end
    -- end
end

function handle_power_ups() 

    -- set bounds for collision detection
    playerLeft = player.x + tileSize/2 - ballSize/2
    playerRight = player.x + tileSize/2 + ballSize/2
    playerTop = player.y + tileSize/2 - ballSize/2
    playerBottom = player.y + tileSize/2 + ballSize/2

    for i = 1, powerUpCount do 

        if powerUps[i].sitting == true then

            powerUpLeft = powerUps[i].x + tileSize/2 - 3
            powerUpRight = powerUps[i].x + tileSize/2 + 3
            powerUpTop = powerUps[i].y + tileSize/2 - 3
            powerUpBottom = powerUps[i].y + tileSize/2 + 3

            if playerLeft < powerUpRight and playerRight > powerUpLeft and playerTop < powerUpBottom and playerBottom > powerUpTop then
                powerUps[i].sitting = false
                powerUps[i].active = true
                powerUps[i].startTime = time()
                sfx(2)
            end

            -- handle power up particles

            if powerUps[i].type == 2 then
                PUparticles[currentPUParticleIndex].x = powerUps[i].x + 4
                PUparticles[currentPUParticleIndex].y = powerUps[i].y + 2

                PUparticles[currentPUParticleIndex].speed.x = rnd(0.5) - 0.25
                PUparticles[currentPUParticleIndex].speed.y = -rnd(0.5) - 0.25

                PUparticles[currentPUParticleIndex].color = 8

                currentPUParticleIndex += 1
                if currentPUParticleIndex > numPUParticles then
                    currentPUParticleIndex = 1
                end

            end

            if powerUps[i].type == 3 then
                PUparticles[currentPUParticleIndex].x = powerUps[i].x + 4
                PUparticles[currentPUParticleIndex].y = powerUps[i].y + 4

                PUparticles[currentPUParticleIndex].speed.x = rnd(0.5) - 0.25
                PUparticles[currentPUParticleIndex].speed.y = rnd(0.5) - 0.25

                PUparticles[currentPUParticleIndex].color = 12

                currentPUParticleIndex += 1
                if currentPUParticleIndex > numPUParticles then
                    currentPUParticleIndex = 1
                end

            end
            
        end

        if powerUps[i].active == true then

            if powerUps[i].type == 0 and scoreMultiplier < 2 then
                scoreMultiplier = 2
            elseif powerUps[i].type == 1 then
                scoreMultiplier = 4
            elseif powerUps[i].type == 2 then
                availableCharge = maxCharge
                chargeRate = 2 * defaultChargeRate
            elseif powerUps[i].type == 3 then
                maxDamage = true
                player.damage = 8
            end

            if time() - powerUps[i].startTime > powerUpDuration then
                
                powerUps[i].active = false

                if powerUps[i].type == 0 then
                    scoreMultiplier = 1
                elseif powerUps[i].type == 1 then
                    scoreMultiplier = 1
                elseif powerUps[i].type == 2 then
                    chargeRate = defaultChargeRate
                elseif powerUps[i].type == 3 then
                    maxDamage = false
                end
            end

        end

    end

end

function handle_particles()

    -- player

    for i = 1, numParticles do 
        particles[i].x += particles[i].speed.x * timeMultiplier
        particles[i].y += particles[i].speed.y * timeMultiplier
    end

    particles[currentParticleIndex].color = player.flame

    if player.flame > 0 then
        particles[currentParticleIndex].x = player.x + ballBuffer + ballSize/2
        particles[currentParticleIndex].y = player.y + ballBuffer + ballSize/2

        particles[currentParticleIndex].speed.x = player.speed.x / player.speed.x + rnd(1) - 0.5
        particles[currentParticleIndex].speed.y = player.speed.y / player.speed.y + rnd(1) - 0.5
    end

    currentParticleIndex += 1
    if currentParticleIndex > numParticles then
        currentParticleIndex = 1
    end

    -- power ups
    for j = 1, numPUParticles do 
        PUparticles[j].x += PUparticles[j].speed.x * timeMultiplier
        PUparticles[j].y += PUparticles[j].speed.y * timeMultiplier
    end

end

function handle_collisions()

    -- check colisions 

    reverseHorizontalSpeed = false
    reverseVerticalSpeed = false

    horizontalCorrection = 0
    verticalCorrection = 0

    -- set bounds for collision detection
    playerLeft = player.x + ballBuffer--tileSize/2 - ballSize/2
    playerRight = player.x + tileSize/2 + ballSize/2
    playerTop = player.y + ballBuffer--tileSize/2 - ballSize/2
    playerBottom = player.y + tileSize/2 + ballSize/2

    -- handle world collisions

    worldBottom = max(brickSpawnY, 128) - 1

    if playerLeft < 0 then
        player.x = 0 - ballBuffer

        if player.speed.x < 0 then
            -- player.speed.x = - bounceMultiplier * player.speed.x
            reverseHorizontalSpeed = true
        end

        sfx(0)
    end

    if playerRight > 127 then
        player.x = 127 - tileSize + ballBuffer

        if player.speed.x > 0 then
            -- player.speed.x = - bounceMultiplier * player.speed.x
            reverseHorizontalSpeed = true
        end

        sfx(0)
    end

    if playerTop < 0 then
        player.y = 0 + ballBuffer

        if player.speed.y < 0 then
            -- player.speed.y = - bounceMultiplier * player.speed.y
            reverseVerticalSpeed = true
        end

        sfx(0)
    end

    if playerBottom > worldBottom then
        player.y = worldBottom - tileSize + ballBuffer

        if player.speed.y > 0 then
            -- player.speed.y = - bounceMultiplier * player.speed.y
            -- player.speed.x = friction * player.speed.x
            reverseVerticalSpeed = true
        end

        if abs(player.speed.y) > gravity then
            sfx(0)
        end
    end

    -- handle brick collisions

    brickCollisions = 0
    bricksCollidedWith = {}

    for i = 1, maxBricks do

        brickLeft = bricks[i].x
        brickRight = bricks[i].x + brickSize
        brickTop = bricks[i].y
        brickBottom = bricks[i].y + brickSize

        rightWall = false
        leftWall = false
        ceiling = false
        floor = false

        corner = false

        boundCheckBuffer = 2

        
        bricks[i].tag = ""

        -- BRICK COLORS: 1, 2, 3, 4, 12, 13, 14, 15

        -- RIGHT WALL
        -- get color of tile to the right
        mapRight = pget(brickRight + boundCheckBuffer, brickTop + boundCheckBuffer)
        -- check to see if color is background, ball, or ball trail
        if mapRight == 0 or (mapRight > 4 and mapRight < 12) then
            rightWall = true

            if brickRight + tileSize/2 > screenSize then
                rightWall = false
            end
        end

        -- LEFT WALL
        -- get color of tile to the left
        mapLeft = pget(brickLeft - boundCheckBuffer, brickTop + boundCheckBuffer)
        -- check to see if color is background, ball, or ball trail
        if mapLeft == 0 or (mapLeft > 4 and mapLeft < 12) then
            leftWall = true

            if brickLeft - tileSize/2 < 0  then
                leftWall = false
            end
        end

        -- CEILING
        -- get color of tile downward
        mapDown = pget(brickLeft + boundCheckBuffer, brickBottom + boundCheckBuffer)
        -- check to see if color is background, ball, or ball trail
        if mapDown == 0 or (mapDown > 4 and mapDown < 12) then
            ceiling = true

            if brickBottom + tileSize/2 > worldBottom then
                ceiling = false
            end
        end

        -- FLOOR
        -- get color of tile downward
        mapUp = pget(brickLeft + boundCheckBuffer, brickTop - boundCheckBuffer)
        -- check to see if color is background, ball, or ball trail
        if mapUp == 0 or (mapUp > 4 and mapUp < 12) then
            floor = true
        end

        -- corner
        if rightWall == false and leftWall == false and ceiling == false and floor == false then
            rightWall = true
            leftWall = true
            ceiling = true
            floor = true

            corner = true
        end

        -- add tags
        if rightWall then
            bricks[i].tag = bricks[i].tag.."r"
        end
        if leftWall then
            bricks[i].tag = bricks[i].tag.."l"
        end
        if ceiling then
            bricks[i].tag = bricks[i].tag.."c"
        end
        if floor then
            bricks[i].tag = bricks[i].tag.."f"
        end
    
        -- extend brick edges for corner detection
        -- if rightWall == false then
        --     brickRight += tileSize
        -- end
        -- if leftWall == false then
        --     brickLeft -= tileSize
        -- end
        -- if ceiling == false then
        --     brickBottom += tileSize
        -- end
        -- if floor == false then
        --     brickTop -= tileSize
        -- end

        -- check for overlap

        if playerLeft < brickRight and playerRight > brickLeft and playerTop < brickBottom and playerBottom > brickTop and brickTop < worldBottom then
            -- overlap detected

            -- brickCollisions += 1
            -- bricksCollidedWith[brickCollisions] = i

            -- set flags for edge checking
            -- bricksCollidedWith[brickCollisions].rightWall = false
            -- bricksCollidedWith[brickCollisions].leftWall = false
            -- bricksCollidedWith[brickCollisions].ceiling = false
            -- bricksCollidedWith[brickCollisions].floor = false

            -- rightWall = false
            -- leftWall = false
            -- ceiling = false
            -- floor = false

            -- -- CHECK TO SEE IF WALL, CEILING, OR FLOOR

            -- -- RIGHT WALL
            -- -- get color of tile to the right
            -- mapRight = pget(brickRight + tileSize/2, brickTop + tileSize /2)
            -- -- check to see if color is background, ball, or ball trail
            -- if mapRight == 0 or mapRight == 5 or mapRight == 6 or mapRight == 7 then
            --     -- bricksCollidedWith[brickCollisions].rightWall = true
            --     rightWall = true

            --     if brickRight + tileSize/2 > screenSize then
            --         rightWall = false
            --     end
            -- end

            -- -- LEFT WALL
            -- -- get color of tile to the left
            -- mapLeft = pget(brickLeft - tileSize/2, brickTop + tileSize /2)
            -- -- check to see if color is background, ball, or ball trail
            -- if mapLeft == 0 or mapLeft == 5 or mapLeft == 6 or mapLeft == 7 then
            --     -- bricksCollidedWith[brickCollisions].leftWall = true
            --     leftWall = true

            --     if brickLeft - tileSize/2 <0  then
            --         leftWall = false
            --     end
            -- end

            -- -- CEILING
            -- -- get color of tile downward
            -- mapDown = pget(brickLeft + tileSize/2, brickBottom + tileSize /2)
            -- -- check to see if color is background, ball, or ball trail
            -- if mapDown == 0 or mapDown == 5 or mapDown == 6 or mapDown == 7 then
            --     -- bricksCollidedWith[brickCollisions].ceiling = true
            --     ceiling = true

            --     if brickBottom + tileSize/2 > worldBottom then
            --         ceiling = false
            --     end
            -- end

            -- -- FLOOR
            -- -- get color of tile downward
            -- mapUp = pget(brickLeft + tileSize/2, brickTop - tileSize /2)
            -- -- check to see if color is background, ball, or ball trail
            -- if mapUp == 0 or mapUp == 5 or mapUp == 6 or mapUp == 7 then
            --     -- bricksCollidedWith[brickCollisions].floor = true
            --     floor = true
            -- end

            -- extend brick edges for corner detection
            -- if rightWall == false then
            --     brickRight += brickSize
            -- end
            -- if leftWall == false then
            --     brickLeft -= brickSize
            -- end
            -- if ceiling == false then
            --     brickBottom += brickSize
            -- end
            -- if floor == false then
            --     brickTop -= brickSize
            -- end

            horizontalCollision = false
            verticalCollision = false

            verticalSink = 0
            horizontalSink = 0

            -- left moving player collision
            if player.speed.x < 0 and rightWall == true then
                horizontalCollision = true
                horizontalSink = brickRight - playerLeft
            end

            -- right moving player collision
            if player.speed.x > 0 and leftWall == true then
                horizontalCollision = true
                horizontalSink = brickLeft - playerRight
            end

            -- upward moving player collision
            if player.speed.y < 0 and ceiling == true then
                verticalCollision = true
                verticalSink = brickBottom - playerTop
            end

            -- downward moving player collision
            if player.speed.y > 0 and floor == true then
                verticalCollision = true
                verticalSink =  brickTop - playerBottom
            end

            -- handle ball bounces

            if verticalCollision == true and horizontalCollision == true and corner == false then
                if abs(verticalSink) > abs(horizontalSink) then
                    verticalCollision = false
                elseif abs(horizontalSink) > abs(verticalSink) then
                    horizontalCollision = false
                end
            end

            if horizontalCollision == true then
                horizontalCorrection = horizontalSink

                -- player.x += horizontalSink --* -( player.speed.x / abs(player.speed.x) )

                reverseHorizontalSpeed = true

                -- player.speed.x = - bounceMultiplier * player.speed.x
                -- player.speed.y = friction * player.speed.y

                bricks[i].numTag = tostr(horizontalSink)

                -- if abs(player.speed.x) < minBounceSpeed then
                --     player.speed.x = minBounceSpeed * (player.speed.x / abs(player.speed.x))
                -- end
            end

            if verticalCollision == true then
                verticalCorrection = verticalSink

                -- player.y += verticalSink --* -( player.speed.y / abs(player.speed.y) )

                reverseVerticalSpeed = true
                -- player.speed.y = - bounceMultiplier * player.speed.y
                -- player.speed.x = friction * player.speed.x

                bricks[i].numTag = tostr(verticalSink)

                -- if abs(player.speed.y) < minBounceSpeed then
                --     player.speed.y = minBounceSpeed * (player.speed.y / abs(player.speed.y))
                -- end
            end

            -- mark bricks

            if horizontalCollision and abs(player.speed.x) > maxSpeed / 8  and corner == false then
                brickCollisions += 1
                bricksCollidedWith[brickCollisions] = i
            elseif verticalCollision and abs(player.speed.y) > maxSpeed / 8 and corner == false then
                brickCollisions += 1
                bricksCollidedWith[brickCollisions] = i
            elseif maxDamage then
                brickCollisions += 1
                bricksCollidedWith[brickCollisions] = i
            end

            -- if verticalCollision or horizontalCollision then
            --     -- if bricks[i].y < worldBottom then
            --     --     bricks[i].health -= player.damage
            --     -- end

            --     -- if bricks[i].health <= 0 then
            --     --     score += bricks[i].points * scoreMultiplier

            --     --     -- randomly spawn power ups
            --     --     powerUpSpawner = flr(rnd(powerUpSpawnChance))

            --     --     -- powerUpSpawner = 4

            --     --     if powerUpSpawner == 4 then
            --     --         powerUpPicker = flr(rnd(8))

            --     --         -- powerUpPicker = 2

            --     --         if powerUpPicker == 1 then
            --     --             spawn_power_up(bricks[i].x + tileSize/2, bricks[i].y + tileSize/2, 1)
            --     --         elseif powerUpPicker == 2 then
            --     --             spawn_power_up(bricks[i].x + tileSize/2, bricks[i].y + tileSize/2, 2)
            --     --         else
            --     --             spawn_power_up(bricks[i].x + tileSize/2, bricks[i].y + tileSize/2, 0)
            --     --         end
            --     --     end

            --     --     spawnBrick(i)
            --     -- end
            -- end

        end
    end

    -- handle ball redirection
    if reverseHorizontalSpeed then
        player.x += horizontalCorrection

        player.speed.x = - bounceMultiplier * player.speed.x
        player.speed.y = friction * player.speed.y

        if abs(player.speed.x) > gravity then
            sfx(0)
        end
    end
    if reverseVerticalSpeed then
        player.y += verticalCorrection

        player.speed.y = - bounceMultiplier * player.speed.y
        player.speed.x = friction * player.speed.x

        if abs(player.speed.y) > gravity then
            sfx(0)
        end
    end

    -- if abs(player.speed.x) < gravity then
    --     player.speed.x = 0
    -- end
    -- if abs(player.speed.y) < gravity then
    --     player.speed.y = 0
    -- end

    -- handle brick damage

    for j = 1, brickCollisions do 

        brickIndex = bricksCollidedWith[j]

        if bricks[brickIndex].y < worldBottom then
            bricks[brickIndex].health -= player.damage
        end

        if bricks[brickIndex].health <= 0 then
            score += bricks[brickIndex].points * scoreMultiplier

            -- randomly spawn power ups
            powerUpSpawner = flr(rnd(powerUpSpawnChance))

            -- powerUpSpawner = 4

            if powerUpSpawner == 4 then
                powerUpPicker = flr(rnd(8))

                -- powerUpPicker = 3

                if powerUpPicker == 1 then
                    spawn_power_up(bricks[brickIndex].x + tileSize/2, bricks[brickIndex].y + tileSize/2, 1)
                elseif powerUpPicker == 2 then
                    spawn_power_up(bricks[brickIndex].x + tileSize/2, bricks[brickIndex].y + tileSize/2, 2)
                elseif powerUpPicker == 3 then
                    spawn_power_up(bricks[brickIndex].x + tileSize/2, bricks[brickIndex].y + tileSize/2, 3)
                else
                    spawn_power_up(bricks[brickIndex].x + tileSize/2, bricks[brickIndex].y + tileSize/2, 0)
                end
            end

            spawnBrick(brickIndex)
        end
    end
end

function handle_player_input() 

    -- if btn(2) then
    --     player.speed.y = -maxSpeed
    -- end
    
    -- check if charging
    if btn(0) or btn(1) or btn(2) or btn(3) then
        if charging == false then
            charging = true
            sfx(4)
        end
    else
        if charging == true then
            charging = false

            sfx(5)

            if abs(horizontalCharge) > 0 then
                player.speed.x = horizontalCharge
            end

            if abs(verticalCharge) > 0 then
                player.speed.y = verticalCharge
            end

            availableCharge -= max(abs(horizontalCharge), abs(verticalCharge))

            horizontalCharge = 0
            verticalCharge = 0

            if gameStarted == false then
                gameStarted = true
                gameTimeStart = time()
                titleCounter = 1
            end
        end
    end

    -- left key
    if btn(0) then
        if charging then

            horizontalCharge -= chargeRate

            if horizontalCharge < -availableCharge then
                horizontalCharge = -availableCharge
            end
        end
    end

    -- right key
    if btn(1) then
        if charging then

            horizontalCharge += chargeRate

            if horizontalCharge > availableCharge then
                horizontalCharge = availableCharge
            end
        end
    end

    -- up key
    if btn(2) then
        if charging then
            
            verticalCharge -= chargeRate

            if verticalCharge < -availableCharge then
                verticalCharge = -availableCharge
            end
        end
    end

    -- down key
    if btn(3) then
        if charging then

            verticalCharge += chargeRate

            if verticalCharge > availableCharge then
                verticalCharge = availableCharge
            end
        end
    end

    -- o button
    if btn(4) then
        if oButtonPressed == false then
            if square then
                square = false
            else
                square = true
            end
            sfx(3)
        end

        oButtonPressed = true
    else
        oButtonPressed = false
    end

    -- x button
    if btn(5) then
        if xButtonPressed == false then
            if square then
                square = false
            else
                square = true
            end
            sfx(3)
        end

        xButtonPressed = true
    else
        xButtonPressed = false
    end

end

function _update()

    -- handle title screen
    handle_title_screen()

    -- update trail effects
    player.trail[2].x = player.trail[1].x
    player.trail[2].y = player.trail[1].y

    player.trail[1].x = player.x
    player.trail[1].y = player.y

    -- apply gravity
    if gameStarted == true then
        player.speed.y += gravity * timeMultiplier
    end

    -- limit speeds

    if abs(player.speed.x) < gravity * timeMultiplier then
        player.speed.x = 0
    end
    if abs(player.speed.y) < gravity * timeMultiplier then
        player.speed.y = 0
    end

    if player.speed.y > maxSpeed then
        player.speed.y = maxSpeed
    end
    if player.speed.y < -maxSpeed then
        player.speed.y = -maxSpeed
    end
    if player.speed.x > maxSpeed then
        player.speed.x = maxSpeed
    end
    if player.speed.x < -maxSpeed then
        player.speed.x = -maxSpeed
    end
    
    -- apply speeds
    player.x += player.speed.x * timeMultiplier
    player.y += player.speed.y * timeMultiplier

    -- handle collisions
    handle_collisions()

    -- player input
    handle_player_input()

    -- apply time effect
    if charging == true then
        timeMultiplier = 0.2
    elseif charging == false then
        timeMultiplier = 1
    end

    -- handle charging
    if availableCharge < maxCharge and gameStarted then
        availableCharge += rechargeRate * timeMultiplier
        if availableCharge > maxCharge then
            availableCharge = maxCharge
        end
    end

    -- handle player damage
    
    if abs(player.speed.x) >= 3 * maxSpeed / 4 or abs(player.speed.y) >= 3 * maxSpeed / 4 then
        player.damage = 8
        player.flame = 3
    elseif abs(player.speed.x) >= 2 * maxSpeed / 4 or abs(player.speed.y) > 2 * maxSpeed / 4 then
        player.damage = 4
        player.flame = 2
    elseif abs(player.speed.x) >= maxSpeed / 4 or abs(player.speed.y) > maxSpeed / 4 then
        player.damage = 2
        player.flame = 1
    elseif abs(player.speed.x) >= maxSpeed / 8 or abs(player.speed.y) >= maxSpeed / 8 then
        player.damage = 1
        player.flame = 0
    else
        player.damage = 0
        player.flame = 0
    end

    -- handle particles
    handle_particles()

    -- handle power ups
    handle_power_ups()

end

function _draw()
    -- clear screen
    cls()

    -- set cam
    cam = {x = 0, y = player.y - 63}
    camera(cam.x, cam.y)

    --debug
    --print("x: "..tostr(player.x)..", y: "..tostr(player.y), player.x - 2, player.y - 7)

    -- handle effects
    flashCurrentFrame += 1
    if flashCurrentFrame >= flashFrameLength then

        if flashOn then
            flashOn = false
        else
            flashOn = true
        end

        flashCurrentFrame = 0
    end

    -- draw world bounds
    line(0, 0, screenSize, 0, 7)

    line(0, worldBottom, screenSize, worldBottom)

    line(cam.x, max(0, cam.y), cam.x, min(cam.y + screenSize, worldBottom), 7)
    line(cam.x + screenSize - 1, max(0, cam.y), cam.x + screenSize - 1, min(cam.y + screenSize, worldBottom), 7)

    -- draw particles
    for i = 1, numParticles do 
        if particles[i].color > 0 and particles[i].y > 0 and particles[i].y < worldBottom then
            if maxDamage == false then
                pset(particles[i].x, particles[i].y, 11 - particles[i].color)
            else
                pset(particles[i].x, particles[i].y, 12)
            end
        end
    end

    for i = 1, numPUParticles do 
        if PUparticles[i].y > 0 and PUparticles[i].y < worldBottom then
            pset(PUparticles[i].x, PUparticles[i].y, PUparticles[i].color)
        end
    end

    -- draw player and trail sprites
    playerStartSprite = 1
    if square then
        playerStartSprite = 56
    end

    spr(playerStartSprite + 5, player.trail[2].x, player.trail[2].y)
    spr(playerStartSprite + 4, player.trail[1].x, player.trail[1].y)
    -- spr(3, player.x - player.speed.x * 2, player.y - player.speed.y * 2)
    -- spr(2, player.x - player.speed.x, player.y - player.speed.y)
    if maxDamage == false then
        spr(playerStartSprite + player.flame, player.x, player.y)
    else
        if square then
            spr(62, player.x, player.y)
        else
            spr(7, player.x, player.y)
        end
        
    end

    --draw bricks
    for i = 1, maxBricks do
        if bricks[i].health > 0 and bricks[i].y < cam.y + screenSize and bricks[i].y < worldBottom then
            -- top left
            spr(14 + bricks[i].health * 2, bricks[i].x, bricks[i].y)
            -- top right
            spr(14 + bricks[i].health * 2 + 1, bricks[i].x + tileSize, bricks[i].y)
            -- bottom left
            spr(14 + bricks[i].health * 2 + 16, bricks[i].x, bricks[i].y + tileSize)
            -- bottom right
            spr(14 + bricks[i].health * 2 + 17, bricks[i].x + tileSize, bricks[i].y + tileSize)

            -- FOR DEBUGGING
            -- if square then
            --     print(bricks[i].numTag, bricks[i].x, bricks[i].y + tileSize/2 + 1, 0)
            -- else
            --     print(bricks[i].tag, bricks[i].x, bricks[i].y + tileSize/2 + 1, 0)
            -- end
            
            if bricks[i].health < bricks[i].points then

                print(bricks[i].health, bricks[i].x + tileSize/2 + 2, bricks[i].y + tileSize/2 + 1, 7)

            --     if bricks[i].health >= 6 then
            --         spr(48, bricks[i].x + tileSize/2, bricks[i].y + tileSize/2)
            --     elseif bricks[i].health >= 4 then
            --         spr(49, bricks[i].x + tileSize/2, bricks[i].y + tileSize/2)
            --     elseif bricks[i].health >= 2 then
            --         spr(50, bricks[i].x + tileSize/2, bricks[i].y + tileSize/2)
            --     elseif bricks[i].health > 0 then
            --         spr(51, bricks[i].x + tileSize/2, bricks[i].y + tileSize/2)
            --     end
            end
        end
    end

    -- draw charge arrow

    arrowColor = 6

    if availableCharge >= 3 * maxCharge / 4 then
        arrowColor = 8
    elseif availableCharge >= 2 * maxCharge / 4 then
        arrowColor = 8 + 1
    elseif availableCharge >= maxCharge / 4 then
        arrowColor = 8 + 2
    else
        arrowColor = 6
    end

    if maxDamage then
        arrowColor = 12
    end

    if charging then
        arrowLength = 3

        arrowOriginX = player.x + tileSize / 2 + horizontalCharge * 3
        arrowOriginY = player.y + tileSize / 2 + verticalCharge * 3

        angle = atan2(horizontalCharge, verticalCharge)

        line(arrowOriginX - horizontalCharge * 2, arrowOriginY - verticalCharge * 2, arrowOriginX, arrowOriginY, arrowColor)

        line(arrowOriginX, arrowOriginY, arrowOriginX + arrowLength * cos(angle + 0.125 + 0.25), arrowOriginY + arrowLength * sin(angle + 0.125 + 0.25), arrowColor)
        line(arrowOriginX, arrowOriginY, arrowOriginX + arrowLength * cos(angle + 0.125 + 0.5), arrowOriginY + arrowLength * sin(angle + 0.125 + 0.5), arrowColor)
    end

    -- draw power ups
    powerUpRenderBuffer = 0

    for i = 1, powerUpCount do 
        if powerUps[i].sitting == true then

            if powerUps[i].type == 0 then
                print("X2", powerUps[i].x, powerUps[i].y, 11)
            elseif powerUps[i].type == 1 then
                print("X4", powerUps[i].x, powerUps[i].y, 11)
            elseif powerUps[i].type == 2 then
                spr(48, powerUps[i].x, powerUps[i].y)

                -- for j = 1, powerUps[i].numParticles do 
                --     pset(powerUps[i].particles[j].x, powerUps[i].particles[j].y, 8)
                -- end       
            elseif powerUps[i].type == 3 then 
                if flashOn then
                    spr(49, powerUps[i].x, powerUps[i].y)
                else
                    spr(50, powerUps[i].x, powerUps[i].y)
                end
            end

        end

        if powerUps[i].active == true then
            if powerUps[i].type == 0 then
                -- print(tostr(time() - powerUps[i].startTime), cam.x + 3, cam.y + 20, 11)

                if (flashOn or (powerUpDuration - (time() - powerUps[i].startTime)) > 5) then
                    print("X2", cam.x + 3, cam.y + 23 + powerUpRenderBuffer, 11)
                end
                
                powerUpRenderBuffer += 7
            elseif powerUps[i].type == 1 then
                -- print(tostr(time() - powerUps[i].startTime), cam.x + 3, cam.y + 30, 11)

                if (flashOn or (powerUpDuration - (time() - powerUps[i].startTime)) > 5) then
                    print("X4", cam.x + 3, cam.y + 23 + powerUpRenderBuffer, 11)
                end

                powerUpRenderBuffer += 7
            elseif powerUps[i].type == 2 then
                -- print(tostr(time() - powerUps[i].startTime), cam.x + 3, cam.y + 40, 8)

                if (flashOn or (powerUpDuration - (time() - powerUps[i].startTime)) > 5) then
                    print("max charge", cam.x + 3, cam.y + 23 + powerUpRenderBuffer, 8)
                end

                powerUpRenderBuffer += 7
            elseif powerUps[i].type == 3 then
                -- print(tostr(time() - powerUps[i].startTime), cam.x + 3, cam.y + 40, 8)

                if (flashOn or (powerUpDuration - (time() - powerUps[i].startTime)) > 5) then
                    print("max damage", cam.x + 3, cam.y + 23 + powerUpRenderBuffer, 12)
                end

                powerUpRenderBuffer += 7
            end
        end
    end

    -- render title
    if titleShow or titleFlash then
        for i = 0, 5 do
            spr(64 + i, (tileSize + 1) * (i + 4.6) - tileSize/2, tileSize * 4)
        end

        spr(8 + tinyBrickPicker, (tileSize + 1) * (5 + 4.6) - tileSize/2, tileSize * 4)
    
        for i = 0, 6 do
            spr(80 + i, (tileSize + 1) * (i + 4.6) - tileSize/2, tileSize * 5 + 1)
        end

        spr(71, screenSize/2 - tileSize/2, screenSize - tileSize * 2 - arrowBuffer)
    end

    -- draw UI
    if gameStarted then
        print("score: "..tostr(score), cam.x + 3, cam.y + 9, 7)
        print("depth: "..tostr(flr((player.y + ballBuffer + ballSize/2) / brickSize)), cam.x + 3, cam.y + 16, 7)

        -- draw charge bar
        barLength = 121
        rect(cam.x + 3, cam.y + 3, cam.x + 3 + barLength, cam.y + 6, 7)
        rect(cam.x + 4, cam.y + 4, cam.x + 4 + (barLength - 2) * (availableCharge / maxCharge), cam.y + 5, arrowColor)
    end
    

    -- debug
    -- print("Time Multiplier: "..tostr(timeMultiplier), player.x - 30, player.y - 40)
    -- print("Horizontal Charge: "..tostr(horizontalCharge), player.x - 30, player.y - 30)
    -- print("Vertical Charge: "..tostr(verticalCharge), player.x - 30, player.y - 20)
    -- print("Charging :"..tostr(charging), player.x - 30, player.y - 10)
end