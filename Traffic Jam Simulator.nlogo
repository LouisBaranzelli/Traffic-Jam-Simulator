; gerer les acceleration  a gauche

turtles-own [
speed; Speed at the instant t of the car. unit : 0.1 = 10 m/s = 36 km/h
nominal_speed ; Initial speed value of the car :  0.1 = 10 m/s = 36 km/h

distance_myneighbor ; distance (m) of the closest car ahead and on the same way : 1 unit in this world = 10m
reaction_time ; Must reach 10 ticks ( 1 second) before to trigger the brake in case of danger
is_braking ; if 1 indicate the car is braking else 0.
braking_distance ; Minimum distance to break, can not be set if the car is braking.
is_accelerating ; if 1 indicate the car is accelerating else 0
is_accident ;  if 1 indicate the car has an accident else 0
 possible_right_way ; id of the way autorized to go when turning right [4, 7, 10]
is_turning_right ; if 1 indicate the car is turning right else 0
possible_left_way ; id of the way autorized to go when turning left [1, 4, 7]
is_turning_left ; if 1 indicate the car is turning left else 0
timer_turn ; requires the car to wait before turning again
interdistance ; distance for braking + reaction time
driver_attitude ; random parameter avg 1 standart deviation 0.15 that influence all the variable to simulate different attitude. ; More than 1 is safer
]


globals [way ; Abcisse possible where cars spawn  [1, 4, 7, 10]
flow_car_min ; Average flow of cars / minute
avg_speed ; Average speed of cars / minute
nbr_accident ; Number of accident
accident_per_car ; Ration accident / per car
total_car ; Number of cars that are spawned
total_car_target ; Number of cars that should have spawned according to the target
avg_time_in_jam_per_car] ; Average time in minute / car in traffic Jam


to-report scale_speed_km_h [speed_km_h]
; Scale speed in km/h to match with the unit of the simulation
; 10 clock = 1 second
; height of the world = 1 km
  report 0.1 * 0.1 * speed_km_h / 3.6
end

to-report round_0_1 [figure]
; 0.168970 -> 0.1
  report ceiling(figure * 10) / 10
end


to-report scale_speed_m_s [speed_m_s]
; Scale speed in m/s to match with the unit of the simulation
; 10 clock = 1 second
; height of the world = 1 km
  report 0.1 * 0.1 * speed_m_s
end

to set_distance_closest_car_ahead [this_car]
  ; Update the distance of the closest car ahead in m
  ; update the variable distance_myneighbor
  ; If no car ahead distance of the closest = 3 x safety distance

  let x_car [xcor] of this_car
  let y_car [ycor] of this_car
  let first_car 0 ; 1st car on the way where there is no distance with the next one because the first.

  let car_ahead turtles with [xcor = x_car AND ycor > y_car] ; Cars on the same way AND Ahead
  if count car_ahead = 0 [ask this_car [set distance_myneighbor 3 * guess_braking_distance_speed(avg_speed)]] ; if no car ahead depends of the average speed
  if count car_ahead > 0 [ ; if there is car ahead
    set car_ahead car_ahead with-min [ distance this_car ] ; select the the closest car ahead
    ask this_car [set distance_myneighbor 10 * distance one-of car_ahead]; set the parameter ; reminder : 1 = 10 m
  ]
end


to-report guess_safety_distance [this_car]
; Define the minmum braking distance to reach 0 km/h
; input object car
; No reaction time here, just the speed of the car is used
; result in m
; 50 km/h -> 12m

  let speed_of_this_car_ms 100 * [speed] of this_car
  let v0_ms speed_of_this_car_ms

  let distance_mini 0.0664 * speed_of_this_car_ms * speed_of_this_car_ms + -0.0631 * speed_of_this_car_ms + 0.4693 + v0_ms + 3
  if distance_mini < 9 [set distance_mini 9]

  report distance_mini
end


to-report guess_braking_distance [this_car]
; Define the minmum braking distance to reach 0 km/h
; input object car
; No reaction time here, just the speed of the car is used
; result in m
; 50 km/h -> 12m

  let speed_of_this_car_ms 100 * [speed] of this_car
  let distance_mini 0.0664 * speed_of_this_car_ms * speed_of_this_car_ms + -0.0631 * speed_of_this_car_ms + 0.4693 + 3
  if distance_mini < 7 [set distance_mini 7]
  report distance_mini

end

to-report guess_braking_distance_speed [speed_car]
; Define the minmum braking distance to reach 0 km/h
; input value of speed
; No reaction time here, just the speed of the car is used
; result in m
; 50 km/h -> 12m

let speed_of_this_car_ms 100 * speed_car
let distance_mini 0.0664 * speed_of_this_car_ms * speed_of_this_car_ms + -0.0631 * speed_of_this_car_ms + 0.4693 + 3
if distance_mini < 7 [set distance_mini 7]
  report distance_mini

end

