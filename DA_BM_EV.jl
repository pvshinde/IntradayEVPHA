# using Distributed
# using DataStructures, LinearAlgebra
# using RandomizedProgressiveHedging, JuMP

using JuMP, GLPK, LinearAlgebra

model = Model(with_optimizer(GLPK.Optimizer))

# Tf = 24 # no. of time slots
# using Revise

    # n = length(s.trajcenter)
    # Tf = [3, 4, 5] # no. of stages, different for different DPs
    Tf = 14
    Df = 10 # no. of time slots (Delivery products)
    In = 50 # no. of cars
    Wf= 100

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
    lambda_DA=[18.6211, 21.5615, 15.8325, 20.1678, 31.5517, 28.7284, 27.2569, 23.7927, 28.4911, 31.8757]

# price_to is SE3 buying
#price_from is SE3 selling a up

price_reg_D=zeros(100,10)
price_reg_D=hcat(price_reg_to_1[1:100,:], price_reg_to_2[1:100,:], price_reg_to_3[1:100,:],price_reg_to_4[1:100,:], price_reg_to_5[1:100,:], price_reg_to_6[1:100,:],price_reg_to_7[1:100,:],
price_reg_to_8[1:100,:], price_reg_to_9[1:100,:],price_reg_to_10[1:100,:])
price_reg_U=zeros(100,10)
price_reg_U=hcat(price_reg_from_1[1:100,:], price_reg_from_2[1:100,:], price_reg_from_3[1:100,:],price_reg_from_4[1:100,:],price_reg_from_5[1:100,:],price_reg_from_6[1:100,:],price_reg_from_7[1:100,:],
price_reg_from_8[1:100,:], price_reg_from_9[1:100,:],price_reg_from_10[1:100,:])

# price_regD=hcat(price_reg_from[1], price_reg_from[2], price_reg_from[3],price_reg_from[4],price_reg_from[5],price_reg_from[6],price_reg_from[7],
# price_reg_from[8], price_reg_from[9],price_reg_from[10])

    @variable(model, 0 <= pA[w = 1:Wf, d = 1:Df]) #day ahead purchase for time t in scenario w
    @variable(model, 0 <= pU[w = 1:Wf, d = 1:Df]) #up regulation power for time t in scenario w
    @variable(model, 0 <= pD[w = 1:Wf, d = 1:Df]) #down regulation power for time t in scenario w
    @variable(model, 0 <= pC[w = 1:Wf, d = 1:Df])
    @variable(model, 0 <= pIp[w = 1:Wf, d = 1:Df])
    @variable(model, 0 <= pIm[w = 1:Wf, d = 1:Df])
    # @variable(model, cI[w = 1:Wf, d = 1:Tf])
    @variable(model, 0 <= pcharge[ w = 1:Wf, i = 1:In, d = 1:Df])
    @variable(model, 0 <= SoC[w = 1:Wf, i = 1:In, d = 1:Df])

    @constraint(model, pcharge .>= 0)
    @constraint(model, SoC .>= 0)
    @constraint(model, pU .>= 0)
    @constraint(model, pD .>= 0)
    @constraint(model, pIp .>= 0)
    @constraint(model, pIm .>= 0)

    @constraint(model, [w=1:Wf, d=1:Df], pIp[w,d] - pIm[w,d] == P_DA[d] + pD[w,d] - pU[w,d] - pC[w,d])

    @constraint(model,
        [w=1:Wf, d = 1:Df], pC[w,d] == sum(pcharge[w,i, d] for i = 1:In))

for w = 1:Wf
for i = 1:In
    for d = 1:Df
        if d0[i] > d && d > DD[i]
            @constraint(model, pcharge[w,i, d] == 0)
        else
            @constraint(model, pcharge[w,i, d] <= Pmax)
        end
        if d >= d0[i] && d < DD[i]
            if d == d0[i]
                @constraint(model, SoC[w,i, d] == SoC_init[i] + alpha * pcharge[w,i, d] * delta_d)
            else
                @constraint(model, SoC[w,i, d] == SoC[w,i, d-1] + alpha * pcharge[w,i, d] * delta_d)
            end
            @constraint(model, SoC[w,i, d] <= SoCmax)
        else
            @constraint(model, SoC[w,i, d] == 0)
        end
        if  d == DD[i]-1
            @constraint(model, Q[i] - SoC[w,i, d] <= epsilon)  # equation 21
        end
    end
end
end

@constraint(model, [w=1:Wf, d = 1:Df], pU[w,d] <=  P_DA[d])  # equation 31

