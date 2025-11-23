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
  max-leadership-levels
  total-promotions
  total-stepdowns
  avg-leader-competence
  avg-leader-authoritarianism
]

to setup
  clear-all
  set max-leadership-levels 5
  set total-promotions 0
  set total-stepdowns 0
  
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
      step-down
    ]
  ]
  
  ; Promotion opportunities occur periodically
  if ticks mod promotion-frequency = 0 [
    conduct-promotions
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

to conduct-promotions
  ; Find agents eligible for promotion at each level
  let levels-list (range 0 max-leadership-levels)
  
  foreach levels-list [ current-level ->
    ; Count how many positions are available at next level
    let agents-at-next-level count agents with [leadership-level = current-level + 1]
    let positions-available max-leaders-per-level - agents-at-next-level
    
    if positions-available > 0 [
      ; Find candidates at current level
      let candidates agents with [leadership-level = current-level]
      
      if any? candidates [
        ; Calculate promotion score for each candidate
        ask candidates [
          ; Promotion driven by both will to dominate and competence
          ; But need to have enough humiliation tolerance to survive
          let promotion-score (authoritarianism * promotion-authoritarian-weight + 
                               competence * promotion-competence-weight)
          set label precision promotion-score 1
        ]
        
        ; Promote the top candidates who have positive humiliation tolerance
        let viable-candidates candidates with [humiliation-tolerance > 0]
        
        if any? viable-candidates [
          let to-promote min (list positions-available count viable-candidates)
          
          ask max-n-of to-promote viable-candidates [
            authoritarianism * promotion-authoritarian-weight + 
            competence * promotion-competence-weight
          ] [
            set leadership-level leadership-level + 1
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
  set color scale-color blue leadership-level max-leadership-levels 0
  
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
