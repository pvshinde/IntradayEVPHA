using Distributed
using DataStructures, LinearAlgebra
using RandomizedProgressiveHedging, JuMP
# using Revise
@everywhere const RPH = RandomizedProgressiveHedging

@everywhere struct PriceScenariosp <: RPH.AbstractScenario
    ID_ask_price::Matrix{Float64}
    ID_buy_price::Matrix{Float64}
    Up_price::Matrix{Float64}
    Dn_price::Matrix{Float64}
    Im_price::Matrix{Float64}
    Ip_price::Matrix{Float64}
end

@everywhere function build_fs_CsEV!(model::JuMP.Model, s::PriceScenariosp, id_scen::ScenarioId)
    # n = length(s.trajcenter)
    Tf = 3 # no. of stages, different for different DPs

    Df = 3 # no. of time slots (Delivery products)
    In = 10 # no. of cars

    Pmax = 6.6 #maximal charging rate
    SoCmax = 24 #upper limit of soc of car i
    PA_max = 50
    PB_max = 50
    P_max = 50
    # L3 = 1000
    alpha = 0.9 #charging efficiency
    lambda_f = 0.5 #imbalance fee
    delta_d = 1 #time step
    # Q = ones(Mn, Nf) #reserved battery level of reservation m in cluster n scenario w (3D)

    Q = [30, 33, 34, 20, 25, 28, 27, 35, 24, 30] # charging requirement per EV
    SoC_init = [10, 12, 14, 15, 18, 20, 14, 17, 18, 11] # initial SOC for each EV when it arrives
    d0 = [2, 3, 1, 2, 3, 2, 4, 4, 2, 1] # time of arrival of each EV
    DD = [8, 9, 10, 7, 8, 9, 10, 8, 7, 10] # time of departure of each EV

    epsilon = 0.01
    pi_w = 0.05 # probability of scenarios

    P_DA=[30, 60, 45, 29, 50, 45, 40, 44, 48, 50] # DA position of EV aggregator for each DP
    lamba_DA = [25, 30, 35, 40, 28, 44, 34, 38, 37, 40] # DA prces of EV aggregator for each DP

    # lambda_Im = zeros(Wf, Df)
    # lambda_Ip = zeros(Wf, Df)
    # sigmaU = zeros(Wf, Df)
    # sigmaD = zeros(Wf, Df)

    # Convert weathertype::Int into stage to rain level

    pA = @variable(model, [1:Tf,1:Df], base_name="pA_s$id_scen")
    pB = @variable(model, [1:Tf,1:Df], base_name="pB_s$id_scen")
    pU = @variable(model, [1:Df], base_name="pU$id_scen")
    pD = @variable(model, [1:Df], base_name="pD$id_scen")
    pC = @variable(model, [1:Df], base_name="pC$id_scen")
    pIp = @variable(model, [1:Df], base_name="pIp$id_scen")
    pIm = @variable(model, [1:Df], base_name="pIm$id_scen")
    # cI = @variable(model, [1:Wf, 1:Df], base_name="cI$id_scen")
    pcharge = @variable(model, [1:In, 1:Df], base_name="pch$id_scen")
    SoC = @variable(model, [1:In, 1:Df], base_name="SoC$id_scen")

    @constraint(model, pcharge .>= 0)
    @constraint(model, SoC .>= 0)
    @constraint(model, pA .>= 0)
    @constraint(model, pB .>= 0)
    @constraint(model, pU .>= 0)
    @constraint(model, pD .>= 0)
    @constraint(model, pIp .>= 0)
    @constraint(model, pIm .>= 0)

    objexpr = sum(sum(pB[t, d]*s.ID_buy_price[t,d] - pA[t, d]*s.ID_ask_price[t,d] for t in Tf) for d in Df)
                + sum(pD[d] * s.Up_price[d] - pU[d] * s.Dn_price[d] - pIm[d]*s.Im_price[d] + pIp[d]*s.Ip_price[d] +
                (pIp[d] + pIm[d]) * lambda_f for d in Df)

    @constraint(model, [d=1:Df], pIp[d] - pIm[d] == sum(pA[t,d] - pB[t,d] for t in 1:Tf) + pD[d] -pU[d] -pC[d])

    # @constraint(model,
    #     [d = 1:Df], pC[d] == sum(pcharge[i, d] for i = 1:In) ) # equation 17

