using Distributed
using DataStructures, LinearAlgebra
using RandomizedProgressiveHedging, JuMP
# using Revise
@everywhere const RPH = RandomizedProgressiveHedging

@everywhere struct PriceScenarios <: RPH.AbstractScenario
    ID_ask_price::Matrix{Float64}
    ID_buy_price::Matrix{Float64}
    Dn_price::Matrix{Float64}
    Up_price::Matrix{Float64}
    Ip_price::Matrix{Float64}
    Im_price::Matrix{Float64}
end

@everywhere function build_fs_CsEV!(model::JuMP.Model, s::PriceScenarios, id_scen::ScenarioId)
    # n = length(s.trajcenter)
    # Tf = [3, 4, 5] # no. of stages, different for different DPs
    Tf = 12
    Df = 10 # no. of time slots (Delivery products)
    In = 50 # no. of cars

    Pmax = 10 #maximal charging rate
    SoCmax = 40 #upper limit of soc of car i
    PA_max = 500
    PB_max = 500
    P_max = 500
    # L3 = 1000
    alpha = 0.9 #charging efficiency
    lambda_f = 0.5 #imbalance fee
    delta_d = 1 #time step
    # Q = ones(Mn, Nf) #reserved battery level of reservation m in cluster n scenario w (3D)
    #
    # Q = [30, 33, 34, 20, 25, 28, 28, 34, 28, 30] # charging requirement per EV
    # SoC_init = [20, 12, 14, 15, 15, 15, 17, 17, 20, 20] # initial SOC for each EV when it arrives
    # d0 = [2, 3, 1, 2, 3, 2, 1, 1, 2, 1] # time of arrival of each EV
    # DD = [8, 9, 10, 7, 8, 9, 10, 8, 7, 10] # time of departure of each EV
    #
    # Q = [30, 33, 34, 20, 25, 28, 28, 34, 28, 30, 30, 33, 34, 20, 25, 28, 28, 34, 28, 30] # charging requirement per EV
    # SoC_init = [20, 12, 14, 15, 15, 15, 17, 17, 20, 20, 20, 12, 14, 15, 15, 15, 17, 17, 20, 20] # initial SOC for each EV when it arrives
    # d0 = [2, 3, 1, 2, 3, 2, 1, 1, 2, 1,2, 3, 1, 2, 3, 2, 1, 1, 2, 1] # time of arrival of each EV
    # DD = [8, 9, 10, 7, 8, 9, 10, 8, 7, 10,8, 9, 10, 7, 8, 9, 10, 8, 7, 10] # time of departure of each EV
# data for 12 stages run on Friday 16:30
    # Q = [30, 33, 34, 20, 25, 28, 28, 34, 28, 30, 30, 33, 34, 20, 25, 28, 28, 34, 28, 30,
    # 30, 33, 34, 20, 25, 28, 28, 34, 28, 30,30, 33, 34, 20, 25, 28, 28, 34, 28, 30, 30, 33, 34, 20, 25, 28, 28, 34, 28, 30] # charging requirement per EV
    # SoC_init = [20, 12, 14, 15, 15, 15, 17, 17, 20, 20, 20, 12, 14, 15, 15, 15, 17, 17, 20, 20,
    # 20, 12, 14, 15, 15, 15, 17, 17, 20, 20, 20, 12, 14, 15, 15, 15, 17, 17, 20, 20, 20, 12, 14, 15, 15, 15, 17, 17, 20, 20] # initial SOC for each EV when it arrives
    # d0 = [2, 3, 1, 2, 3, 2, 1, 1, 2, 1,2, 3, 1, 2, 3, 2, 1, 1, 2, 1,
    # 2, 3, 1, 2, 3, 2, 1, 1, 2, 1,2, 3, 1, 2, 3, 2, 1, 1, 2, 1,2, 3, 1, 2, 3, 2, 1, 1, 2, 1] # time of arrival of each EV
    # DD = [8, 9, 10, 7, 8, 9, 10, 8, 7, 10,8, 9, 10, 7, 8, 9, 10, 8, 7, 10,
    # 8, 9, 10, 7, 8, 9, 10, 8, 7, 10,8, 9, 10, 7, 8, 9, 10, 8, 7, 10,8, 9, 10, 7, 8, 9, 10, 8, 7, 10] # time of departure of each EV

    Q = [30, 13, 34, 20, 25, 18, 18, 10, 18, 30, 10, 33, 14, 20, 25, 28, 28, 34, 28, 30,
    30, 11, 14, 20, 25, 28, 28, 34, 28, 10,30, 22, 34, 20, 25, 28, 28, 14, 18, 12, 16, 11, 34, 20, 25, 28, 28, 14, 18, 10] # charging requirement per EV
    SoC_init = [20, 12, 14, 15, 15, 15, 17, 17, 20, 20, 20, 12, 14, 15, 15, 15, 17, 17, 20, 20,
    20, 12, 14, 15, 15, 15, 17, 17, 20, 20, 20, 12, 14, 15, 15, 15, 17, 17, 20, 20, 20, 12, 14, 15, 15, 15, 17, 17, 20, 20] # initial SOC for each EV when it arrives
    d0 = [2, 3, 1, 2, 3, 2, 1, 1, 2, 1,2, 3, 1, 2, 3, 2, 1, 1, 2, 1,
    2, 3, 1, 2, 3, 2, 1, 1, 2, 1,2, 3, 1, 2, 3, 2, 1, 1, 2, 1,2, 3, 1, 2, 3, 2, 1, 1, 2, 1] # time of arrival of each EV
    DD = [8, 9, 10, 7, 8, 9, 10, 8, 7, 10,8, 9, 10, 7, 8, 9, 10, 8, 7, 10,
    8, 9, 10, 7, 8, 9, 10, 8, 7, 10,8, 9, 10, 7, 8, 9, 10, 8, 7, 10,8, 9, 10, 7, 8, 9, 10, 8, 7, 10] # time of departure of each EV

    epsilon = 0

    P_DA=[200, 220, 105, 401, 190, 185, 80, 214, 208, 390] # DA position of EV aggregator for each DP

    # P_DA=[100, 120, 105, 101, 90, 85, 80, 114, 108, 100]

    # lambda_DA = [15, 10, 15, 10, 18, 14, 14, 18, 17, 20] # DA prices of EV aggregator for each DP
    lambda_DA=[18.6211, 21.5615, 15.8325, 20.1678, 31.5517, 28.7284, 27.2569, 23.7927, 28.4911, 31.8757]

