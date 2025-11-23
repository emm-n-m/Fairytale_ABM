breed [fey faerie]

fey-own [
  competence           ; 0-100: ability/skill level
  authoritarianism     ; 0-100: desire to dominate others
  humiliation-tolerance ; calculated from competence and authoritarianism
  perceived-humiliation ; current humiliation accumulated
  leadership-level      ; 0 = no leadership, higher = more authority
  time-in-position      ; ticks spent in current leadership position
  times-promoted        ; career counter
  times-stepped-down    ; career counter
  last-stepdown-tick    ; when they last resigned (for cooldown)
]

globals [
  total-promotions
  total-stepdowns
  avg-leader-competence
  avg-leader-authoritarianism
  leadership-pyramid  ; list of target counts per level
  promotion-cooldown  ; ticks agents must wait after stepdown before re-promotion
]

to setup
  clear-all
  set total-promotions 0
  set total-stepdowns 0
  set promotion-cooldown 50  ; Must wait 50 ticks after stepdown
  
  ; Calculate leadership pyramid: each level has fewer positions
  ; Level 0 = regular workers (no leadership)
  ; Level 1 = 1 position per X fey (frontline supervisors)
  ; Level 2 = 1 position per X^2 fey (middle management)
  ; etc.
  set leadership-pyramid []
  let level 1
  let positions-at-level floor (num-agents / agents-per-leader-ratio)
  
  while [positions-at-level >= 1] [
    set leadership-pyramid lput positions-at-level leadership-pyramid
    set level level + 1
    set positions-at-level floor (positions-at-level / agents-per-leader-ratio)
  ]
  
  create-fey num-agents [
    set competence random-float 100
    set authoritarianism random-float 100
    update-humiliation-tolerance
    set perceived-humiliation 0
    set leadership-level 0
    set time-in-position 0
    set times-promoted 0
    set times-stepped-down 0
    set last-stepdown-tick -999  ; never stepped down
    
    ; Visual representation
    set shape "person"
    setxy random-xcor random-ycor
    update-appearance
  ]
  
  ; Initial promotion to fill pyramid
  fill-leadership-pyramid
  
  reset-ticks
end

to update-humiliation-tolerance
  ; Competence increases tolerance, authoritarianism decreases it
  set humiliation-tolerance (competence * competence-tolerance-factor - 
                             authoritarianism * authoritarianism-penalty-factor)
end

to go
  if ticks > 1000 [stop]
  
  ; Each tick represents a time period
  ask fey [
    set time-in-position time-in-position + 1
    
    ; Leaders experience humiliation from subordinates
    if leadership-level > 0 [
      accumulate-humiliation
    ]
    
    ; Check if leader needs to step down
    if leadership-level > 0 and perceived-humiliation > humiliation-tolerance [
      let old-level leadership-level
      step-down
      ; Immediately trigger promotion to fill the vacancy
      fill-vacant-position old-level
    ]
  ]
  
  ; Update statistics
  calculate-statistics
  
  ; Visual updates
  ask fey [update-appearance]
  
  tick
end

to accumulate-humiliation
  ; Humiliation comes from subordinates exercising dominance
  ; Amount depends on number of subordinates and their assertiveness
  let subordinate-count count fey with [leadership-level = [leadership-level] of myself - 1]
  
  ; Base humiliation per subordinate, modified by the leader's authoritarianism
  ; More authoritarian leaders perceive MORE humiliation from same treatment
  let humiliation-per-sub humiliation-base-rate * (1 + authoritarianism / 100)
  
  set perceived-humiliation perceived-humiliation + (subordinate-count * humiliation-per-sub)
end

to step-down
  set leadership-level leadership-level - 1
  set perceived-humiliation 0
  set time-in-position 0
  set times-stepped-down times-stepped-down + 1
  set total-stepdowns total-stepdowns + 1
  set last-stepdown-tick ticks  ; Record when they stepped down
end

