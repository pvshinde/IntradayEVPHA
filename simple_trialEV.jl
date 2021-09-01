using Distributed
using DataStructures, LinearAlgebra
using RandomizedProgressiveHedging, JuMP
@everywhere const RPH = RandomizedProgressiveHedging
#
# @everywhere struct PriceScenarios <: RPH.AbstractScenario
#     ID_ask_price::Vector{Float64}
# end

@everywhere struct SimpleExScenario <: RPH.AbstractScenario
    trajcenter::Vector{Float64}
    constraintbound::Int
end
@everywhere function build_fs_CsEV(model::JuMP.Model, s::SimpleExScenario, id_scen::RPH.ScenarioId)
    # n = length(s.trajcenter)

    Wf = 3 # stages
    Df = 1 # no. of time slots
    Nf = 4 # no. of car cluster
    In = 12 # no. of cars
    Mn = 5 # no. of reservations
    # Wf = 10 # no. of scenarios
    Vf = 10 # no. of scenarios for NAC

    Pmax = 6.6 #maximal charging rate
    SoCmax = 24 #upper limit of soc of car i in cluster n
    L1 = 2
    L2 = 24
    # L3 = 1000
    alpha = 0.9 #charging efficiency
    lambda_f = 0.5 #imbalance fee
    delta_d = 1 #time step
    Q = 24*ones(Mn, Nf, Wf) #reserved battery level of reservation m in cluster n scenario w (3D)
    Tleave = [24, 24, 24, 24]
    epsilon = 5
    pi_w = 0.25 # probability of scenarios

    # lambda_Im = zeros(Wf, Df)
    # lambda_Ip = zeros(Wf, Df)
    # sigmaU = zeros(Wf, Df)
    # sigmaD = zeros(Wf, Df)

    # Convert weathertype::Int into stage to rain level
    # stage_to_rainlevel = int_to_bindec(s.weathertype, s.nstages) .+1

    pA = @variable(model, [1:Wf], base_name="pA$id_scen")
    pB = @variable(model, [1:Wf], base_name="pB$id_scen")
    # pU = @variable(model, [1:Wf, 1:Df], base_name="pU$id_scen")
    # pD = @variable(model, [1:Wf, 1:Df], base_name="pD$id_scen")
    # pC = @variable(model, [1:Wf, 1:Df], base_name="pC$id_scen")
    # pIp = @variable(model, [1:Wf, 1:Df], base_name="pIp$id_scen")
    # pIm = @variable(model, [1:Wf, 1:Df], base_name="pIm$id_scen")
    # cI = @variable(model, [1:Wf, 1:Df], base_name="cI$id_scen")
    # pch = @variable(model, [1:In, 1:Nf, 1:Df], base_name="pch$id_scen")
    # SoC = @variable(model, [1:In, 1:Nf, 1:Wf, 1:Df], base_name="SoC$id_scen")
    # y = @variable(model, [1:In, 1:Nf, 1:Wf, 1:Df], base_name="y$id_scen", Bin) #binary
    # a = @variable(model, [1:In, 1:Nf, 1:Wf, 1:Df], base_name="a$id_scen", Bin) #binary
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

    objexpr = sum(pA[w] - pB[w] for w in 1:Wf)# do not need a scenario index, t is stage, d id DP
    # @constraint(model, [w=1:Wf, d=1:Df], pA[w,d] - pB[w,d]  == 0)

    # @constraint(model, y .<= s.constraintbound)

    return objexpr
end

function build_simpleexampleEV()
        #########################################################
    ## Problem definition
    #
    # scenario1 = PriceScenarios([3, 4, 6]) # assuming three ID stages will correspond to 4 scenarios if nbranching=2, one BM stage
    # scenario2 = PriceScenarios([3, 4, 7])
    # scenario3 = PriceScenarios([3, 5, 8])
    # scenario4 = PriceScenarios([3, 5, 9])


    scenario1 = SimpleExScenario([1, 1, 1], 3)
    scenario2 = SimpleExScenario([2, 2, 2], 3)
    scenario3 = SimpleExScenario([3, 3, 3], 3)

    # stage to scenario partition
    stageid_to_scenpart = [
        OrderedSet([BitSet(1:3)]),                      # Stage 1
        OrderedSet([BitSet(1), BitSet(2:3)]),           # Stage 2
        OrderedSet([BitSet(1), BitSet(2), BitSet(3)]),  # Stage 3
    ]

    nstages = 3
    nscenarios = 4

    # scenariotree =  ScenarioTree(; depth=nstages, nbranching=2)
    # dim_to_subspace = [1:6,7:12,13:18]

    pb = Problem(
        [scenario1, scenario2, scenario3],  # scenarios array
        build_fs_CsEV,
        [0.5, 0.25, 0.25],                  # scenario probabilities
        [1:1, 2:2, 3:3],                    # stage id to trajectory coordinates, required for projection
        stageid_to_scenpart)

    #
    #     [scenario1, scenario2, scenario3, scenario4],  # scenarios array
    #     build_fs_CsEV!,
    #     [0.25, 0.25, 0.25, 0.25],                  # scenario probabilities
    #     nscenarios,
    #     nstages,
    #     dim_to_subspace,
    #     scenariotree
    # )
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