to turn_left[this_car]
; gives the car permission to turn left

  let distance_closest_car_behind_left 0 ; Initialize the distance of the closest car behind on the left way
  let distance_closest_car_ahead_left 0 ; Initialize the distance of the closest car ahead on the left way
  let time_between_cars_behind_s 0 ; Time between cars with the closest car behind on the left way according to the delta speed  (in second)
  let time_between_cars_ahead_s 0 ; Time between cars with the closest car ahead on the left way according to the delta speed  (in second)
  let delta_speed 0; difference of speed between car
  let x_car [ceiling(xcor * 10) / 10] of this_car ; abcis of the car
  let y_car [ycor] of this_car ; Ordone of the car
  let car_on_leftway turtles with [xcor = x_car - 3] ; Set of car on the left way of this_car
  let car_on_the_same_way turtles with [xcor = x_car]  ; Set of car on the same way of this_car
  let car_blind_spot 0 ; Quantity of car in the blind spot
  let coef [driver_attitude] of this_car
  let y_ahead_blind_spot  coef * 2.5  ; delta distance  between car and this limit ahead where no car must be to have autorisation to turn left
  let y_behind_blind_spot  coef * 2.5 ; delta distance between car and this limit behind where no car must be to have autorisation to turn left


  ;Indicates the possible roads on which to deport depending on the road on which the car is
  if x_car = 10 [ask this_car [ set possible_left_way 6 set is_turning_left 0]]
  if x_car = 7 [ask this_car [ set possible_left_way 3 set is_turning_left 0]]
  if x_car = 4 [ask this_car [ set possible_left_way 0 set is_turning_left 0]]
  if x_car = 1 [ask this_car[set is_turning_left 0]]

  ; Calculate the speed of the car ahead
  let speed_car_ahead 0
  let car_on_the_same_way_ahead car_on_the_same_way with [ycor > y_car] ; car ahead but not in the blind spot
  if count car_on_the_same_way_ahead = 0 [set speed_car_ahead 1000] ; if no car ahead by default the value is very hight -> wont be taken in consideration
  if count car_on_the_same_way_ahead > 0 [
    set car_on_the_same_way_ahead car_on_the_same_way_ahead with-min [ distance this_car ]  ; select the the closest car behind
    set speed_car_ahead [speed] of one-of car_on_the_same_way_ahead
  ]
    ; ------------------------------------------------------


  ; Estimate the time available with  the car approaching from the left rear
  ; How fast is the car approaching from the left rear STEP 1
  let car_behind car_on_leftway with [ycor < y_car - y_behind_blind_spot]  ; set of car on the left way of this_car + behind the blind spot.
  if count car_behind = 0 [set distance_closest_car_behind_left 1000] ; if no car ahead by default the value is very hight -> wont be taken in consideration
  if count car_behind > 0 [ ; if there is car behind
    set car_behind car_behind with-min [ distance this_car ] ; select the the closest car behind
    set distance_closest_car_behind_left y_car - [ycor] of one-of car_behind
    set delta_speed [speed] of this_car - [speed] of one-of car_behind ; estimate the delta speed between the both cars
  ]

   ; Estimate the time available with  the car approaching from the left rear STEP 2
  if delta_speed >= 0 [set time_between_cars_behind_s 1000] ; if the car behind is slower ->  by default the value is very hight -> wont be taken in consideration
  if delta_speed < 0 [ ; if the car on the left getting closer, estimate time available
    set time_between_cars_behind_s 0.1 * distance_closest_car_behind_left / abs(delta_speed)
  ]
  ; ------------------------------------------------------

  ; Estimate the time available with  the car approaching from the left ahead
  ; How fast is the car approaching from the left ahead STEP 1
  let car_ahead car_on_leftway with [ycor >= y_car  + y_ahead_blind_spot]  ; set of car on the left way of this_car + ahead
  if count car_ahead = 0 [set distance_closest_car_ahead_left guess_braking_distance(this_car)] ; if no car ahead by default the value is very hight -> wont be taken in consideration
  if count car_ahead > 0 [ ; if there is car ahead
    set car_ahead car_ahead with-min [ distance this_car ] ; select the the closest car car_ahead
    set distance_closest_car_ahead_left [ycor] of one-of car_ahead - y_car; estimate the distance between the both cars
    set delta_speed [speed] of one-of car_ahead - [speed] of this_car ; estimate the delta speed between the both cars
  ]

  ; Estimate the time available with  the car approaching from the left rear STEP 2
  if delta_speed >= 0 [set time_between_cars_ahead_s 1000] ;  if the car ahead is quicker ->  by default the value is very hight -> wont be taken in consideration
  if delta_speed < 0 [ ; if the car on the left ahead getting closer
    set time_between_cars_ahead_s 0.1 * distance_closest_car_ahead_left / abs(delta_speed)
  ]
  ; ------------------------------------------------------

  ; Are there cars in the blind spot?
  let x_lim_left 0 ; Limit of the roads taken into consideration to estimate the presence of cars in the blind spots

  if x_car = 1 [set x_lim_left 0]
  if x_car = 4 [set x_lim_left 0]
  if x_car = 7 [set x_lim_left 4]
  if x_car = 10 [set x_lim_left 7]

  set car_blind_spot turtles with [ycor <= y_car + y_ahead_blind_spot AND
    ycor >= y_car - y_behind_blind_spot AND
    xcor < x_car AND
    x_car >=  x_lim_left]  ; set of car un the blind spot

    ; ------------------------------------------------------

  ; Are there any cars in the left lane that simultaneously turn right?
  ; Section of the way taken in consideration + turning right
  let car_on_left_is_turning_right turtles with [ycor <= y_car + 2 AND
    ycor >= y_car - 2 AND
    xcor < x_car AND
    is_turning_right = 1]
  ; ------------------------------------------------------

  ; Are there any cars behind that simultaneously turn left ?
  let car_close_is_turning_left turtles with [ycor <= y_car + 5 AND
    ycor > y_car - 5 AND
    xcor <= x_car AND
    xcor >= x_lim_left + 0.1]
  set car_close_is_turning_left car_close_is_turning_left with-min [ distance this_car ]
  set car_close_is_turning_left car_close_is_turning_left with [is_turning_left = 1]
  ; ------------------------------------------------------

 ; Turn left if :
  if [speed] of this_car  <  [nominal_speed] of this_car  AND ; The nominal speed of this car is  lower than it nominal speed
  speed_car_ahead < [nominal_speed] of this_car AND  ; The nominal speed of this car is really higher than the speed of the car ahead
  time_between_cars_behind_s > coef * 6 AND ; Give 6 seconds at least to the car behind left to break
  time_between_cars_ahead_s > coef * 5 AND ; Has at least 5 seconds to get into the left lane
  ;360 * [speed] of this_car > 0.35 * avg_speed AND ;
  (x_car = 4 OR x_car = 7 or x_car = 10) AND ; Must be on one of these 3 ways to initiate the turning left
  [timer_turn] of this_car > 100 AND ; Need to wait at least 10 seconds before to turn again -> timer_turn
  ; distance_myneighbor <= 100 AND ; If the car ahead very far no need to turn left
  count car_on_left_is_turning_right = 0 AND ; No car simultenaously turning right around
  [is_turning_right] of this_car = 0 AND ; Can not turn left if the car is turning right.
  count car_close_is_turning_left = 0 AND ; The car behind is no turning left.
  count car_blind_spot = 0  AND ; No car in the blind spot.
   y_car < 90 AND; No turning possible the last 100m
   y_car > 8  [; No turning possible the first 80 m

    ask this_car [
      set xcor round_0_1(xcor - 0.1); turn left
      set is_turning_left 1; Indicate that turn left is in process
      set timer_turn 0 ; reset the timer to turn again
      ]
  ]

  set x_car [round_0_1(xcor)] of this_car ; Update the value x_car because car mooved left
  ; if start to turn left, keep turning left till the end (no need to go threw the previous conditions)
  if [is_turning_left] of this_car = 1  [ask this_car [set xcor round_0_1(xcor - 0.11)]]; turning left
