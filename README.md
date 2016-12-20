# Multi-agent-pursuit-in-urban-evironment
This is a course project for the 'Distributed Systems &amp; Sensors' class I had taken at RPI. We called this project 'Catching Batman'.

## Introduction 
Consider an urban environment where there are many agents that move along a
grid-like network of roads to travel from some source location to some destina-
tion location. These cars are constrained to obey traffc laws, that is, their speed
is bounded by the speed limit, and they can only travel through intersections
In addition, there is a static network of sensors at each intersection that record
when a car passes through and what its velocity is at that time. Our problem
is that of pursuing a rogue agent traveling through the city with a set of drone
vehicles, which can be thought of as the police. These drones can communicate
with the stationary network and can be treated as mobile nodes within the net-
work. We assume that the stationary nodes are also capable of distinguishing
the rogue agent from the rest of the vehicles, and can pass this information to
the pursuing agents. The pursuing agents are further constrained to maintain
safety, that is, they will maintain some safe distance from other vehicles and will
not unsafely pass through red lights, whereas the rogue agent is not required to
follow these constraints.

In order to address the problem, we have the stationary network collect data
concerning the current location and movement direction of the rogue agent, as
well as current congestion levels on different sections of road, and make this
information available to the pursuing agents. A wireless sensor network demands implementation of protocols and algo-
rithms that make effective use of limited resources and counter the challenges
posed by their operating environment. The network in our case comprises many
static nodes and a few mobile nodes. The major limitation was the limited
battery power for the stationary nodes. In wireless sensor networks, communica-
tions takes the most amount of energy, so it is very essential to strike the right
balance between data processing and transmission of raw data. We assumed
that sensor nodes have the capability to do some amount of signal processing
before they forward or disseminate the data. The topology is such that one
can expect that at a particular time only a few stationary sensor will be in the
vicinity of a mobile sensor. This boosts the case for giving control on part of the
mobile nodes to initiate and fetch information from the stationary nodes. The
degree of mobility of the nodes is another factor that determined the effciency
of pursuit algorithms used. We have tested our algorithms by simulating the
system in MATLAB while varying different parameters of the simulation, such
as the starting location of the agents, the number of pursuers, the density of vehicles, the communication speed and range of sensors, etc. 


An example simulation is seen here: https://www.youtube.com/watch?v=HhI5zNiAhKU