@constraint(model, [w=1:Wf, d = 1:Df], sum(pcharge[w,i, d] for i in In) - (P_DA[d]) >= pD[w,d])  # equation 32
# make sure that pcharge for i is 0 when d is less than d0 and greater than DD for that EV

    # objexpr = (1/8192)*(sum(pD[w,d]*price_reg_D[w,d] - pU[w,d] *price_reg_U[w,d]  + pIm[w,d]*lambda_Im_14[w,d] - pIp[w,d]*lambda_Ip_14[w,d] +
    #             (pIp[w,d] + pIm[w,d]) * lambda_f for d in Df))

@objective(model,Min,(1/100)*sum(sum(pD[w,d]*price_reg_D[w,d] - pU[w,d] *price_reg_U[w,d]  + pIm[w,d]*lambda_Im[w,d] - pIp[w,d]*lambda_Ip[w,d] +
            (pIp[w,d] + pIm[w,d]) * lambda_f for d in Df) for w in Wf))

    # print(model)
    # print(JuMP.value.(pA))
optimize!(model)

cost=(1/100)*sum(sum( JuMP.value.(pD[w,d])*price_reg_D[w,d] -  JuMP.value.(pU[w,d]) *price_reg_U[w,d]  +
JuMP.value.(pIm[w,d])*lambda_Im[w,d] - JuMP.value.(pIp[w,d])*lambda_Ip[w,d] +(JuMP.value.(pIp[w,d]) +
 JuMP.value.(pIm[w,d])) * lambda_f for d in Df) for w in Wf)
display(cost)
pUp=JuMP.value.(pU)
pDn=JuMP.value.(pD)
pImb=JuMP.value.(pIm)
pIpb=JuMP.value.(pIp)
        #########################################################
    ## Problem definition
#     Tf = 14 # no. of stages
#     Df = 10 # no. of time slots (Delivery products)
#     In = 50 # no. of cars
#
# #assuming three ID stages will correspond to 4 scenarios if nbranching=2, one BM stage
#
# scenarios = [PriceScenario([price_scen_to[1][i:i,:]; price_scen_to[2][i:i,:];price_scen_to[3][i:i,:]; price_scen_to[4][i:i,:];price_scen_to[5][i:i,:];
#  price_scen_to[6][i:i,:];price_scen_to[7][i:i,:]; price_scen_to[8][i:i,:];price_scen_to[9][i:i,:]; price_scen_to[10][i:i,:]],
#  [price_scen_from[1][i:i,:]; price_scen_from[2][i:i,:];price_scen_from[3][i:i,:]; price_scen_from[4][i:i,:];price_scen_from[5][i:i,:];
#  price_scen_from[6][i:i,:];price_scen_from[7][i:i,:]; price_scen_from[8][i:i,:];price_scen_from[9][i:i,:]; price_scen_from[10][i:i,:]],
#  [price_reg_to[1][i:i,1:1]; price_reg_to[2][i:i,1:1];price_reg_to[3][i:i,1:1]; price_reg_to[4][i:i,1:1];price_reg_to[5][i:i,1:1];price_reg_to[6][i:i,1:1]; price_reg_to[7][i:i,1:1];
#  price_reg_to[8][i:i,1:1]; price_reg_to[9][i:i,1:1]; price_reg_to[10][i:i,1:1]],
#  [price_reg_from[1][i:i,1:1]; price_reg_from[2][i:i,1:1];price_reg_from[3][i:i,1:1]; price_reg_from[4][i:i,1:1];price_reg_from[5][i:i,1:1];price_reg_from[6][i:i,1:1];
#  price_reg_from[7][i:i,1:1]; price_reg_from[8][i:i,1:1];price_reg_from[9][i:i,1:1]; price_reg_from[10][i:i,1:1]],
#  lambda_Ip_14[i:i,:], lambda_Im_14[i:i,:]) for i in 1:8192]

# scenarios = [PriceScenarios([price_scenarios_8[i:i,9:12]; price_scenarios_9[i:i,9:12]; price_scenarios_10[i:i,9:12]], [price_scenarios_from_7[i:i,9:12]; price_scenarios_from_8[i:i,9:12];
# price_scenarios_from_9[i:i,9:12]], [price_reg_to_1[i:i,1:1]; price_reg_to_2[i:i,1:1]; price_reg_to_3[i:i,1:1]], [price_reg_from_1[i:i,1:1]; price_reg_from_2[i:i,1:1]; price_reg_from_3[i:i,1:1]]) for i in 1:8]