# price_to is SE3 buying
#price_from is SE3 selling a up

    pA = @variable(model, [1:Df,1:Tf], base_name="pA_s$id_scen")
    pB = @variable(model, [1:Df,1:Tf], base_name="pB_s$id_scen")
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
    #
    # objexpr = sum(sum(pB[d, t]*s.ID_buy_price[d,t] - pA[d, t]*s.ID_ask_price[d,t] for t in Tf) for d in Df)
    #             + sum(pD[d] * s.Dn_price[d] - pU[d] * s.Up_price[d] + pIm[d]*s.Im_price[d] - pIp[d]*s.Ip_price[d] +
    #             (pIp[d] + pIm[d]) * lambda_f for d in Df)
    objexpr = sum(sum(pB[d, t]*s.ID_buy_price[d,t] - pA[d, t]*s.ID_ask_price[d,t] for t in Tf) for d in Df)
                + sum(pD[d] * s.Dn_price[d] - pU[d] * s.Up_price[d] + pIm[d]*s.Im_price[d] - pIp[d]*s.Ip_price[d] +
                (pIp[d] + pIm[d]) * lambda_f for d in Df)

    @constraint(model, [d=1:Df], pIp[d] - pIm[d] == P_DA[d] + sum(-pA[d,t] + pB[d,t] for t in 1:Tf) + pD[d] - pU[d] - pC[d])

    @constraint(model,
        [d = 1:Df], pC[d] == sum(pcharge[i, d] for i = 1:In))

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
        if  d == DD[i]-1
            @constraint(model, Q[i] - SoC[i, d] <= epsilon)  # equation 21
        end
    end
end

for t=1:Tf
    if t==1
        @constraint(model, [d = 1:Df],  P_DA[d] >= pA[d, t]) # equation 30
    else
        @constraint(model, [d = 1:Df], P_DA[d]+sum(pB[d, t]-pA[d, t] for t=1:t-1)>= pA[d,t]) # equation 30
    end
end

# @constraint(model, [d = 1:Df], PB_max >= pB[d, t]) # equation 30
for t=1:Tf
    if t==1
        @constraint(model, [d = 1:Df], PB_max - P_DA[d] >= pB[d, t]) # equation 30
    else
        @constraint(model, [d = 1:Df], PB_max - (P_DA[d]+sum(pB[d,t]-pA[d,t] for t=1:t-1)) >= pB[d, t]) # equation 30
    end
end

@constraint(model, [d = 1:Df], pU[d] <= sum(pB[d,t]-pA[d,t] for t=1:Tf) + P_DA[d])  # equation 31
#  @constraint(model, [d = 1:Df], pU[d] <= 1000)
# @constraint(model, [d = 1:Df], pD[d] <= 1000)
@constraint(model, [d = 1:Df], sum(pcharge[i, d] for i in In) - (sum(pB[d,t]-pA[d,t] for t=1:Tf) + P_DA[d]) >= pD[d])  # equation 32
# make sure that pcharge for i is 0 when d is less than d0 and greater than DD for that EV

for d=1:9
    Td=[4,5,6,7,8,9,10,11,12]
        @constraint(model, [t=Td[d]:12], pA[d,t]==0)
        @constraint(model, [t=Td[d]:12], pB[d,t]==0)
end
    Y = collect(Iterators.flatten([union(pA[1:Df,1:Tf], pB[1:Df,1:Tf], pU[1:Df], pD[1:Df], pC[1:Df],
                 pIp[1:Df], pIm[1:Df], pcharge[1:In, 1:Df], SoC[1:In, 1:Df])]))

    # print(Y)
    # print(model)
    # print(JuMP.value.(pA))

    return Y, objexpr, []
end