for i = 1:In
    for d = 1:Df
        if d0[i] > d && d > DD[i]
            @constraint(model, pcharge[i, d] == 0)
        else
            @constraint(model, pcharge[i, d] <= Pmax)
        end
        if d >= d0[i] && d < DD[i]
            if d == d0[i]
                @constraint(model, SoC[i, d] == SoC_init[i] + alpha * pcharge[i, d] * delta_d)
            else
                @constraint(model, SoC[i, d] == SoC[i, d-1] + alpha * pcharge[i, d] * delta_d)
            end
            @constraint(model, SoC[i, d] <= SoCmax)
        else
            @constraint(model, SoC[i, d] == 0)
        end
        if  d == DD[i]
            @constraint(model, Q[i] - SoC[i, d] >= epsilon)  # equation 21
        end
    end
end

for t=1:Tf
    if t==1
        @constraint(model, [d = 1:Df], P_DA[d] >= pA[t,d]) # equation 30
    else
        @constraint(model, [d = 1:Df], P_DA[d]+sum(pB[t,d]-pA[t,d] for t=1:t-1)>= pA[t,d]) # equation 30
    end
end

for t=1:Tf
    if t==1
        @constraint(model, [d = 1:Df], PB_max - P_DA[d] >= pB[t,d]) # equation 30
    else
        @constraint(model, [d = 1:Df], PB_max - (P_DA[d]+sum(pB[t,d]-pA[t,d] for t=1:t-1)) >= pB[t,d]) # equation 30
    end
end

@constraint(model, [d = 1:Df], pU[d] <= sum(pB[t,d]-pA[t,d] for t=1:Tf) + P_DA[d])  # equation 31

@constraint(model, [d = 1:Df], sum(pcharge[i, d] for i in In) - (sum(pB[t,d]-pA[t,d] for t=1:Tf) + P_DA[d]) >= pD[d])  # equation 32
# make sure that pcharge for i is 0 when d is less than d0 and greater than DD for that EV

    Y = collect(Iterators.flatten([union(pA[1:Tf,1:Df], pB[1:Tf,1:Df], pU[1:Df], pD[1:Df], pC[1:Df],
                 pIp[1:Df], pIm[1:Df], pcharge[1:In, 1:Df], SoC[1:In, 1:Df])]))

    # print(Y)
    # print(model)
    # print(JuMP.value.(pA))

    return Y, objexpr, []
end

function build_simpleexampleEV()
        #########################################################
    ## Problem definition
    Tf = 3 # no. of stages
    Wf = 4 # this not really a scenario in this case. It is just like any other index for example dams.

    Df = 3 # no. of time slots (Delivery products)
    In = 10 # no. of cars

#assuming three ID stages will correspond to 4 scenarios if nbranching=2, one BM stage
# scenario1 = PriceScenariosp(lambda_A[1:3,1:4], lambda_D[1:3,1:4],lambda_U[1:1,1:4],lambda_D[1:1,1:4],
# lambda_Im[1:1,1:4],lambda_Ip[1:1,1:4])
# #IDpriceA, B, Upreg, Dnreg,Imprice, Ipprice, SoCinit, Q, d0, DD
# scenario2 = PriceScenariosp(lambda_A[4:6,1:4], lambda_D[4:6,1:4],lambda_U[2:2,1:4],lambda_D[2:2,1:4],
# lambda_Im[2:2,1:4],lambda_Ip[2:2,1:4])
# # SoC is for Nf that is 3, ID_A, ID_B, SOC_init, Q, d0, DD
# scenario3 = PriceScenariosp(lambda_A[7:9,1:4], lambda_D[7:9,1:4],lambda_U[3:3,1:4],lambda_D[3:3,1:4],
# lambda_Im[3:3,1:4],lambda_Ip[3:3,1:4])
# scenario4 = PriceScenariosp(lambda_A[10:12,1:4], lambda_D[10:12,1:4],lambda_U[4:4,1:4],lambda_D[4:4,1:4],
# lambda_Im[4:4,1:4],lambda_Ip[4:4,1:4])

