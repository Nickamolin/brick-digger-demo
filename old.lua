collisionX = false
    collisionY = false

    brickToDamageX = 1
    brickToDamageY = 1

    setPlayerX = player.x
    setPlayerY = player.y

    -- label edges

    playerLeft = player.x + tileSize/2 - ballSize/2
    playerRight = player.x + tileSize/2 + ballSize/2
    playerTop = player.y + tileSize/2 - ballSize/2
    playerBottom = player.y + tileSize/2 + ballSize/2

    for i = 1, maxBricks do
        
        -- check collisions traveling right
        if player.speed.x > 0 then
            if playerRight > bricks[i].x and playerRight - player.speed.x < bricks[i].x + brickSize then
                if playerBottom > bricks[i].y and playerTop < bricks[i].y + tileSize then
                    -- collision happened
                    collisionX = true

                    if bricks[i].x - ballSize < setPlayerX then
                        setPlayerX = bricks[i].x - ballSize
                        brickToDamageX = i
                    end
                end
            end
        end

        -- check collisions traveling left
        if player.speed.x < 0 then
            if playerLeft < bricks[i].x + brickSize and playerLeft - player.speed.x > bricks[i].x then
                if playerBottom > bricks[i].y and playerTop < bricks[i].y + tileSize then
                    -- collision happened
                    collisionX = true

                    if bricks[i].x + tileSize > setPlayerX then
                        setPlayerX = bricks[i].x + tileSize
                        brickToDamageX = i
                    end
                end
            end
        end

        -- check collisions traveling down
        if player.speed.y > 0 then
            if playerBottom > bricks[i].y and playerBottom - player.speed.y < bricks[i].y + brickSize then
                if playerRight > bricks[i].x and playerLeft < bricks[i].x + tileSize then
                    -- collision happened
                    collisionY = true

                    if bricks[i].y - ballSize < setPlayerY then
                        setPlayerY = bricks[i].y - ballSize
                        brickToDamageY = i
                    end
                end
            end
        end

        -- check collisions traveling up
        if player.speed.y < 0 then
            if playerTop < bricks[i].y + brickSize and playerTop - player.speed.y > bricks[i].y then
                if playerRight > bricks[i].x and playerLeft < bricks[i].x + tileSize then
                    -- collision happened
                    collisionY = true

                    if bricks[i].y + tileSize > setPlayerY then
                        setPlayerY = bricks[i].y + tileSize
                        brickToDamageY = i
                    end
                end
            end
        end
    end

    -- handle collisions

    if collisionX == true and collisionY == true then

        -- check to see if solely vertical collision detection can resolve it
        collisionX = false

        for j = 1, maxBricks do
            if setPlayerX + 1 < bricks[j].x + tileSize and setPlayerX + 1 + ballSize > bricks[j].x then
                if player.y + 1 < bricks[j].y + tileSize and player.y + 1 + ballSize > bricks[j].y then
                    collisionX = true
                end
            end
        end

        -- check to see if solely vertical collision detection can resolve it
        collisionY = false

        for j = 1, maxBricks do
            if setPlayerY + 1 < bricks[j].y + tileSize and setPlayerY + 1 + ballSize > bricks[j].y then
                if player.x + 1 < bricks[j].x + tileSize and player.x + 1 + ballSize > bricks[j].x then
                    collisionY = true
                end
            end
        end

    end

    if collisionX == true then

        if abs(player.speed.x) > 1 then
            bricks[brickToDamageX].health = 0
            bricks[brickToDamageX].x = -200
        end

        player.x = setPlayerX
        player.speed.x = -0.5 * player.speed.x
    end

    if collisionY == true then

        if abs(player.speed.y) > 1 then
            bricks[brickToDamageY].health = 0
            bricks[brickToDamageY].y = -200
        end

        player.y = setPlayerY
        player.speed.y = -0.5 * player.speed.y
    end