to fill-leadership-pyramid
  ; Initial filling of all leadership positions
  let level 1
  foreach leadership-pyramid [ target-count ->
    let current-count count fey with [leadership-level = level]
    let needed target-count - current-count
    
    if needed > 0 [
      ; Find candidates from level below (cooldown doesn't matter at initialization)
      let candidates fey with [
        leadership-level = level - 1 and
        (ticks - last-stepdown-tick) > promotion-cooldown
      ]
      
      if any? candidates [
        ; Promote the most qualified who can survive
        let viable-candidates candidates with [humiliation-tolerance > 0]
        
        if any? viable-candidates [
          let to-promote min (list needed count viable-candidates)
          
          ask max-n-of to-promote viable-candidates [
            authoritarianism * promotion-authoritarian-weight + 
            competence * promotion-competence-weight
          ] [
            set leadership-level level
            set perceived-humiliation 0
            set time-in-position 0
            set times-promoted times-promoted + 1
            set total-promotions total-promotions + 1
          ]
        ]
      ]
    ]
    set level level + 1
  ]
end

to fill-vacant-position [vacant-level]
  ; Check if we need to fill this position
  let level-index vacant-level - 1  ; convert to 0-indexed
  
  ; Make sure this level exists in pyramid
  if level-index < length leadership-pyramid [
    let target-count item level-index leadership-pyramid
    let current-count count fey with [leadership-level = vacant-level]
    
    if current-count < target-count [
      ; Find candidates from level below WHO HAVEN'T RECENTLY STEPPED DOWN
      let candidates fey with [
        leadership-level = vacant-level - 1 and
        (ticks - last-stepdown-tick) > promotion-cooldown  ; Must be past cooldown
      ]
      
      if any? candidates [
        ; Find the best candidate who can survive leadership
        let viable-candidates candidates with [humiliation-tolerance > 0]
        
        if any? viable-candidates [
          ; Promote the single best candidate
          let winner max-one-of viable-candidates [
            authoritarianism * promotion-authoritarian-weight + 
            competence * promotion-competence-weight
          ]
          
          ask winner [
            set leadership-level vacant-level
            set perceived-humiliation 0
            set time-in-position 0
            set times-promoted times-promoted + 1
            set total-promotions total-promotions + 1
          ]
        ]
      ]
    ]
  ]
end

to update-appearance
  ; Color based on leadership level
  let max-level length leadership-pyramid
  ifelse max-level > 0 [
    set color scale-color blue leadership-level (max-level + 1) 0
  ] [
    set color gray
  ]
  
  ; Size based on competence
  set size 0.5 + (competence / 100) * 1.5
  
  ; Shape indicates if under stress
  ifelse leadership-level > 0 and perceived-humiliation > (humiliation-tolerance * 0.8) [
    set shape "person business"  ; stressed leader
  ] [
    set shape "person"
  ]
end

to calculate-statistics
  let leaders fey with [leadership-level > 0]
  
  ifelse any? leaders [
    set avg-leader-competence mean [competence] of leaders
    set avg-leader-authoritarianism mean [authoritarianism] of leaders
  ] [
    set avg-leader-competence 0
    set avg-leader-authoritarianism 0
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
735
10
1172
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
20
20
100
53
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
110
20
190
53
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
20
70
250
103
num-agents
num-agents
10
500
200.0
10
1
NIL
HORIZONTAL

SLIDER
20
110
250
143
competence-tolerance-factor
competence-tolerance-factor
0
2
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
20
150
250
183
authoritarianism-penalty-factor
authoritarianism-penalty-factor
0
2
1.2
0.1
1
NIL
HORIZONTAL

SLIDER
20
190
250
223
agents-per-leader-ratio
agents-per-leader-ratio
5
20
10.0
1
1
agents
HORIZONTAL

SLIDER
20
230
250
263
humiliation-base-rate
humiliation-base-rate
0.1
5
1.5
0.1
1
per tick
HORIZONTAL

SLIDER
20
270
250
303
promotion-authoritarian-weight
promotion-authoritarian-weight
0
1
0.6
0.05
1
NIL
HORIZONTAL

SLIDER
20
310
250
343
promotion-competence-weight
promotion-competence-weight
0
1
0.4
0.05
1
NIL
HORIZONTAL

MONITOR
270
20
400
65
Total Leaders
count fey with [leadership-level > 0]
0
1
11

MONITOR
270
70
400
115
Leadership Levels
length leadership-pyramid
0
1
11

MONITOR
270
120
400
165
Pyramid Structure
leadership-pyramid
0
1
11

MONITOR
270
170
400
215
Avg Leader Competence
avg-leader-competence
2
1
11

MONITOR
270
220
400
265
Avg Leader Authoritarian
avg-leader-authoritarianism
2
1
11

MONITOR
270
270
400
315
Total Promotions
total-promotions
0
1
11

MONITOR
270
320
400
365
Total Stepdowns
total-stepdowns
0
1
11

MONITOR
270
370
400
415
Stepdown Rate
ifelse-value (total-promotions > 0) [total-stepdowns / total-promotions] [0]
3
1
11

MONITOR
270
420
400
465
Longest Tenure
ifelse-value any? fey with [leadership-level > 0] [max [time-in-position] of fey with [leadership-level > 0]] [0]
0
1
11

PLOT
420
20
720
200
Leadership Distribution
Leadership Level
Count
0.0
5.0
0.0
10.0
true
false
"" ""
PENS
"leaders" 1.0 1 -13345367 true "" "histogram [leadership-level] of fey"

PLOT
420
210
720
390
Leader Traits Over Time
Time
Value
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"competence" 1.0 0 -13840069 true "" "plot avg-leader-competence"
"authoritarianism" 1.0 0 -2674135 true "" "plot avg-leader-authoritarianism"

TEXTBOX
25
360
245
412
agents-per-leader-ratio determines hierarchy:\n10 = 1 leader per 10 agents\nForms natural pyramid structure
11
0.0
1

TEXTBOX
25
420
245
472
Promotion is immediate when vacancy:\nCompetition triggered by stepdown\nNo waiting for promotion cycles
11
0.0
1

TEXTBOX
420
400
720
442
Key Question: Does the system select for low-authoritarian, high-competence leaders over time?
12
15.0
1

@#$#@#$#@
## WHAT IS IT?

This model simulates Queen Amethyst's "Masochocracy" - a political system where leaders must submit to ritual humiliation from their subordinates. The hypothesis: requiring leaders to endure humiliation will naturally filter out power-hungry authoritarians while retaining competent leaders.

## HOW IT WORKS

**Agent Traits:**
- Competence (0-100): Ability to do their job
- Authoritarianism (0-100): Desire to dominate others
- Humiliation Tolerance: Calculated as (competence × factor) - (authoritarianism × penalty)

**The Mechanism:**
1. Agents with high authoritarianism and competence compete for leadership
2. Once in power, leaders accumulate humiliation from subordinates
3. More authoritarian leaders PERCEIVE more humiliation from the same treatment
4. When perceived humiliation exceeds tolerance, leaders step down
5. Vacancies immediately trigger promotion competitions

**The Trap:** Power-hungry individuals desperately want leadership but psychologically cannot tolerate the submission required to keep it.

## HOW TO USE IT

1. Click SETUP to create agents
2. Click GO to run the simulation
3. Watch "Leader Traits Over Time" plot:
   - RED line (authoritarianism) should DECREASE
   - BLUE line (competence) should stay HIGH

**Key Parameters:**
- agents-per-leader-ratio: Organizational structure (10 = 1 leader per 10 agents)
- authoritarianism-penalty-factor: How much being authoritarian sabotages tolerance
- competence-tolerance-factor: How much competence helps endure humiliation
- humiliation-base-rate: How fast humiliation accumulates

## THINGS TO NOTICE

- Does average leader authoritarianism decrease over time?
- Does the stepdown rate decrease as wrong fey stop seeking power?
- Do leadership tenures increase as the system stabilizes?
- What's the distribution of traits among successful long-term leaders?

## THINGS TO TRY

**Experiment 1 - Baseline:** Use default settings. Does authoritarianism decrease?

**Experiment 2 - Breaking Point:** Set authoritarianism-penalty-factor to 0.3. Can authoritarians now survive?

**Experiment 3 - Hierarchy Shape:** Compare agents-per-leader-ratio of 5 vs 20. Which produces better filtering?

## EXTENDING THE MODEL

Possible extensions:
- Add learning: Agents observe who succeeds/fails
- Add corruption: Leaders can reduce humiliation illegitimately
- Add coalition-building: Agents cooperate to get promoted
- Make traits dynamic: Power increases authoritarianism

## NETLOGO FEATURES

Uses agent-based modeling to simulate emergent political selection dynamics with immediate succession mechanics.

## RELATED MODELS

This model tests political philosophy through simulation. Related systems from the Handbook:
- Dracodemocracy (dragons eat bad leaders)
- Fat Dracodemocracy (dragons eat bad voters too)
- Magocracy (wizard power determines hierarchy)

## CREDITS AND REFERENCES

Based on Queen Amethyst's "Handbook of Experimental Social Engineering"

Model implements population-proportional leadership positions and immediate promotion-on-vacancy mechanics for realistic organizational dynamics.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