scenario1 = PriceScenariosp(lambda_A[1:3,1:4], lambda_D[1:3,1:4],lambda_U[1:1,1:4],lambda_D[1:1,1:4],
lambda_Im[1:1,1:4],lambda_Ip[1:1,1:4])
#IDpriceA, B, Upreg, Dnreg,Imprice, Ipprice, SoCinit, Q, d0, DD
scenario2 = PriceScenariosp(lambda_A[4:6,1:4], lambda_D[4:6,1:4],lambda_U[2:2,1:4],lambda_D[2:2,1:4],
lambda_Im[2:2,1:4],lambda_Ip[2:2,1:4])
# SoC is for Nf that is 3, ID_A, ID_B, SOC_init, Q, d0, DD
scenario3 = PriceScenariosp(lambda_A[7:9,1:4], lambda_D[7:9,1:4],lambda_U[3:3,1:4],lambda_D[3:3,1:4],
lambda_Im[3:3,1:4],lambda_Ip[3:3,1:4])
scenario4 = PriceScenariosp(lambda_A[10:12,1:4], lambda_D[10:12,1:4],lambda_U[4:4,1:4],lambda_D[4:4,1:4],
lambda_Im[4:4,1:4],lambda_Ip[4:4,1:4])


    # stage to scenario partition
    stageid_to_scenpart = [
        OrderedSet([BitSet(1:4)]),                      # Stage 1
        OrderedSet([BitSet(1:2), BitSet(3:4)]),           # Stage 2
        OrderedSet([BitSet(1), BitSet(2), BitSet(3), BitSet(4)]),  # Stage 3
    ]

    # scenariotree =  ScenarioTree(; depth=nstages, nbranching=2)
    # dim_to_subspace =[1:8, 9:16, 17:24] #  depends on the number of variables. here when you only have one variable pA you say 1:1, 2:2, 3:3
    # dim_to_subspace = [1+(7*(Df)+Df*Nf)*i:(7*(Df)+Df*Nf)*(i+1) for i in 0:3-1]
    # dim_to_subspace = [1+(7*(Df)+Df*Nf)*i:(7*(Df)+Df*Nf)*(i+1) for i in 0:3-1]
    # dim_to_subspace = [1:8, 9:16, 17:44]
    # dim_to_subspace = [1:8, 9:16, 17:120]
    # dim_to_subspace = [1:8, 9:16, 17:Tf*Df*2+Df*5+In*Nf*Df*2+In*Nf*Mn*2]
    dim_to_subspace = [1:8, 9:16, 17:Tf*Df*2+Df*5+In*Df*2]

    custom_nscenarios = 4
    custom_nstages =3
    # custom_scenariotree= ScenarioTree(stageid_to_scenpart)

    scenariotree = ScenarioTree(; depth=3, nbranching=2)

    pb = Problem(
        [scenario1, scenario2, scenario3, scenario4],  # scenarios array
        build_fs_CsEV!,
        [0.25, 0.25, 0.25, 0.25],                  # scenario probabilities
        custom_nscenarios,
        custom_nstages,
        dim_to_subspace,
        scenariotree
    )
        # [1:1, 2:2, 3:3],                    # stage id to trajectory coordinates, required for projection
        # stageid_to_scenpart                 # stage to scenario partition


    # scenarios,
    # build_fs_extendedmilp,
    # probas,
    # nscenarios,
    # nstages,
    # dim_to_subspace,
    # scenariotree

    return pb
end

# put real data
# put in PHA context