function build_simpleexampleEV()
        #########################################################
    ## Problem definition
    Tf = 12 # no. of stages
    Df = 10 # no. of time slots (Delivery products)
    In = 50 # no. of cars

#assuming three ID stages will correspond to 4 scenarios if nbranching=2, one BM stage

scenarios = [PriceScenarios([price_scenarios_1[i:i,:]; price_scenarios_2[i:i,:];price_scenarios_3[i:i,:]; price_scenarios_4[i:i,:];price_scenarios_5[i:i,:];
 price_scenarios_6[i:i,:];price_scenarios_7[i:i,:]; price_scenarios_8[i:i,:];price_scenarios_9[i:i,:]; price_scenarios_10[i:i,:]],
 [price_scenarios_from_1[i:i,:]; price_scenarios_from_2[i:i,:];price_scenarios_from_3[i:i,:]; price_scenarios_from_4[i:i,:];price_scenarios_from_5[i:i,:];
 price_scenarios_from_6[i:i,:];price_scenarios_from_7[i:i,:]; price_scenarios_from_8[i:i,:];price_scenarios_from_9[i:i,:]; price_scenarios_from_10[i:i,:]],
 [price_reg_to_1[i:i,1:1]; price_reg_to_2[i:i,1:1];price_reg_to_3[i:i,1:1]; price_reg_to_4[i:i,1:1];price_reg_to_5[i:i,1:1];price_reg_to_6[i:i,1:1]; price_reg_to_7[i:i,1:1];
 price_reg_to_8[i:i,1:1]; price_reg_to_9[i:i,1:1]; price_reg_to_10[i:i,1:1]],
 [price_reg_from_1[i:i,1:1]; price_reg_from_2[i:i,1:1];price_reg_from_3[i:i,1:1]; price_reg_from_4[i:i,1:1];price_reg_from_5[i:i,1:1];price_reg_from_6[i:i,1:1];
 price_reg_from_7[i:i,1:1]; price_reg_from_8[i:i,1:1];price_reg_from_9[i:i,1:1]; price_reg_from_10[i:i,1:1]],
 lambda_Ip[i:i,:], lambda_Im[i:i,:]) for i in 1:2048]

# scenarios = [PriceScenarios([price_scenarios_8[i:i,9:12]; price_scenarios_9[i:i,9:12]; price_scenarios_10[i:i,9:12]], [price_scenarios_from_7[i:i,9:12]; price_scenarios_from_8[i:i,9:12];
# price_scenarios_from_9[i:i,9:12]], [price_reg_to_1[i:i,1:1]; price_reg_to_2[i:i,1:1]; price_reg_to_3[i:i,1:1]], [price_reg_from_1[i:i,1:1]; price_reg_from_2[i:i,1:1]; price_reg_from_3[i:i,1:1]]) for i in 1:8]

#IDpriceA, B, Upreg, Dnreg,Imprice, Ipprice, SoCinit, Q, d0, DD

    # stage to scenario partition
    stageid_to_scenpart = [
        OrderedSet([BitSet(1:2048)]),                      # Stage 1
        OrderedSet([BitSet(1:1024), BitSet(1025:2048)]),           # Stage 2
        OrderedSet([BitSet(1:512), BitSet(513:1024), BitSet(1025:1536), BitSet(1537:2048)]),  # Stage 3
        OrderedSet([BitSet(1:256), BitSet(257:512), BitSet(513:768), BitSet(769:1024),BitSet(1025:1280), BitSet(1281:1536), BitSet(1537:1792), BitSet(1793:2048)]), #stage4
        OrderedSet([BitSet(1+128*i:128*(1+i)) for i in 0:15]), # stage 5
        OrderedSet([BitSet(1+64*i:64*(1+i)) for i in 0:31]), # stage 6
        OrderedSet([BitSet(1+32*i:32*(1+i)) for i in 0:63]), # stage 7
        OrderedSet([BitSet(1+16*i:16*(1+i)) for i in 0:127]), # stage 8
        OrderedSet([BitSet(1+8*i:8*(1+i)) for i in 0:255]), # stage 9
        OrderedSet([BitSet(1+4*i:4*(1+i)) for i in 0:511]), # stage 10
        OrderedSet([BitSet(1+2*i:2*(1+i)) for i in 0:1023]), # stage 11
        OrderedSet([BitSet(i) for i in 1:2048]) # stage 12
    ]

    dim_to_subspace = [1:Df*2, Df*2+1:Df*4, Df*4+1:Df*6, Df*6+1:Df*8, Df*8+1:Df*10, Df*10+1:Df*12,
    Df*12+1:Df*14, Df*14+1:Df*16, Df*16+1:Df*18, Df*18+1:Df*20, Df*20+1:Df*22, Df*22+1:Df*24+Df*5+In*Df*2]

    custom_nscenarios = 2048
    custom_nstages =12

    scenariotree = ScenarioTree(; depth=12, nbranching=2)

    pb = Problem(
        scenarios,  # scenarios array
        build_fs_CsEV!,
        vec((1/2048).*ones(2048)),                  # scenario probabilities
        custom_nscenarios,
        custom_nstages,
        dim_to_subspace,
        scenariotree
    )
    return pb
end
