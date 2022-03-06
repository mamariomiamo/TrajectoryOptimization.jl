# TrajectoryOptimization

## Installation Procedure
### Install Julia
#### Ubuntu
Download Julia https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.5-linux-x86_64.tar.gz

Extract the folder `julia-1.6.5`, copy and paste to ~/Desktop.

**Add Julia to path**

`gedit .bashrc`, add to the following line to end of the file:
`export PATH="$PATH:/home/USER/Desktop/julia-1.6.5/bin"`

Replace `USER` with your username.

### Clone repository
`git clone git@github.com:RoboticExplorationLab/TrajectoryOptimization.jl.git`

OR `git clone https://github.com/RoboticExplorationLab/TrajectoryOptimization.jl.git` if you did not setup Github SSH.

### Checkout to correct branch
`git checkout distributed_team_lift`

### Activate and Instantiate project environment
`cd /TrajectoryOptimization.jl/examples/RA-L`

Start Julia in terminal `julia`

Go to package manager by pressing ] then `activate .` and then `instantiate`

Go back to julia and `include("distributed.jl")` to run the script.

### What is REPL?
Julia comes with a full-featured interactive command-line REPL (read-eval-print loop) built into the julia executable.

**--------------------------------------------------Everything is same as upstream after this-----------------------------------------------------------**

###

![Build Status](https://travis-ci.org/RoboticExplorationLab/TrajectoryOptimization.jl.svg?branch=master)
[![codecov](https://codecov.io/gh/RoboticExplorationLab/TrajectoryOptimization.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/RoboticExplorationLab/TrajectoryOptimization.jl)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://RoboticExplorationLab.github.io/TrajectoryOptimization.jl/dev)

A library of solvers for trajectory optimization problems written in Julia. Currently, the following methods are implemented with a common interface:

[ALTRO (Augmented Lagrangian TRajectory Optimizer)](https://rexlab.stanford.edu/papers/altro-iros.pdf): A fast solver for constrained trajectory optimization problems formulated as MDPs that features:
  * General nonlinear cost functions, including minimum time problems
  * General nonlinear state and input constraints
  * Infeasible state initialization
  * Square-root methods for improved numerical conditioning
  * Active-set projection method for solution polishing

Direct Collocation (DIRCOL)
  * Interfaces to Nonlinear Programming solvers (e.g., [Ipopt](https://github.com/coin-or/Ipopt), [SNOPT](https://ccom.ucsd.edu/~optimizers/solvers/snopt/)) via [MathOptInterface](https://github.com/JuliaOpt/MathOptInterface.jl)

All methods utilize Julia's extensive autodifferentiation capabilities via [ForwardDiff.jl](http://www.juliadiff.org/ForwardDiff.jl/) so that the user does not need to specify derivatives of dynamics, cost, or constraint functions. Dynamics can be computed directly from a URDF file via [RigidBodyDynamics.jl](https://github.com/JuliaRobotics/RigidBodyDynamics.jl).

## Installation
To install TrajectoryOptimization.jl, run the following from the Julia REPL:
```julia
Pkg.add("TrajectoryOptimization")
```

## Quick Start
To run a simple example of a constrained 1D block move:
```julia
using TrajectoryOptimization, LinearAlgebra

function dynamics!(ẋ,x,u) # inplace dynamics
    ẋ[1] = x[2]
    ẋ[2] = u[1]
end

n = 2 # number of states
m = 1 # number of controls
model = Model(dynamics!,n,m) # create model
model_d = rk3(model) # create discrete model w/ rk3 integration

x0 = [0.; 0.] # initial state
xf = [1.; 0.] # goal state

N = 21 # number of knot points
dt = 0.1 # time step

U0 = [0.01*rand(m) for k = 1:N-1]; # initial control trajectory

Q = 1.0*Diagonal(I,n)
Qf = 1.0*Diagonal(I,n)
R = 1.0e-1*Diagonal(I,m)
obj = LQRObjective(Q,R,Qf,xf,N) # objective

bnd = BoundConstraint(n,m,u_max=1.5, u_min=-1.5) # control limits
goal = goal_constraint(xf) # terminal constraint

constraints = Constraints(N) # define constraints at each time step
for k = 1:N-1
    constraints[k] += bnd
end
constraints[N] += goal

prob = Problem(model_d, obj, constraints=constraints, x0=x0, xf=xf, N=N, dt=dt) # construct problem
initial_controls!(prob,U0) # initialize problem with controls

solver = solve!(prob, ALTROSolverOptions{Float64}())
```

## Examples
Notebooks with more detailed examples can be found [here](https://github.com/RoboticExplorationLab/TrajectoryOptimization.jl/tree/master/examples), including all the examples from our [IROS 2019 paper](https://github.com/RoboticExplorationLab/TrajectoryOptimization.jl/tree/master/examples/IROS_2019).

## Documentation
Detailed documentation for getting started with the package can be found [here](https://roboticexplorationlab.github.io/TrajectoryOptimization.jl/dev/).
