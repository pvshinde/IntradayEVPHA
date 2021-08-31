using Distributed
using DataStructures, LinearAlgebra
using RandomizedProgressiveHedging, JuMP
@everywhere const RPH = RandomizedProgressiveHedging

@everywhere struct PriceScenarios <: RPH.AbstractScenario
    ID_ask_price::Vector{Float64}
    ID_buy_price::Vector{Float64}
    Up_reg_price::Vector{Float64}
    Dn_reg_price::Vector{Float64}
end



@everywhere function build_fs_CsEV!(model::JuMP.Model, s::PriceScenarios, id_scen::RPH.ScenarioId)
    n = length(s.trajcenter)

    Df = 24 # no. of time slots
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
    delta_d = 1 #time step
    Q = 24*ones(Mn, Nf, Wf) #reserved battery level of reservation m in cluster n scenario w (3D)
    Tleave = [24, 24, 24, 24]
    epsilon = 5
    pi_w = 0.05 # probability of scenarios

    lambda_Im = zeros(Wf, Df)
    lambda_Ip = zeros(Wf, Df)
    sigmaU = zeros(Wf, Df)
    sigmaD = zeros(Wf, Df)

    # Convert weathertype::Int into stage to rain level
    # stage_to_rainlevel = int_to_bindec(s.weathertype, s.nstages) .+1

    pA = @variable(model, [1:Wf, 1:Df], base_name="pA$id_scen")
    pB = @variable(model, [1:Wf, 1:Df], base_name="pB$id_scen")
    pU = @variable(model, [1:Wf, 1:Df], base_name="pU$id_scen")
    pD = @variable(model, [1:Wf, 1:Df], base_name="pD$id_scen")
    pC = @variable(model, [1:Wf, 1:Df], base_name="pC$id_scen")
    pIp = @variable(model, [1:Wf, 1:Df], base_name="pIp$id_scen")
    pIm = @variable(model, [1:Wf, 1:Df], base_name="pIm$id_scen")
    cI = @variable(model, [1:Wf, 1:Df], base_name="cI$id_scen")
    pch = @variable(model, [1:In, 1:Nf, 1:Df], base_name="pch$id_scen")
    SoC = @variable(model, [1:In, 1:Nf, 1:Wf, 1:Df], base_name="SoC$id_scen")
    y = @variable(model, [1:In, 1:Nf, 1:Wf, 1:Df], base_name="y$id_scen", Bin) #binary
    a = @variable(model, [1:In, 1:Nf, 1:Wf, 1:Df], base_name="a$id_scen", Bin) #binary
    #
    # @constraint(model, pch .>= 0)
    # @constraint(model, SoC .>= 0)
    # @constraint(model, pA .>= 0)
    # @constraint(model, pB .>= 0)
    # @constraint(model, pU .>= 0)
    # @constraint(model, pD .>= 0)
    # @constraint(model, pIp .>= 0)
    # @constraint(model, pIm .>= 0)

    # y = @variable(model, [1:n], base_name="y_s$id_scen")
    # objexpr = sum((y[i] - s.trajcenter[i])^2 for i in 1:n)

    objexpr = sum(sum(pi_w*pA[w,d] + pi_w*pD[w,d] -pi_w*pU[w,d] for d in 1:Df) for w in Wf)
    @constraint(model, [w=1:Wf, d=1:Df], pIp[w,d] - pIm[w,d] == pA[w,d] - pB[w,d] + pD[w,d] -pU[w,d] -pC[w,d])

    # @constraint(model, y .<= s.constraintbound)

    return y, objexpr, []
end

function build_simpleexampleEV()
        #########################################################
    ## Problem definition

    scenario1 = PriceScenarios([3, 4, 6, 5], [2, 2, 1, 3], [7], [4]) # assuming three ID stages will correspond to 4 scenarios if nbranching=2, one BM stage
    scenario2 = PriceScenarios([3, 5, 7, 3], [2, 2, 1, 2], [8], [4])
    scenario3 = PriceScenarios([4, 3, 6, 7], [3, 2, 3, 2], [6], [3])

    # stage to scenario partition
    # stageid_to_scenpart = [
    #     OrderedSet([BitSet(1:3)]),                      # Stage 1
    #     OrderedSet([BitSet(1), BitSet(2:3)]),           # Stage 2
    #     OrderedSet([BitSet(1), BitSet(2), BitSet(3)]),  # Stage 3
    # ]

    scenariotree =  ScenarioTree(; depth=nstages, nbranching=2)

    pb = Problem(
        [scenario1, scenario2, scenario3],  # scenarios array
        build_fs_CsEV!,
        [0.5, 0.25, 0.25],                  # scenario probabilities
        nscenarios,
        nstages,
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
