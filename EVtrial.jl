using JuMP, GLPK, LinearAlgebra
using MAT

model = Model(with_optimizer(GLPK.Optimizer))

# Tf = 24 # no. of time slots
# Nf = 2 # no. of car cluster
# In = 2 # no. of cars
# Mn = 2 # no. of reservations
# Wf = 10 # no. of scenarios
# Vf = 10 # no. of scenarios for NAC

Tf = 24 # no. of time slots
Nf = 4 # no. of car cluster
In = 12 # no. of cars
Mn = 5 # no. of reservations
Wf = 10 # no. of scenarios
Vf = 10 # no. of scenarios for NAC

Pmax = 6.6 #maximal charging rate
SoCmax = 24 #upper limit of soc of car i in cluster n
L1 = 24
L2 = 24
# L3 = 1000
alpha = 0.9 #charging efficiency
lambda_f = 0.5 #imbalance fee
delta_t = 1 #time step
Q = 24*ones(Mn, Nf, Wf) #reserved battery level of reservation m in cluster n scenario w (3D)
Tleave = [24, 24, 24, 24]
epsilon = 5
pi_w = 0.05 # probability of scenarios

lambda_Im = zeros(Wf, Tf)
lambda_Ip = zeros(Wf, Tf)
sigmaU = zeros(Wf, Tf)
sigmaD = zeros(Wf, Tf)

#  lambda_A, lambda_U, lambda_D, TT, t0, SOC_0 inputs from .mat files
DAvars = matread("generate_resevation.mat")
RTvars = matread("regulating.mat")

lambda_U = get(RTvars,"priceup",3) #up regulation price for time t in scenario w
lambda_D = get(RTvars,"pricedown",3)  #down regulation price for time t in scenario w
lambda_A = get(DAvars,"lambda_A",3) #spot price for time t in scenario w

TT = get(DAvars,"TT",3)
t0 = get(DAvars,"t0",3)
SoC_0 = get(DAvars,"SOC_0",3)

# @variable(model, k)
# @variable(model, m)
# @variable(model, w)
# @variable(model, n)
@variable(model, 0 <= pA[w = 1:Wf, t = 1:Tf]) #day ahead purchase for time t in scenario w
@variable(model, 0 <= pU[w = 1:Wf, t = 1:Tf]) #up regulation power for time t in scenario w
@variable(model, 0 <= pD[w = 1:Wf, t = 1:Tf]) #down regulation power for time t in scenario w
@variable(model, 0 <= pC[w = 1:Wf, t = 1:Tf])
@variable(model, 0 <= pIp[w = 1:Wf, t = 1:Tf])
@variable(model, 0 <= pIm[w = 1:Wf, t = 1:Tf])
@variable(model, cI[w = 1:Wf, t = 1:Tf])

@variable(model, 0 <= pcharge[i = 1:In, n = 1:Nf, w = 1:Wf, t = 1:Tf])
@variable(model, 0 <= SoC[i = 1:In, n = 1:Nf, w = 1:Wf, t = 1:Tf]) #soc of car i in cluster n at t in scenario w
@variable(model, y[i = 1:In, n = 1:Nf, m = 1:Mn, w = 1:Wf], Bin) #binary whether car i satisfy reservation m in scenario w
@variable(model, a[i = 1:In, n = 1:Nf, m = 1:Mn, w = 1:Wf], Bin) #binary  whether car i is assigned for reservation m in scenario w

@constraint(
    model,
    [w = 1:Wf, t = 1:Tf],
    pIp[w, t] - pIm[w, t] == pA[w, t] + pD[w, t] - pU[w, t] - pC[w, t] # equation 2
)
@constraint(
    model,
    [w = 1:Wf, t = 1:Tf],
    cI[w, t] ==
    pIm[w, t] * lambda_Im[w, t] - pIp[w, t] * lambda_Ip[w, t] +
    (pIp[w, t] + pIm[w, t]) * lambda_f # equation 3
)

for w = 1:Wf
    for t = 1:Tf
        sigmaU[w, t] == lambda_U[w, t] - lambda_A[w, t] #equation 5
        sigmaD[w, t] == lambda_D[w, t] - lambda_A[w, t] # equation 6

        if sigmaD[w, t] < 0   # equation 7
            lambda_Ip[w, t] == lambda_D[w, t]
        elseif sigmaD[w, t] == 0
            lambda_Ip[w, t] == lambda_A[w, t]
        end

        if sigmaU[w, t] < 0 # equation 8
            lambda_Im[w, t] == lambda_U[w, t]
        elseif sigmaU[w, t] == 0
            lambda_Im[w, t] == lambda_A[w, t]
        end

        for v = 1:Vf
            if lambda_A[w, t] == lambda_A[v, t]
                @constraint(model, pA[w, t] == pA[v, t]) # equation 9
            elseif lambda_A[w, t] > lambda_A[v, t]
                @constraint(model, pA[w, t] >= pA[v, t]) # equation 10
            end

            if lambda_A[w, t] == lambda_A[v, t] &&
               lambda_U[w, t] == lambda_U[v, t]
                @constraint(model, pU[w, t] == pU[v, t]) # equation 11

            elseif lambda_A[w, t] == lambda_A[v, t] &&
                   lambda_U[w, t] < lambda_U[v, t]
                @constraint(model, pU[w, t] <= pU[v, t]) # equation 12
            end

            if sigmaU[w, t] == 0
                @constraint(model, pU[w, t] == 0) # equation 13
            end

            if lambda_A[w, t] == lambda_A[v, t] &&
               lambda_D[w, t] == lambda_D[v, t]
                @constraint(model, pD[w, t] == pD[v, t]) # equation 14
            elseif lambda_A[w, t] == lambda_A[v, t] &&
                   lambda_D[w, t] > lambda_D[v, t]
                @constraint(model, pD[w, t] <= pD[v, t]) # equation 15
            end

            if sigmaD[w, t] == 0
                @constraint(model, pD[w, t] == 0) # equation 16
            end
        end
    end
