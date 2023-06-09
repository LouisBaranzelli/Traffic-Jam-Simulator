## ON WHICH PLATFORM IT WORKS?

download netlogo https://ccl.northwestern.edu/netlogo/download.shtml

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
- The braking distances are in (m)
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
copyright


## AUTHOR
Louis Baranzelli
first version the 12/03/23

 
