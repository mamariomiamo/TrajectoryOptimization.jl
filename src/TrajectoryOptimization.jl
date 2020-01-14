"""
    TrajectoryOptimization
Primary module for setting up and solving trajectory optimization problems.
"""
module TrajectoryOptimization

using ForwardDiff
using DocStringExtensions
using Interpolations
using RecipesBase
using LinearAlgebra
using Statistics
using Random
using SparseArrays
using StaticArrays
using Logging
using Formatting
using BenchmarkTools
using Parameters
using Rotations
using MathOptInterface
using Quaternions

const MOI = MathOptInterface
const MAX_ELEM = 300

import Base.copy

export
    Dynamics,
    Problems

export
    state_dim,
    control_dim

# Primary types
export
    Model,
    QuadraticCost,
    LQRCost,
    LQRObjective,
    GenericCost,
    Trajectory

export
    Problem,
    iLQRSolver,
    iLQRSolverOptions,
    AugmentedLagrangianSolver,
    AugmentedLagrangianSolverOptions,
    AugmentedLagrangianProblem,
    ALTROSolverOptions,
    DIRCOLSolver,
    DIRCOLSolverOptions,
    ProjectedNewtonSolver,
    ProjectedNewtonSolverOptions,
    SequentialNewtonSolver,
    Discrete,
    Continuous,
    Constraint,
    BoundConstraint,
    Equality,
    Inequality,
    Objective,
    Constraints

export
    rk3,
    rk4,
    midpoint,
    add_constraints!,
    goal_constraint,
    initial_controls!,
    initial_state!,
    circle_constraint,
    sphere_constraint


# Primary methods
export
    solve,
    solve!,
    rollout!,
    rollout,
    forwardpass!,
    backwardpass!,
    cost,
    max_violation,
    max_violation_direct,
    infeasible_control,
    line_trajectory,
    evaluate!,
    jacobian!

export
    get_sizes,
    num_constraints,
    get_num_constraints,
    get_num_controls,
    init_results,
    to_array,
    get_N,
    to_dvecs,
    quat2rot,
    sphere_constraint,
    circle_constraint,
    plot_trajectory!,
    plot_vertical_lines!,
    convergence_rate,
    plot_obstacles,
    evals,
    reset,
    reset_evals,
    final_time,
    total_time,
    count_constraints,
    inequalities,
    equalities,
    bounds,
    labels,
    terminal,
    stage,
    interp_rows

# Static methods
export
    convertProblem

# Trajectory Types
# Trajectory{T} = Vector{T} where T <: AbstractArray
# VectorTrajectory{T} = Vector{Vector{T}} where T <: Real
# MatrixTrajectory{T} = Vector{Matrix{T}} where T <: Real
# AbstractVectorTrajectory{T} = Vector{V} where {V <: AbstractVector{T}, T <: Real}
# DiagonalTrajectory{T} = Vector{Diagonal{T,Vector{T}}} where T <: Real
# PartedVecTrajectory{T} = Vector{PartedVector{T,Vector{T}}}
# PartedMatTrajectory{T} = Vector{PartedMatrix{T,Matrix{T}}}

include("utils.jl")
include("rotations.jl")
include("logger.jl")
# include("constraints.jl")
# include("constraint_sets.jl")
include("knotpoint.jl")
include("costfunctions.jl")
include("static_model.jl")
# include("model.jl")
# include("integration.jl")
include("objective.jl")
# include("problem.jl")
include("solvers.jl")
# include("rollout.jl")
include("abstract_constraint.jl")
include("static_constraints.jl")
include("dynamics_constraints.jl")
include("integration.jl")
include("dynamics.jl")
# include("logger.jl")
# include("../dynamics/quaternions.jl")

include("cost.jl")
include("static_methods.jl")
include("constraint_vals.jl")
include("constraint_sets.jl")
include("static_problem.jl")
include("solvers/silqr/silqr_solver.jl")
include("solvers/silqr/silqr_methods.jl")
include("solvers/augmented_lagrangian/sal_solver.jl")
include("solvers/augmented_lagrangian/sal_methods.jl")
include("solvers/direct/static_primals.jl")
include("solvers/direct/static_pn.jl")
include("solvers/direct/static_pn_methods.jl")
include("solvers/altro/saltro_solver.jl")

include("solvers/direct/static_moi.jl")
include("solvers/direct/copy_blocks.jl")
include("solvers/direct/direct_constraints.jl")

include("problems.jl")

write_ipopt_options()
Logging.global_logger(default_logger(true))
end