end


to turn_right[this_car]
; gives the car permission to turn right

  let delta_speed 0
  let distance_closest_car_behind_right 0 ; Initialize the distance of the closest car behind on the right way
  let distance_closest_car_ahead_right 0 ; Initialize the distance of the closest car ahead on the right way
  let time_between_cars_behind_s 0 ; Time between cars with the closest car behind on the right way according to the delta speed  (in second)
  let time_between_cars_ahead_s 0 ; Time between cars with the closest car ahead on the left way according to the delta speed  (in second)
  let x_car  [round_0_1(xcor)] of this_car
  let y_car [ycor] of this_car
  let car_on_rightway turtles with [xcor = x_car + 3]; Set of car on the right way of this_car
  let coef [driver_attitude] of this_car
  let y_ahead_blind_spot 0.1 * coef * [braking_distance] of this_car + 1 ; delta distance  between car and this limit
  let y_behind_blind_spot  coef * 1.5; (20 m) delta distance between car and this limit behind where no car must be to have autorisation to turn left

  let car_blind_spot 0 ; quantity of car in the blind spot


  ask this_car [set timer_turn timer_turn + 1] ; increase the counter to give then, the autorisation to turn either right or left

  ; Indicates the possible roads on which to deport depending on the road on which the car is
  if x_car = 1 [ask this_car [ set is_turning_right 0]]
  if x_car = 4 [ask this_car [ set is_turning_right 0]]
  if x_car = 7 [ask this_car [ set is_turning_right 0]]
  if x_car = 10 [ask this_car[set is_turning_right 0]]


  ; Estimate the time available with  the car approaching from the right rear
  ; How fast is the car approaching from the right rear STEP 1
  let car_behind car_on_rightway with [ycor < y_car - y_behind_blind_spot] ; set of car on the right way of this_car
  if count car_behind = 0 [set distance_closest_car_behind_right 10000]  ; if no car ahead by default the value is very hight -> wont be taken in consideration
  if count car_behind > 0 [ ; if there is a car.
    set car_behind car_behind with-min [ distance this_car ] ; select the the closest car behind
    set distance_closest_car_behind_right y_car - [ycor] of one-of car_behind ; Define the distance of the closest car behind
    set delta_speed [speed] of this_car - [speed] of one-of car_behind ; estimate the delta speed between the both cars
  ]

   ; Estimate the time available with  the car approaching from the right rear STEP 2
  if delta_speed >= 0 [set time_between_cars_behind_s 10000] ; if the car behind is slower ->  by default the value is very hight -> wont be taken in consideration
  if delta_speed < 0 [ ; if the car on the right getting closer, estimate time available
    set time_between_cars_behind_s 0.1 * distance_closest_car_behind_right / abs(delta_speed)
  ]
  ; ------------------------------------------------------

  ; Estimate the time available with  the car approaching from the right ahead
  ; How fast is the car approaching from the right ahead STEP 1
  let car_ahead car_on_rightway with [ycor > y_car + y_ahead_blind_spot]  ;  set of car on the right way of this_car + ahead
  if count car_ahead = 0 [set distance_closest_car_ahead_right guess_braking_distance(this_car)];  if the car ahead is quicker ->  by default the value is very hight -> wont be taken in consideration
  if count car_ahead > 0 [ ; if there is car ahead
    set car_ahead car_ahead with-min [ distance this_car ] ; select the the closest car car_ahead
    set distance_closest_car_ahead_right [ycor] of one-of car_ahead - y_car; estimate the distance between the both cars
    set delta_speed [speed] of one-of car_ahead - [speed] of this_car ; estimate the delta speed between the both cars
  ]

  ; Estimate the time available with  the car approaching from the left rear STEP 2
  if delta_speed >= 0 [set time_between_cars_ahead_s 10000] ; if the car ahead is quicker ->  by default the value is very hight -> wont be taken in consideration
  if delta_speed < 0 [ ;if the car on the right ahead getting closer, estimate time available
    set time_between_cars_ahead_s 0.1 * distance_closest_car_ahead_right / abs(delta_speed)
  ]
  ; ------------------------------------------------------

  ; Are there cars in the blind spot?
  ; Limit of the roads taken into consideration to estimate the presence of cars in the blind spots
  let x_lim_right 0 ;
  if x_car = 1 [set x_lim_right 4]
  if x_car = 4 [set x_lim_right 7]
  if x_car = 7 [set x_lim_right 10]
  if x_car = 10 [set x_lim_right 10]

  set car_blind_spot turtles with [ycor <= y_car + y_ahead_blind_spot AND
    ycor >= y_car - y_behind_blind_spot AND
    xcor > x_car and xcor <= x_lim_right]
  ; ------------------------------------------------------

  ; Are there any cars in the right lane that simultaneously turn left?
  ; Section of the way taken in consideration + turning left
  let car_on_right_is_turning_left turtles with [ycor <= y_car + 2 AND
    ycor >= y_car - 2 AND
    xcor > x_car AND
    is_turning_left = 1]
  ; ------------------------------------------------------

  ; Are there any cars behind that simultaneously turn left ?
  let car_close_is_turning_right turtles with [ycor <= y_car + 5 AND
    ycor > y_car - 5 AND
    xcor >= x_car AND
    xcor <= x_lim_right - 0.1]
  set car_close_is_turning_right car_close_is_turning_right with-min [ distance this_car ]
  set car_close_is_turning_right car_close_is_turning_right with [is_turning_right = 1]

 ; Turn right if :
  if time_between_cars_behind_s > coef * 5 AND ; Give 4 seconds at least for the car behind right to break
  ;[speed] of this_car > scale_speed_km_h(4) AND ; Can not turn if the car is to slow
  time_between_cars_ahead_s > coef * 10 AND ; No need to turn right if the car ahead right is close (in time to reach it)
  (x_car = 1 OR x_car = 4 OR x_car = 7) AND ; Must be on one of these 3 ways to initiate the turning right
  [timer_turn] of this_car > 100 AND ; Need to wait at least 10 second before to turn again
  ;[is_turning_left] of this_car = 0 AND ; can not turn left if the car is turning right.
  count car_on_right_is_turning_left = 0 AND ; No car simultenaously turn on the opposite direction
  count car_close_is_turning_right = 0 AND ; The car behind is no turning in the same direction than me
  count car_blind_spot = 0  AND ; No car in the blind spot.
  y_car < 90 AND; No turning possible the last 90m
  y_car > 8 [ ;  can not turn the first 80 m of the experience
    ask this_car
      [set xcor round_0_1(xcor + 0.1)] ; turn right
       set is_turning_right 1 ; Indicate that turn right is in process
       set timer_turn 0] ; reset the timer to turn again

  ; if start to turn right, keep turning right till the end
  if [is_turning_right] of this_car = 1 [ask this_car [set xcor round_0_1(xcor + 0.1)] ] ; turning right

