# VulkanTrek rules, version 2

These rules are intentional game design, not claims about the DOS original.

## Mission and information

| Rank | Hostiles | Deadline (days) |
|---|---:|---:|
| Lieutenant Commander | 16 | 40 |
| Commander | 20 | 38 |
| Captain | 24 | 36 |
| Commodore | 28 | 34 |
| Admiral | 32 | 32 |

All missions use 64 quadrants with 8×8 sectors. There are at most three initial
hostiles per random quadrant; two opening enemies and the opening base are fixed.
Fleet intelligence gives live enemy counts and friendly station types everywhere.
Stars remain unknown until scanned. REPORT lists remaining enemy quadrants.
Information, configuration orders, shield transfers, menus and typing take no time.

Victory means no hostiles remain. Deadline expiry, exhausted main power, loss of
crew, or exhausted life-support reserves ends the mission. Reaching the deadline
takes priority even if the final action destroys the final enemy.

## Power, travel and service

Main energy holds 5000 units and powers both movement and lasers. Shields have a
2500-unit reserve. SHUP costs 50 main; lowering shields is free. Transfers must
leave some main power. Full shield charge absorbs a full hit; protection declines
with shield charge and generator condition. MAX refills shields from main energy.
The converter restores 400 main units/day at full integrity, capped at 5000.

Impulse uses the shortest four-way unoccupied path: 8 energy and 0.04 day per
step (minimum action duration 0.05 day). Warp ignores intervening obstacles but
requires an empty destination. Its distance is global sector distance / 8;
cost is distance × warp × 60, doubled with raised shields; time is distance / warp.
Warp 4 is the recommended cruising setting. Above 6, each trip has a 25% chance
of damaging the engines. Damaged engines limit selectable warp. Automatic
navigation and target analysis require at least 50% computer integrity; manual
relative movement remains available with a failed computer.

Movement permits one local enemy response at arrival. Passive regeneration,
cooling and repair integrate in steps of at most 0.1 day during the journey;
there is no enemy fire in transit.

DOCK takes 0.3 day. A StarBase fills main power, shields, torpedoes, crew and life
reserves and protects docked repairs. Supply stations replenish torpedoes and
life reserves; research stations replenish life reserves only. Passive energy
regeneration still happens during station service. Firing or moving leaves
protection. The opening StarBase is never selected for the relief emergency.

## Weapons and enemies

LASERS accepts up to 2000 total energy per salvo from main power and costs 0.1 day.
Allocations follow INFO order. Damage is allocation × efficiency / (1 + range ×
0.16). Efficiency is laser integrity × clamp(1 − heat/140, 0.1, 1), with integrity
as a fraction. INFO gives a current single-target lethal allocation; above 2000
requires multiple salvos or another weapon. Heat rises by total allocation / 35,
caps at 120, and cools 60/day. Costs shown before execution exclude regeneration
and incoming damage.

Torpedoes use a ten-round inventory, up to three per 0.1-day salvo with intact
tubes. They follow a ray to the first object; raised shields cause a 25% scatter
chance. Damage is 750 / (1 + range × 0.08). Stars can nova; firing through neutral
objects can destroy them. RAY CONFIRM is usable once per mission: 50% clears the
quadrant, otherwise it removes 75% of main power and disables lasers. It takes
0.1 day and leaves docking protection. SELF CONFIRM ends the mission in defeat.

| Enemy | Shields | Behavior |
|---|---:|---|
| Cruiser | 450 | Moves one free sector closer every second response; normal fire |
| Scout | 240 | Moves away; once calls an existing ally from an adjacent quadrant; weak fire |
| Supply | 300 | Restores 35 shields to each ally within range 3 per response; weak fire |
| Commander | 800 | Closes every second response; stronger fire and +25% allied fire within range 3 |

Scouts and the relief event relocate existing ships. The fleet never grows.
Enemy movement cannot enter the player sector or an occupied sector. Recruited
allies first act on the next order. Killing enemies before their response prevents
their attack. Reading INFO never triggers a response.

## Repairs, emergencies and scoring

FIX [system|all] days waits in 0.1-day increments, each allowing an enemy response
outside StarBase protection. Repairs are faster at a StarBase; focusing one
system suspends work on others until it is restored. Damaged life support consumes
two days of reserve life supplies; healthy life support restores those reserves.
Repair life support before a long trip if reserve capacity is low.

On the first time step reaching six mission days, a non-opening StarBase may
request relief. Up to two existing ships are reassigned there, capped at four
local enemies. Clear it within six further days to preserve the base and earn
500 score. Missing the deadline destroys that base but does not itself end the
mission. If no enemy can threaten it, no relief reward is given. The mission
clock continues throughout the emergency and during all refits.

Score is max(0, kills × 100 + rescued × 2 + relief bonus − elapsed × 20 + victory
bonus 1000), rounded down. Planetary landing can collect one-time energium and
rescue populations. Energium restores main power when main is below 20% and
shields below 50%. Death-ray failure and rescue are optional tools, not required
by the command-only feasibility pilot.
