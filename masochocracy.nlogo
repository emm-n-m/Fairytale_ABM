breed [agents agent]

agents-own [
  competence           ; 0-100: ability/skill level
  authoritarianism     ; 0-100: desire to dominate others
  humiliation-tolerance ; calculated from competence and authoritarianism
  perceived-humiliation ; current humiliation accumulated
  leadership-level      ; 0 = no leadership, higher = more authority
  time-in-position      ; ticks spent in current leadership position
  times-promoted        ; career counter
  times-stepped-down    ; career counter
]

globals [
  total-promotions
  total-stepdowns
  avg-leader-competence
  avg-leader-authoritarianism
  leadership-pyramid  ; list of target counts per level
]

to setup
  clear-all
  set total-promotions 0
  set total-stepdowns 0
  
  ; Calculate leadership pyramid: each level has fewer positions
  ; Level 0 = regular workers (no leadership)
  ; Level 1 = 1 position per X agents (frontline supervisors)
  ; Level 2 = 1 position per X^2 agents (middle management)
  ; etc.
  set leadership-pyramid []
  let level 1
  let positions-at-level floor (num-agents / agents-per-leader-ratio)
  
  while [positions-at-level >= 1] [
    set leadership-pyramid lput positions-at-level leadership-pyramid
    set level level + 1
    set positions-at-level floor (positions-at-level / agents-per-leader-ratio)
  ]
  
  create-agents num-agents [
    set competence random-float 100
    set authoritarianism random-float 100
    update-humiliation-tolerance
    set perceived-humiliation 0
    set leadership-level 0
    set time-in-position 0
    set times-promoted 0
    set times-stepped-down 0
    
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
  ask agents [
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
  ask agents [update-appearance]
  
  tick
end

to accumulate-humiliation
  ; Humiliation comes from subordinates exercising dominance
  ; Amount depends on number of subordinates and their assertiveness
  let subordinate-count count agents with [leadership-level = [leadership-level] of myself - 1]
  
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
end

to fill-leadership-pyramid
  ; Initial filling of all leadership positions
  let level 1
  foreach leadership-pyramid [ target-count ->
    let current-count count agents with [leadership-level = level]
    let needed target-count - current-count
    
    if needed > 0 [
      ; Find candidates from level below
      let candidates agents with [leadership-level = level - 1]
      
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
    let current-count count agents with [leadership-level = vacant-level]
    
    if current-count < target-count [
      ; Find candidates from level below
      let candidates agents with [leadership-level = vacant-level - 1]
      
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
  set color scale-color blue leadership-level (max-level + 1) 0
  
  ; Size based on competence
  set size 0.5 + (competence / 100) * 1.5
  
  ; Shape indicates if under stress
  ifelse perceived-humiliation > (humiliation-tolerance * 0.8) [
    set shape "person business"  ; stressed leader
  ] [
    set shape "person"
  ]
end

to calculate-statistics
  let leaders agents with [leadership-level > 0]
  
  ifelse any? leaders [
    set avg-leader-competence mean [competence] of leaders
    set avg-leader-authoritarianism mean [authoritarianism] of leaders
  ] [
    set avg-leader-competence 0
    set avg-leader-authoritarianism 0
  ]
end

; Helper function for max-n-of
to-report max-n-of [n agentset reporter-task]
  let sorted-agents sort-on [(- runresult reporter-task)] agentset
  report turtle-set sublist sorted-agents 0 (min (list n length sorted-agents))
end
