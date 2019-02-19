
function gen_newton_functions(solver::Solver)
    n,m,N = get_sizes(solver)
    p,pI,pE = get_num_constraints(solver)
    p_N,pI_N,pE_N = get_num_terminal_constraints(solver)

    c_function!, c_jacobian!, c_labels, cI!, cE! = generate_constraint_functions(solver.obj)
    f = solver.fd
    s_x = reshape(1:(N*n),n,N)
    s_u = reshape(N*n .+ (1:(m*(N-1))),m,N-1)
    s_λ = (N*n + (N-1)*m) .+ (1:((N-1)*pE + pE_N))
    s_μ = (N*n + (N-1)*m + length(s_λ)) .+ (1:((N-1)*pI + pI_N))
    s_ν = (N*n + (N-1)*m + length(s_λ) + length(s_μ)) .+ (1:N*n)
    s_s = (N*n + (N-1)*m + length(s_λ) + length(s_μ) + N*n) .+ (1:length(s_μ))
    sze = (X=s_x, U=s_u, λ=s_λ, μ=s_μ, ν=s_ν, s=s_s)

    function newton_cost(V::Vector)
        X,U,λ,μ,ν,s = unpackV(V)
        J = cost(solver,X,U) + λ'cE(V) + μ'*(cI(V) + 0.5*s.^2) + ν'd(V)
        return J
    end

    function cI(V)
        X,U,λ,μ,ν,s = unpackV(V)
        C = zeros(eltype(V),pI,N-1)
        for k = 1:N-1
            cI!(view(C,1:pI,k),X[:,k],U[:,k])
        end
        CN = zeros(eltype(V),pI_N)
        cI!(CN,X[:,N])
        CI = [vec(C); CN]
        return CI
    end

    function cE(V)
        X,U,λ,μ,ν,s = unpackV(V)
        C = zeros(eltype(V),pE,N-1)
        for k = 1:N-1
            cE!(view(C,1:pE,k),X[:,k],U[:,k])
        end
        CN = zeros(eltype(V),pE_N)
        cE!(CN,X[:,N])
        CE = [vec(C); CN]
        return CE
    end

    function d(V)
        X,U,λ,μ,ν,s = unpackV(V)
        D = zeros(eltype(V),n,N)
        D[:,1] = X[:,1] - solver.obj.x0
        for k = 2:N
            f(view(D,1:n,k),X[:,k-1],U[:,k-1])
            D[:,k] -= X[:,k]
        end
        return vec(D)
    end

    function active_set(V,eps=1e-2)
        X,U,λ,μ,ν,s = unpackV(V)
        a = trues(length(V))
        ci = cI(V)
        c_inds = ci .>= -eps
        a[sze.μ] = c_inds
        a[sze.s] = c_inds
        return a
    end


    function packV(X,U,λ,μ,ν,s)
        V = [vec(X);vec(U);λ;μ;ν;s]
    end

    function unpackV(V)
        X = V[sze.X]
        U = V[sze.U]
        λ = V[sze.λ]
        μ = V[sze.μ]
        ν = V[sze.ν]
        s = V[sze.s]
        return X,U,λ,μ,ν,s
    end
    return newton_cost, packV, unpackV, cI, cE, d, active_set, sze
end

model,obj = Dynamics.dubinscar
solver = Solver(model,obj,N=31)
n,m,N = get_sizes(solver)
U0 = rand(m,N-1)
res,stats = solve(solver,U0)
# λ_update_default!(res,solver);

newton_cost, packV, unpackV, cI, cE, d, active_set = gen_newton_functions(solver)
max_c(V) = max(maximum(cI(V)),norm(cE(V),Inf))
p,pI,pE = get_num_constraints(solver)
pN,pI_N,pE_N = get_num_terminal_constraints(solver)
nZ  = 2N*n + (N-1)*m
X = to_array(res.X)
U = to_array(res.U)
μ = vcat([k < N ? res.λ[k][1:pI] : res.λ[k][1:pI_N] for k = 1:N]...)
λ = vcat([k < N ? res.λ[k][pI .+ (1:pE)] : res.λ[k][pI_N .+ (1:pE_N)] for k = 1:N]...)
ν = vec(to_array(res.s))
s = vcat([k < N ? res.C[k][1:pI] : res.C[k][1:pI_N] for k = 1:N]...)
s = sqrt.(2*max.(0,-s))

μ = zeros(0)
λ = zeros(0)
s = zeros(0)
V = packV(X,U,λ,μ,ν,s)

unpackV(V)
(X,U,λ,μ,ν,s) == unpackV(V)
d(V)
cE(V)
cI(V)

V = packV(X,U,λ,μ,ν,s)

J1 = newton_cost(V)
g = ForwardDiff.gradient(newton_cost,V)
H = ForwardDiff.hessian(newton_cost,V)
V_ = line_search(V,H+I,g)
newton_cost(V_)
d(V_)
norm(d(V_),Inf)
X_,U_,λ_,μ_,ν_,s_ = unpackV(V_)
ν_
V = copy(V_)



function line_search(V,H,g)
    J0 = newton_cost(V)
    α = 1.
    V_ = V - α*(H\g)
    J = newton_cost(V_)
    iter = 1
    while J > J0
        α /= 2
        V_ = V - α*(H\g)
        J = newton_cost(V_)
        iter += 1
        @show J, α
        iter > 10 ? break : nothing
    end
    @show J0-J
    return V_
end



max_c(V)
findmax(cI(V))
cI(V)
X,U,λ,μ,ν,s == unpackV(V)
μ[8]
norm(μ.*s,Inf)
d(V)

# Block move
opts = TrajectoryOptimization.SolverOptions()
opts.verbose = false
opts.cost_tolerance = 1e-4
opts.cost_tolerance_intermediate = 1e-4
opts.constraint_tolerance = 1e-4
opts.square_root = false
opts.active_constraint_tolerance = 0.0
opts.outer_loop_update_type = :default
opts.live_plotting = false

# Block move
model, obj = TrajectoryOptimization.Dynamics.double_integrator
u_min = -0.2
u_max = 0.2
obj_con = TrajectoryOptimization.ConstrainedObjective(obj, tf=5.0,use_xf_equality_constraint=true, u_min=u_min, u_max=u_max)#, x_max=x_max)

solver = TrajectoryOptimization.Solver(model,obj_con,integration=:rk4,N=11,opts=opts)
U = rand(solver.model.m, solver.N)

res, stats = TrajectoryOptimization.solve(solver,U)
@assert max_violation(res) < opts.constraint_tolerance
max_violation(res)

newton_cost, packV, unpackV, cI, cE, d, active_set = gen_newton_functions(solver)
max_c(V) = max(maximum(cI(V)),norm(cE(V),Inf))

X = to_array(res.X)
U = to_array(res.U)
μ = vec(to_array(res.λ[1:N-1]))
λ = vec(res.λ[N])
ν = vec(to_array(res.s))
s = sqrt.(2.0*max.(0.0,vec(-to_array(res.C[1:N-1]))))
V = packV(X,U,λ,μ,ν,s)

cost(solver,res)
max_c(V)
newton_cost(V)
g = ForwardDiff.gradient(newton_cost,V)
H = ForwardDiff.hessian(newton_cost,V)
V[a] = V[a] - H[a,a]\g[a]
# V = V - H\g
newton_cost(V)
max_c(V)


X,U,λ,μ,ν,s == unpackV(V)
