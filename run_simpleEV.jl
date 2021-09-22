using Distributed
@everywhere using JuMP, RandomizedProgressiveHedging

# include("simple_trialEV.jl")
include("Simplified_EV.jl")
using Ipopt

function main()
    pb = build_simpleexampleEV()
    #
    hist=OrderedDict{Symbol, Any}(
        :approxsol => zeros(4,17)
    )

    println("Full problem is:")
    println(pb)

    #########################################################
    ## Problem solve: build and solve complete problem, exponential in constraints
    global y_direct = solve_direct(pb, optimizer = Ipopt.Optimizer)
    println("\nDirect solve output is:")
    display(y_direct)
    println("")

    #
    # #########################################################
    # ## Problem solve: classical PH algo, as in Ruszczynski book, p. 203
    y_PH = solve_progressivehedging(pb, maxtime=5, printstep=3, hist=hist)
    println("\nSequential solve output is:")
    display(y_PH)
    println("")
    #
    # #########################################################
    # ## Problem solve: synchronous (un parallelized) version of PH
    # y_sync = solve_randomized_sync(pb, maxtime=5, printstep=3*3, hist=hist)
    # println("\nSynchronous solve output is:")
    # display(y_sync)
    #
    # #########################################################
    # ## Problem solve: asynchronous (parallelized) version of PH
    # y_par = solve_randomized_par(pb, maxtime=5, printstep=3, hist=hist)
    # println("\nRandom Par solve output is:")
    # display(y_par)
    #
    #
    # #########################################################
    # ## Problem solve: asynchronous (parallelized) version of PH
    # y_async = solve_randomized_async(pb, maxtime=5, printstep=3*3, hist=hist)
    # println("Asynchronous solve output is:")
    # display(y_async)

    return
end

main()

Tf=3
Df=1
In = 3 # no. of cars
n_scen=4
pA_val= zeros(n_scen,Tf*Df)
pB_val= zeros(n_scen,Tf*Df)
pU_val= zeros(n_scen,Df)
pD_val= zeros(n_scen,Df)
pC_val= zeros(n_scen,Df)
pIp_val= zeros(n_scen,Df)
pIm_val= zeros(n_scen,Df)
p_charge=zeros(In*Df)
SoC=zeros(In*Df)

pA_val= y_direct[:,1:Tf*Df]
pB_val= y_direct[:,Tf*Df+1:Tf*Df*2]
pU_val= y_direct[:,Tf*Df*2+1:Tf*Df*2+Df]
pD_val= y_direct[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df]
pC_val= y_direct[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df]
pIp_val= y_direct[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df]
pIm_val= y_direct[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df]
p_charge=y_direct[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df]
SoC=y_direct[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2]