end


to update_acceleration

  ; trigger the acceleration of the deceleration of the car

  ask turtles [
     let x_car xcor
     let y_car ycor
     let speed_car speed

  ; Is the car ahead  is braking / slow ?
  let car_ahead_is_braking 0
  let car_ahead turtles with [xcor = x_car
      AND ycor > y_car ]

  if count car_ahead = 0 [set car_ahead_is_braking 0] ; if no car no preventive braking
  if count car_ahead > 0 [
    set car_ahead car_ahead with-min [ distance self ] ; select the the closest car ahead
    ask car_ahead [ ; check if the car ahead is braking
        set car_ahead_is_braking 0
        if (is_braking = 1) OR ;if the car ahead is braking
        (is_accident = 1) OR ; if the car ahead has an accident
         speed_car - speed > scale_speed_km_h(40) OR ; if relative speed of the car ahead is to important
        ;(is_turning_right = 1) OR ; if the car ahead comming from left
        speed < scale_speed_km_h(50) ; Car slow
        [
          set car_ahead_is_braking 1
        ]
      ]
    ]
   ; ------------------------------------------------------


    ; do not update the braking distance if the car is braking
    if is_braking = 0 [
      set braking_distance 1 * driver_attitude * guess_braking_distance(self)
      set interdistance  driver_attitude * guess_safety_distance(self)
    ]

    ; Define if the car ahead is getting clother
    let previous_distance_closest_car [distance_myneighbor] of self; save previous value of the closest car.

    set_distance_closest_car_ahead(self) ; update parameter of distance of the closest car ahead.


    ; evolution of the distance between both cars :
    ; if delta_distance < 0 : distance decreasing and car getting clother
    let delta_distance  [distance_myneighbor] of self - previous_distance_closest_car ;
    set delta_distance precision delta_distance 2 ; 1,3344556 = 1,33
  ; ------------------------------------------------------

    ; Reaction time
    ; Should the car reset the reaction time ?
    if delta_distance > 0 AND ; getting further of the car ahead
    [distance_myneighbor] of self > guess_braking_distance(self) ; not in the security distance behind the car
    [
      set reaction_time 0 ; -> reactiontime reset 0
    ]

    ; the car notice a danger : need 10 ticks to start braking
    if delta_distance < 0  OR ; a car getting clother
    [distance_myneighbor] of self < 2 * braking_distance ; in a safety area
    [
      set reaction_time reaction_time + 1 ; Need 10 ticks = 1second to trigger the brake
    ]

    ; No need Reaction time in these two cases
    if (delta_distance < 0 AND ; if danger getting closer but very far from the car,
    [distance_myneighbor] of self > 3 * braking_distance) OR ;
    ([speed] of self < scale_speed_km_h(15)) ; car very slow
    [
      set reaction_time 100
    ]
  ; ------------------------------------------------------

    ; The car on right must brake a bit if quicker than the car on the left at the normal speed (more than 50 km/h)
    let car_ahead_left turtles with [xcor < x_car AND
      ycor > y_car - driver_attitude * 0.5  AND
      ycor < y_car + driver_attitude * 0.5 AND
      speed_car > scale_speed_km_h(50) AND
      speed_car > speed - scale_speed_km_h(2)]

    let braking_car_left 0
    if count car_ahead_left = 0 [set braking_car_left  0]
    if count car_ahead_left != 0 [set braking_car_left 1] ; 100 for braking allow to brake very slowly
  ; ------------------------------------------------------

    set is_braking 0 ; by default the car is not braking
    set is_accelerating 0 ; by default the car is not accelerating

  ; Trigger the break if:
    if (car_ahead_is_braking = 1 AND ; Danger getting closer
      reaction_time >= 10 AND ; After 1 second
      [distance_myneighbor] of self <  driver_attitude * 1.2 * [interdistance] of self) ; at 1.2 * braking distance

    ; Minimum distance before to brake with no danger and speed normal :
    OR (reaction_time >= 10 AND ; After 1 second
      [speed] of self >= scale_speed_km_h(10) AND ; with aminimum speed
      [distance_myneighbor] of self <  driver_attitude * 1 * [braking_distance] of self  ) ; minimum distance before to trigger the break

    ; Minimum distance before to brake with no danger and speed low :
   OR   ([speed] of self < scale_speed_km_h(30) AND ; if very low speed
      [distance_myneighbor] of self < driver_attitude * 0.8 * [interdistance] of self) ;  small distance before braking
    [
      set_deceleration self abs(delta_distance) ; brake with a lavel depending of the distance available
      set is_braking 1 ; Indicate that the car is braking
    ]

    if (braking_car_left != 0) ; If car on a left side quicker
    [
      set_deceleration self 1 ; brake
      set is_braking 1 ; Indicate that the car is braking
    ]


    if delta_distance >= 0 [set is_braking 0 ] ; if the distance between anything ahead is getting more important stop the breaking

    ; Step 2 : Should the car accelerate
    ; a car can accelerate if :
    ; - it speed < it nominal speed
    ; - not braking
      if [is_braking] of self = 0 AND
    [nominal_speed] of self > [speed] of self AND
    y_car < 99 ; No acceleration possible the last 100m
    [
      set_acceleration self
    ]
  ]
