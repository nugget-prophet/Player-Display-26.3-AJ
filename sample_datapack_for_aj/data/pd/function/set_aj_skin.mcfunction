#function has to be called by the player. If a non-player is calling the function use(execute as @p run function pd:set_aj_skin)

execute at @s run summon item_display ~ ~ ~ {Tags:["name"],UUID:[I;112,110,116,120],transformation:{left_rotation:[0f,0f,0f,1f],right_rotation:[0f,0f,0f,1f],translation:[0f,0f,0f],scale:[0f,0f,0f]}}

execute store result storage pd: _.name int 1 run data get entity 00000070-0000-006e-0000-007400000078 item.components.minecraft:profile.name


loot replace entity 00000070-0000-006e-0000-007400000078 container.0 loot pd:entities/player_head


data modify storage pd: _.name set from entity 00000070-0000-006e-0000-007400000078 item.components.minecraft:profile.name


kill 00000070-0000-006e-0000-007400000078




execute as @e[tag=aj.player_display.bone.head,distance=..3,sort=nearest,limit=1,type=item_display] run function pd:1_head with storage pd: _

execute as @e[tag=aj.player_display.bone.right_arm,distance=..3,sort=nearest,limit=1,type=item_display] run function pd:1_arm_r with storage pd: _

execute as @e[tag=aj.player_display.bone.left_arm,distance=..3,sort=nearest,limit=1,type=item_display] run function pd:1_arm_l with storage pd: _

execute as @e[tag=aj.player_display.bone.torso,distance=..3,sort=nearest,limit=1,type=item_display] run function pd:1_torso with storage pd: _

execute as @e[tag=aj.player_display.bone.right_leg,distance=..3,sort=nearest,limit=1,type=item_display] run function pd:1_leg_r with storage pd: _

execute as @e[tag=aj.player_display.bone.left_leg,distance=..3,sort=nearest,limit=1,type=item_display] run function pd:1_leg_l with storage pd: _
