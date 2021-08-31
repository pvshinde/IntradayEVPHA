## Hydrothermal scheduling example, see [FAST](https://web.stanford.edu/~lcambier/papers/poster_xpo16.pdf), l. cambier
using Distributed
using JuMP, RandomizedProgressiveHedging, LinearAlgebra
@everywhere const RPH = RandomizedProgressiveHedging


"""
int_to_bindec(s::Int, decomplength::Int)

Compute the vector of the `decomplength` bits of the base 2 representation of `s`, from strongest to weakest.
"""

@everywhere function int_to_bindec(s::Int, decomplength::Int)
    expo_to_val = zeros(Int, decomplength)
    for i in 0:decomplength-1
        expo_to_val[decomplength-i] = mod(floor(Int, s / 2^i), 2)
    end

    return expo_to_val
end


@everywhere struct HydroThermalScenarioExtended <: RPH.AbstractScenario
    weathertype::Int    # Int whose base 2 decomposition holds stage to rain level info.
    nstages::Int
    ndams::Int
end

# """
# build_fs_Cs!(model::JuMP.Model, s::HydroThermalScenario, id_scen::ScenarioId)

# Build the subproblem associated to a `HydroThermalScenario` scenario, as specified in [FAST](https://web.stanford.edu/~lcambier/papers/poster_xpo16.pdf).
# """
@everywhere function build_fs_extendedlpEV(model::JuMP.Model, s::HydroThermalScenarioExtended, id_scen::ScenarioId)
    B = s.ndams         # number of dams
    T = s.nstages

    # c_H = [1 for b in 1:B]       # dams electiricity prod costs

    T = 24
    Pmax = 6.6 #charging power limit
    SoCmax = 24
    L1 = 1000
    L2 = 1000
    L3 = 1000
    N = 4
    In = [4, 3, 3, 5]
    Mn = [1, 3, 2, 1]
    alpha= 0.9
    W = 10
    lambda_f = 10
    delta_t = 1
    Q = [6, 6.4, 14, 8]
    Tleave = [24, 24, 24, 24]
    t0 = [5, 6, 7, 6]
    V = 10
    epsilon = 5
    pi_w = 0.1
    # Convert weathertype::Int into stage to rain level
    stage_to_rainlevel = int_to_bindec(s.weathertype, s.nstages) .+1


    pA = @variable(model, [1:T, 1:B], base_name="pA$id_scen")
    pU = @variable(model, [1:T, 1:B], base_name="pU$id_scen")
    pD = @variable(model, [1:T, 1:B], base_name="pD$id_scen")
    pC = @variable(model, [1:T, 1:B], base_name="pC$id_scen")
    pIp = @variable(model, [1:T, 1:B], base_name="pIp$id_scen")
    pIm = @variable(model, [1:T, 1:B], base_name="pIm$id_scen")
    cI = @variable(model, [1:T, 1:B], base_name="cI$id_scen")
    pch = @variable(model, [1:T, 1:B, 1:I, 1:N], base_name="pch$id_scen")
    SoC = @variable(model, [1:T, 1:B, 1:I, 1:N], base_name="SoC$id_scen")
    y = @variable(model, [1:T, 1:B, 1:I, 1:N], base_name="y$id_scen", Bin) #binary
    a = @variable(model, [1:T, 1:B, 1:I, 1:N], base_name="a$id_scen", Bin) #binary


    # positivity constraint
    @constraint(model, pch .>= 0)
    @constraint(model, SoC .>= 0)

    @constraint(model, pA .>= 0)
    @constraint(model, pU .>= 0)
    @constraint(model, pD .>= 0)
    @constraint(model, pIp .>= 0)
    @constraint(model, pIm .>= 0)

    # Reservoir max capacity

    @constraint(model, [w=1:W, t=1:T], pIp[w,t] - pIm[w,t] == pA[w,t] + pD[w,t] -pU[w,t] -pC[w,t])
    @constraint(model, [w=1:W, t=1:T], CI[w,t] == pIm[w,t]*lambda_Im[w,t] - pIp[w,t]*lambda_Ip[w,t] + (pIp[w,t]+pIm[w,t])*lambda_f)

    #@constraint(model, [w=1:W, t=1:T], sigmaU[w,t] == lambda_U[w,t] - lambda_A[w,t])
    #@constraint(model, [w=1:W, t=1:T], sigmaD[w,t] == lambda_D[w,t] - lambda_A[w,t])

    for w=1:W
        for t=1:T
            sigmaU[w,t] == lambda_U[w,t] - lambda_A[w,t]
            sigmaD[w,t] == lambda_D[w,t] - lambda_A[w,t]

            if sigmaD[w,t] < 0
                lambda_Ip[w,t] == lambda_D[w,t]
            elseif sigmaD[w,t] == 0
                lambda_Ip[w,t] == lambda_A[w,t]
            end

            if sigmaU[w,t] < 0
                lambda_Im[w,t] == lambda_U[w,t]
            elseif sigmaU[w,t] == 0
                lambda_Im[w,t] == lambda_A[w,t]
            end

            for v=1:V
                if lambda_A[w,t] == lambda_A[v,t]
                    @constraint(model, pA[w,t] == pA[v,t])
                elseif lambda_A[w,t] > lambda_A[v,t]
                    @constraint(model, pA[w,t] >= pA[v,t])
                end

                if lambda_A[w,t] == lambda_A[v,t] && lambda_U[w,t] == lambda_U[v,t]
                    @constraint(model, pU[w,t] == pU[v,t])
                elseif lambda_A[w,t] == lambda_A[v,t] && lambda_U[w,t] < lambda_U[v,t]
                    @constraint(model, pU[w,t] <= pU[v,t])
                end

                if sigmaU[w,t] == 0
                    @constraint(model, pU[w,t] == 0)
                end

                if lambda_A[w,t] == lambda_A[v,t] && lambda_D[w,t] == lambda_D[v,t]
                    @constraint(model, pD[w,t] == pD[v,t])
                elseif lambda_A[w,t] == lambda_A[v,t] && lambda_D[w,t] > lambda_D[v,t]
                    @constraint(model, pD[w,t] <= pD[v,t])
                end

                if sigmaD[w,t] == 0
                    @constraint(model, pD[w,t] == 0)
                end
            end
        end
    end

    @constraint(model, [w=1:W, t=1:T], pC[w,t] == sum(sum(pch[i,n,w,t] for i=1:I) for n=1:N)
    @constraint(model, [w=1:W, t=t0:T], SoC[i,n,w,t] == SoC[i,n,w,t-1] + alpha*pch[i,n,w,t]*delta_t)

    @constraint(model, [i=1:I, n=1:N, m=1:M, t=T], Q[m,n] - SoC[i,n,w,t] <= L1*(1-y[i,n,m,w]))
    @constraint(model, [i=1:I, n=1:N, m=1:M, t=T], Q[m,n] - SoC[i,n,w,t] >= epsilon - L2*y[i,n,m,w])


    @constraint(model, a .<= y)

    @constraint(model, [i=1:I, n=1:N, w=1:W], sum(a[i,n,m,w] for m=1:M) <= 1)
    @constraint(model, [n=1:N, m=1:M, w=1:W], sum(a[i,n,m,w] for i=1:I) == 1)
    #@constraint(model, [m=1:M, n=1:N, m=1:M, w=1:W], a[i,n,m,w] == 0)

    @constraint(model, SoC .<= SoCmax)
    @constraint(model, pch .<= Pmax)

    @constraint(model, [t=1:T, w=1:W], sum(sum((1-sum(a[i,n,m,w] for m=1:M))*Pmax for i=1:I) for n=1:N) >= pA[w,t])
    @constraint(model, pU .<= pA)
    @constraint(model, [t=1:T, w=1:W], sum(sum((1-sum(a[i,n,m,w] for m=1:M))*Pmax for i=1:I) for n=1:N) - pA[w,t] >= pD[w,t])

    objexpr = sum(sum(pi_w*pA[w,t]*lambda_A + pi_w*pD[w,t]*lambda_D -pi_w*pU[w,t]*lambda_U + pi_w*cI[w,t] for t in 1:T) for w in W)
    # objexpr = sum(dot(c_H, ys[t, 1:B]) + c_E * e[t] for t in 1:T)
    #objexpr = sum(dot(c_H .* (1-0.1*t), ys[t, 1:B]) + c_E * e[t] for t in 1:T)

    #Y = collect(Iterators.flatten([ union(ys[t, 1:B], qs[t, 1:B], e[t]) for t in 1:T] ))

    #return Y, objexpr, []
    return objexpr, []
end


function build_hydrothermalextended_problem(; nstages = 5, ndams=10, p = 1/4)
    nbranching = 2
    nscenarios = 2^(nstages-1)

    scenarios = Array{HydroThermalScenarioExtended}(undef, nscenarios)
    for s in 1:nscenarios
        scenarios[s] = HydroThermalScenarioExtended(s-1, nstages, ndams)
    end

    scenariotree = ScenarioTree(; depth=nstages, nbranching=2)

    ## Building probas: p is proba of rain
    probas = zeros(nscenarios)
    for s_id in 0:nscenarios-1
        ## in binary decomposition: 0 -> no rain; 1-> rain
        probas[s_id+1] = prod(v*p + (1-v)*(1-p) for v in int_to_bindec(s_id, nstages)[2:end])
    end

    @assert isapprox(sum(probas), 1.)

    dim_to_subspace = [1+(2ndams+1)*i:(2ndams+1)*(i+1) for i in 0:nstages-1]

    return Problem(
        build_fs_extendedlpEV,
    )

    # return Problem(
    #     scenarios,
    #     build_fs_extendedlpEV,
    #     probas,
    #     nscenarios,
    #     nstages,
    #     dim_to_subspace,
    #     scenariotree
    # )
end