end


to set_acceleration [this_car]
  ; give the autorisation to accelerate of 3 m/s

  let delta_speed 0
  let x_car [xcor] of this_car
  let y_car [ycor] of this_car
  let car_ahead turtles with [xcor = x_car AND ycor > y_car] ; set of car on the same way ahead of this_car
  let distance_closest_car_ahead 0
  let coef [driver_attitude] of this_car

 ; Calculation of the delta speed
  if count car_ahead = 0 [
    set distance_closest_car_ahead 10000 ; if no car set at 1000
    set delta_speed -10000 ; condition necessary to accelerate -> no impact because no car
  ]

  if count car_ahead > 0 [; if there is car ahead
    set car_ahead car_ahead with-min [ distance this_car ] ; select the the closest car car_ahead
    set distance_closest_car_ahead [ycor] of one-of car_ahead - y_car; delta distance with the closest car
    set delta_speed [speed] of this_car - [speed] of one-of car_ahead ; estimate the delta speed between the both cars, if >0 -> this id quicker already so no need to accelerate
  ]

  if delta_speed < scale_speed_km_h(20) AND ; car ahead quicker or a bit slower of 5 km/h
    distance_closest_car_ahead > coef * 1.2 * 0.1 * [braking_distance] of this_car AND ; accelerate if more than 1 x braking distance allow to brake and accelerate to get closer of the car
    distance_closest_car_ahead > 0.7 AND; absolu minimum distance = 6m
   [is_turning_right] of this_car = 0
  [ask this_car [
      set is_accelerating 1
      set speed speed + coef * scale_speed_km_h(3) * 0.1] ; increasing the speed
  ]