end

@constraint(
    model,
    [w = 1:Wf, t = 1:Tf],
    pC[w, t] == sum(sum(pcharge[i, n, w, t] for i = 1:In) for n = 1:Nf) # equation 17
)

# @constraint(
#     model,
#     [i = 1:In, n = 1:Nf, m = 1:Mn, w = Wf, t = Tf],
#     Q[m, n, w] - SoC[i, n, w, t] <= L1 * (1 - y[i, n, m, w])  # equation 20
# )
# @constraint(
#     model,
#     [i = 1:In, n = 1:Nf, m = 1:Mn, w = Wf, t = Tf],
#     Q[m, n, w] - SoC[i, n, w, t] >= epsilon - L2 * y[i, n, m, w]  # equation 21
# )

for i = 1:In
    for n= 1:Nf
        for w=1:Wf
            for t = 1:Tf
                if t < t0[i,n,w]
                    @constraint(model, pcharge[i, n, w, t] == 0)
                else
                    @constraint(model, pcharge[i, n, w, t] <= Pmax)
                end
                if t >= t0[i,n,w]
                    if t == t0[i,n,w]
                        @constraint(model, SoC[i, n, w, t] == SoC_0[i, n, w] + alpha * pcharge[i, n, w, t] * delta_t)
                    else
                        @constraint(model, SoC[i, n, w, t] == SoC[i, n, w, t-1] + alpha * pcharge[i, n, w, t] * delta_t)
                    end
                    @constraint(model, SoC[i, n, w, t] <= SoCmax)
                else
                    @constraint(model, SoC[i, n, w, t] == 0)
                end
                for m = 1:Mn
                    if t0[i,n,w] <= TT[m,n,w] && t > TT[m,n,w]
                         @constraint(model, pcharge[i,n,w,t] <= (1-a[i,n,m,w])*Pmax)
                    end
                    if t == TT[m,n,w] && t0[i,n,w] <= TT[m,n,w]
                        @constraint(model, Q[m, n, w] - SoC[i, n, w, t] <= L1 * (1 - y[i, n, m, w])) # equation 20
                        @constraint(model, Q[m, n, w] - SoC[i, n, w, t] >= epsilon - L2 * y[i, n, m, w])  # equation 21
                    end
                end
            end
            for m=1:Mn
                if t0[i,n,w] <= TT[m,n,w]
                    @constraint(model, a[i, n, m, w] <= y[i, n, m, w])# equation 23
                elseif t0[i,n,w] > TT[m,n,w]
                    @constraint(model, a[i, n, m, w] == 0) #equation 26
                    @constraint(model, y[i, n, m, w] == 0)
                end
            end
            @constraint(model, sum(a[i, n, m, w] for m = 1:Mn if t0[i,n,w] <= TT[m,n,w]) <= 1)  # equation 24
        end
    end
end

for n= 1:Nf
    for w=1:Wf
        for m=1:Mn
                @constraint(model, sum(a[i, n, m, w] for i = 1:In if t0[i,n,w] <= TT[m,n,w]) == 1)# equation 25
                @constraint(model, sum(y[i, n, m, w] for i = 1:In if t0[i,n,w] <= TT[m,n,w]) == 1)# equation 25
        end
    end
end

# @constraint(model, [i = 1:In, n = 1:Nf, m = 1:Mn, w = 1:Wf], a[i, n, m, w] == 0) # equation 26

# @constraint(model, [t = 1:Tf, w = 1:Wf], sum(sum((1 - sum(a[k, (global n), m, w] for m = 1:Mn if TT[m,n,w] < t))*Pmax
#                                                 for k = 1:In) for n = 1:Nf if t0[global k,n,w] <= t) >= pA[w, t]) # equation 30

#
# @constraint(model, [t = 1:Tf, w = 1:Wf], sum(sum((1 - sum(a[global k, n, m, w] for m = 1:Mn))*Pmax
#                                                  for k = 1:In) for n = 1:Nf if TT[global m,n,w] < t && t0[global k,n,w] <= t) >= pA[w, t])
# if TT(m,n,w) <= t
# if t0(i,n,w) <= t

@constraint(model, [t = 1:Tf, w = 1:Wf], sum(sum((1 - sum(a[i, n, m, w] for m = 1:Mn)) * Pmax
                                                for i = 1:In) for n = 1:Nf) >= pA[w, t]) # equation 30

@constraint(model, [w = 1:Wf, t = 1:Tf], pU[w, t] <= pA[w, t])  # equation 31

@constraint(model, [w = 1:Wf, t = 1:Tf], sum(sum(((1 - sum(a[i, n, m, w] for m = 1:Mn)) * Pmax) for i = 1:In) for n = 1:Nf) - pA[w, t] >= pD[w, t])  # equation 32

@objective(
    model,
    Min,
    sum(
        sum(pi_w*pA[w, t] * lambda_A[w, t] + pi_w*pD[w, t] * lambda_D[w, t] -
            pi_w*pU[w, t] * lambda_U[w, t] + pi_w*cI[w, t] for t = 1:Tf) for w in Wf)
)

optimize!(model)



# obj_val = sum(sum(pi_w*pA[w,t]*lambda_A + pi_w*pD[w,t]*lambda_D -pi_w*pU[w,t]*lambda_U + pi_w*cI[w,t] for t in 1:Tf) for w in Wf)
