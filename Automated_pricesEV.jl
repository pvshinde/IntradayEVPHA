using Distributed
using DataStructures, LinearAlgebra
using RandomizedProgressiveHedging, JuMP
# using Revise
@everywhere const RPH = RandomizedProgressiveHedging

@everywhere struct PriceScenarios <: RPH.AbstractScenario
    ID_ask_price::Matrix{Float64}
    ID_buy_price::Matrix{Float64}
    Up_price::Matrix{Float64}
    Dn_price::Matrix{Float64}
    Im_price::Matrix{Float64}
    Ip_price::Matrix{Float64}
end

@everywhere function build_fs_CsEV!(model::JuMP.Model, s::PriceScenarios, id_scen::ScenarioId)
    # n = length(s.trajcenter)
    Tf = 4 # no. of stages, different for different DPs

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
    lamba_DA = [15, 10, 15, 10, 18, 14, 14, 18, 17, 20] # DA prces of EV aggregator for each DP

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
    Tf = 4 # no. of stages
    Df = 3 # no. of time slots (Delivery products)
    In = 10 # no. of cars

#assuming three ID stages will correspond to 4 scenarios if nbranching=2, one BM stage
# scenarios = [PriceScenarios(lambda_A[1+3*i:3*(i+1),1:4],lambda_D[1+3*i:3*(i+1),1:4],lambda_U[i:i,1:4],lambda_D[i:i,1:4],
#             lambda_Im[i:i,1:4],lambda_Ip[i:i,1:4]) for i in 1:4]
scenarios = [PriceScenarios(lambda_A[1:4,1:4],lambda_D[1:4,1:4],lambda_U[1:1,1:4],lambda_D[1:1,1:4],
            lambda_Im[1:1,1:4],lambda_Ip[1:1,1:4]) for i in 0:7]

#IDpriceA, B, Upreg, Dnreg,Imprice, Ipprice, SoCinit, Q, d0, DD

    # stage to scenario partition
    stageid_to_scenpart = [
        OrderedSet([BitSet(1:8)]),                      # Stage 1
        OrderedSet([BitSet(1:4), BitSet(5:8)]),           # Stage 2
        OrderedSet([BitSet(1+2*i:2*(1+i)) for i in 0:3]), #stage 3
        OrderedSet([BitSet(1), BitSet(2), BitSet(3), BitSet(4),BitSet(5), BitSet(6), BitSet(7), BitSet(8)]) #stage4
    ]
    # stageid_to_scenpart = [
    #     OrderedSet([BitSet(1:2048)]),                      # Stage 1
    #     OrderedSet([BitSet(1:1024), BitSet(1025:2048)]),           # Stage 2
    #     OrderedSet([BitSet(1:512), BitSet(513:1024), BitSet(1025:1536), BitSet(1537:2048)]),  # Stage 3
    #     OrderedSet([BitSet(1:256), BitSet(257:512), BitSet(513:768), BitSet(769:1024),BitSet(1025:1280), BitSet(1281:1536), BitSet(1537:1792), BitSet(1793:2048)]), #stage4
    #     OrderedSet([BitSet(1+128*i:128*(1+i)) for i in 0:15]) # stage 5
    #     OrderedSet([BitSet(1+64*i:64*(1+i)) for i in 0:31]) # stage 6
    #     OrderedSet([BitSet(1+32*i:32*(1+i)) for i in 0:63]) # stage 7
    #     OrderedSet([BitSet(1+16*i:16*(1+i)) for i in 0:127]) # stage 8
    #     OrderedSet([BitSet(1+8*i:8*(1+i)) for i in 0:255]) # stage 9
    #     OrderedSet([BitSet(1+4*i:4*(1+i)) for i in 0:511]) # stage 10
    #     OrderedSet([BitSet(1+2*i:2*(1+i)) for i in 0:1023]) # stage 11
    #     OrderedSet([BitSet(i) for i in 0:2047]) # stage 12
    # ]

    # scenariotree =  ScenarioTree(; depth=nstages, nbranching=2)
    # dim_to_subspace =[1:8, 9:16, 17:24] #  depends on the number of variables. here when you only have one variable pA you say 1:1, 2:2, 3:3
    # dim_to_subspace = [1+(7*(Df)+Df*Nf)*i:(7*(Df)+Df*Nf)*(i+1) for i in 0:3-1]
    # dim_to_subspace = [1+(7*(Df)+Df*Nf)*i:(7*(Df)+Df*Nf)*(i+1) for i in 0:3-1]
    # dim_to_subspace = [1:8, 9:16, 17:44]
    # dim_to_subspace = [1:8, 9:16, 17:120]
    # dim_to_subspace = [1:8, 9:16, 17:Tf*Df*2+Df*5+In*Nf*Df*2+In*Nf*Mn*2]
    dim_to_subspace = [1:24, 25:48, 49:72, 73:Tf*Df*2+Df*5+In*Df*2]

    custom_nscenarios = 8
    custom_nstages =4
    # custom_scenariotree= ScenarioTree(stageid_to_scenpart)

    scenariotree = ScenarioTree(; depth=4, nbranching=2)

    pb = Problem(
        scenarios,  # scenarios array
        build_fs_CsEV!,
        [0.25, 0.25, 0.25, 0.25,0.25, 0.25, 0.25, 0.25],                  # scenario probabilities
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