end

to set_deceleration [this_car closing_speed_mtick]

  ; Estimate the braking
  ; formula fo the descelation / s (deceleration_estimated_s) = (speed_getting closer in m/s)^2 / (distance between 2 car - interdistance of security)

  let closing_speed_ms closing_speed_mtick * 10 ; conversion in m/s
  let coef [driver_attitude] of this_car
  let distance_braking_car [distance_myneighbor] of this_car -  [braking_distance] of this_car ; distance available for the braking = distance - 3m
  let deceleration_estimated_s 0

  if distance_braking_car < 0 [
    let delta_distance_m_to_go_in_safety [interdistance] of this_car - [distance_myneighbor] of this_car ; distance to go in safety (in m)
    let delta_speed_back_in_safety_ms delta_distance_m_to_go_in_safety / 3; must be reach in 3 second
    set deceleration_estimated_s  delta_speed_back_in_safety_ms ; just copy
    if deceleration_estimated_s > 11 [set deceleration_estimated_s 11]; 11.1 is the deceleration maximum possible
    set deceleration_estimated_s floor coef * deceleration_estimated_s] ; a bad driver will brak more brutally

    ;set deceleration_estimated_s (1 / coef) * 9
  ;]; if car closer than 3m -> braking max = 9 m/s


  if distance_braking_car > 0[ ; if car located at a distance > 3m  -> braking must be calculated
    let delta_t distance_braking_car / (closing_speed_ms + 0.0000001)
    set deceleration_estimated_s floor(closing_speed_ms / delta_t)

    if deceleration_estimated_s > 11 [set deceleration_estimated_s 11]; 11.1 is the deceleration maximum possible
    set deceleration_estimated_s floor coef * deceleration_estimated_s] ; a bad driver will brak more brutally

    if deceleration_estimated_s < 3 [set deceleration_estimated_s 3] ; deceleration mini 3 m/s
  let deceleration_estimated_tick  0.1 * scale_speed_m_s(deceleration_estimated_s)  ; conversion of the speed in m/tick


  ask this_car [
    set speed speed - deceleration_estimated_tick ; braking
    if speed < 0 [set speed 0]; impossible to have a speed below 0
  ]

end

to check_accident
  ; if this car share the same y size +/- 2m and the same x cor (one the same way
  ; both cars stop speed set 0
  ; color car -> red

  ask turtles[
    let x_car xcor
    let y_car ycor

    let car_on_thisway turtles with [xcor = x_car] ; set of car on the same way of this_car
    let car_too_close car_on_thisway with [ycor < y_car + 0.1 AND ycor > y_car - 0.1]  ; set of car at +/- 2m on the same way of this car, remind: 1 unit = 10m
    ; show distance_myneighbor
    if count car_too_close > 1 [  ; if there is an accident


      set is_accident 1
      set nbr_accident nbr_accident + 1
      ask car_too_close [ ; Car bumped is stopped
        set nbr_accident nbr_accident + 1
        die ;set speed 0
        ;set speed 0
       ]
      if nbr_accident != 0 [set accident_per_car total_car / nbr_accident]
      if nbr_accident = 0 [set accident_per_car 0]

      ; Car which bumped the car also stopped

      set is_accident 1
      ]
     ]
end

to update_color_car
  ask turtles[

    if is_braking = 0 [set color green]
    if is_accelerating = 1 [set color blue]
    if is_braking = 1 [set color yellow]
    if speed < 0.01  [set color pink]
    if is_accident = 1 [set color red]
  ]
end

to setup
  resize-world 0 11 0 100 ; distance in m * 10
  clear-all

  ; the first car appear with the nominal speed, then depends of the average speed
  ;set_new_car_test
  reset-ticks
  set way 1 ; abcisse of apparition of the car
end

to go
  move_cars ; cars go on according to their speeds
  check_accident ; check if there is accident
  update_acceleration ; modify the speed of the car if the car must brake or accelerate
  update_color_car ; update color of the car
  ask turtles [turn_right(self)]
  ask turtles [turn_left(self)]
  set_new_car ; new car appear at the flow indicated
  tick ; = 1/10 seconde clock go on
end


to move_cars
  let sum_speed 0
  ask turtles [

    ;set label driver_attitude;
    set label ceiling(speed * 360)
   set sum_speed sum_speed + [speed] of self ; definition of the average speed
   forward speed
   if ycor > 99 [ die ] ; When off the world delete the car
  ]
  if count turtles = 0 [set avg_speed avg_speed_target]
  if count turtles != 0 [set avg_speed round_0_1(sum_speed * 360 / count turtles)]
end


to set_new_car

  ; Create car with the flow indicated in the target

  let OFFSET_SPEED 0 ;OFFSET_SPEED allow to have car on the left quicker than on the right and keep the save average speed
  if way = 1 [set OFFSET_SPEED 2] ; OFFSET_SPEED in km/h
  if way = 4 [set OFFSET_SPEED 1] ; OFFSET_SPEED in km/h
  if way = 7 [set OFFSET_SPEED -1] ; OFFSET_SPEED in km/h
  if way = 10 [set OFFSET_SPEED -2] ; OFFSET_SPEED in km/h

  if random int(600 / FLOW_CAR_MIN_TARGET ) = 0 [ ; formula to reach the flow / min indicated in FLOW_CAR_MIN

    set total_car_target total_car_target + 1 ; total number of car according to the target
    if flow_car_min != 0 [set avg_time_in_jam_per_car total_car_target / flow_car_min]
    if flow_car_min = 0 [set avg_time_in_jam_per_car 0]
    set avg_time_in_jam_per_car round_0_1((avg_time_in_jam_per_car * 600 - ticks) / 600) ; estimatio nof the average time in the trafic jam / car
    if avg_time_in_jam_per_car < 0 [set avg_time_in_jam_per_car 0]

    ; check if there is enough place for a new car (depend of the average speed of the way on the first 150m)
    let distance_min 0
    if count turtles with [xcor = way AND ycor < 15] >= 1 [set distance_min  0.5] ; if there is few car, distance mini to spawn new car very small
    if count turtles with [xcor = way AND ycor < 15] > 6 [set distance_min  0.1 * guess_braking_distance_speed(mean [speed] of turtles with [xcor = way])] ; if lots of car: distance to pop new car depend of the speed of the car : more slow the car are car smaller the distace is
    if distance_min < 0.5 [set distance_min 0.5]  ; minimun distance remain 10 m

    let car_ahead turtles with [ycor < distance_min AND xcor = way]  ;
    ; let car_ahead turtles with [ycor < 40 AND xcor = 1]
    if count car_ahead = 0 [; Check that we have enough space at the begining -> if no : reduction of the flow

      ; estimate the flow of car
      let car_ahead_50 turtles with [ycor > 5] ; number of car the last 50 m (world finish at 990 m)
      set flow_car_min round_0_1(count car_ahead_50 * (avg_speed / 3.6) * 60 / 950); flow car / minute estinmated on the 950m

      let AVG_SPEED_KMH AVG_SPEED_TARGET + OFFSET_SPEED ; speed according to the way the car is
      let RANDOM_SPEED_KMH random-normal  AVG_SPEED_KMH 5; select a random speed
      let SPEED_SCALED_MS scale_speed_km_h(RANDOM_SPEED_KMH)  ; speed scaled to the world
      set total_car total_car + 1

      create-turtles 1 [
        set nominal_speed SPEED_SCALED_MS
        if count turtles with [xcor = way AND ycor < 5] != 0 [set speed 1 * mean [speed] of turtles with [xcor = way AND ycor < 5]]; the cars appear with the average speed of the cars in the same way of the first 50m
        if count turtles with [xcor = way AND ycor < 5] = 0 [set speed scale_speed_km_h(AVG_SPEED_TARGET)]
        set driver_attitude random-normal 1 0.1
        set shape "van top"
        setxy way 0
        set heading 0
        set reaction_time 10
        if speed > scale_speed_km_h (30) [set interdistance 1 * guess_braking_distance(self)]
        set distance_myneighbor 0 ; distance of the closest car arbitrary set at 0 at the bigining
        set is_accident 0] ; speed in m/s, /10 because of the world size, /10 because 1 tick = 1/10 sec
    ]

    if way = 10 [set way -2] ; create a loop
    set way way + 3; next car will appear on the next way on the right
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
112
65
363
2124
-1
-1
20.3
1
10
1
1
1
0
1
1
1
0
11
0
100
1
1
1
ticks
30.0

SLIDER
701
465
902
498
AVG_SPEED_TARGET
AVG_SPEED_TARGET
40
150
127.0
1
1
NIL
HORIZONTAL

BUTTON
435
137
513
170
NIL
SETUP
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
531
137
607
170
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
701
509
904
542
FLOW_CAR_MIN_TARGET
FLOW_CAR_MIN_TARGET
1
300
257.0
2
1
NIL
HORIZONTAL

PLOT
407
184
689
363
Average speed in km/h
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot avg_speed"

PLOT
409
379
690
583
flow_car_min
NIL
NIL
0.0
600.0
0.0
120.0
true
false
"" "flow_car_min"
PENS
"default" 1.0 0 -16777216 true "" "plot flow_car_min"

MONITOR
733
184
861
229
NIL
avg_speed
17
1
11

MONITOR
735
353
862
398
Car / way / hour
flow_car_min * 60 / 4
17
1
11

MONITOR
737
408
863
453
NIL
nbr_accident
17
1
11

MONITOR
734
295
860
340
Flow car / minute
flow_car_min
17
1
11

MONITOR
733
240
860
285
Minute in jam / car
avg_time_in_jam_per_car
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model simulates highway traffic. Based on an incoming car flow and a fixed speed, the model demonstrates when a traffic jam develops and estimates the waiting time for motorists.

The motorist appears on one of the 4 lanes in ordinate 0. You can consider this level as a junction of roads on which we try to pass a maximum number of cars. If the cars don't have enough space to spawn (5m minimum, but this distance depends on the average speed of the cars), they don't spawn and are considered blocked at the back of the road (not visible). But this number of excess cars with the flow of cars on the highway allow us to estimate the traffic jam time per car (Minute in jam / car)


## HOW IT WORKS

The cars follow the classic traffic rules:

- It pass only on the left.
- The fastest cars move into the left lane.
- The slowest cars go to the right lanes.
- The cars check their blind spots as well as the relative speeds of other motorists to see if the deportation on the right or the left is possible.

- An interdistance is calculated based on the braking distance given by the following formula:

interdistance = braking distance + reaction time

with :
reaction time = initial speed (m/s)
braking distance = 0.0664 * speed * speed +  -0.0631 * speed + 3,469

with braking distance in m and speed in m/s

The nominal speed of the cars follows a normal law of average speed indicated in parameter (standard deviation = 5). The nominal speed is kept and during the passage of the car in the route, it will always try to approach it.


The cars appear to try to reach the fixed rate in parameter. If there is not enough space for a car to appear, it is counted to estimate the size of the traffic jam that is virtually forming at the rear.

The cars on the left are a bit faster in rated speed than the cars on the right.

The labels on the cars indicate their speeds in km/h.
A color code identifies their behavior:

	green: regular
	blue: speed up
	yellow: brakes
	pink: very slow
	red: accident

In the event of an accident, the car disappears so as not to disturb the simulation, but the accident count is kept.

Cars maintain a safe distance based on their speed and adapt their behavior to the cars around them:
- Is the car in front faster, does it brake?
- Am I faster than the car on the left?
- Is the car behind turning?

Each drive as his own attitude equivalent to an indice equal to a normal distibution (avg 1 and sigma 0.1). All the  distance and speed limit are multiplied by this coef and make each reaction of the drivers unique.


## IN THE CODE

The scales used in the code are specific:

- 10 ticks = 1 seconds
- The baking distances are in (m)
- The coordinate differences using ycor are such that ycor1 - ycor2 = 1 = 10m
- speed = 1 (in the simulation) = (1 * 360) km/h in reality = 100 m/s.
- The height of the road from top to bottom: 100 units = 1km


## HOW TO USE IT

Set the setpoint of the car flow / minute and the desired speed. If the traffic is fluid the average speed will reach the fixed speed and no traffic jam time will be counted.

If you want the cars to drive at 70 km/h, set the nominal speed to 100 km/h

The evolution of the average speed and the flow are represented on graphs.

## THINGS TO NOTICE

It is difficult to obtain a throughput of more than 2000 car/hour/road (130 car/minute for this 4-lane highway). This is what we observe in reality. The ideal speed is around 70 km/h.

Note the evolution of the traffic jam time which evolves.


## SHARE THIS WORK
Possible


## AUTHOR
Louis Baranzelli
first version the 12/03/23

 
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

van top
true
0
Polygon -7500403 true true 90 117 71 134 228 133 210 117
Polygon -7500403 true true 150 8 118 10 96 17 85 30 84 264 89 282 105 293 149 294 192 293 209 282 215 265 214 31 201 17 179 10
Polygon -16777216 true false 94 129 105 120 195 120 204 128 180 150 120 150
Polygon -16777216 true false 90 270 105 255 105 150 90 135
Polygon -16777216 true false 101 279 120 286 180 286 198 281 195 270 105 270
Polygon -16777216 true false 210 270 195 255 195 150 210 135
Polygon -1 true false 201 16 201 26 179 20 179 10
Polygon -1 true false 99 16 99 26 121 20 121 10
Line -16777216 false 130 14 168 14
Line -16777216 false 130 18 168 18
Line -16777216 false 130 11 168 11
Line -16777216 false 185 29 194 112
Line -16777216 false 115 29 106 112
Line -7500403 false 210 180 195 180
Line -7500403 false 195 225 210 240
Line -7500403 false 105 225 90 240
Line -7500403 false 90 180 105 180

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
NetLogo 6.3.0
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
