using Distributed
using Statistics

@everywhere using JuMP, RandomizedProgressiveHedging

# include("simple_trialEV.jl")
# include("Simplified_EV.jl")
# include("Automated_pricesEV.jl")
include("Full_EV_14stages.jl")
using Ipopt
using Plots

function main()
    pb = build_simpleexampleEV()
    #
    hist=OrderedDict{Symbol, Any}(
        :approxsol => zeros(8196,1330)
    )

    println("Full problem is:")
    println(pb)

    #########################################################
    # Problem solve: build and solve complete problem, exponential in constraints
    # global y_direct = solve_direct(pb, optimizer = Ipopt.Optimizer)
    # println("\nDirect solve output is:")
    # display(y_direct)
    # println("")
    #
    #
    # #########################################################
    ## Problem solve: classical PH algo, as in Ruszczynski book, p. 203
    # global y_PH = solve_progressivehedging(pb, maxtime=500, printstep=10, hist=hist)
    # println("\nSequential solve output is:")
    # display(y_PH)
    # println("")
    #
    # # # #########################################################
    # # Problem solve: synchronous (un parallelized) version of PH
    # global y_sync = solve_randomized_sync(pb, maxtime=5, printstep=3*3, hist=hist)
    # println("\nSynchronous solve output is:")
    # display(y_sync)

    #########################################################
    # Problem solve: synchronous (parallelized) version of PH
    global y_par = solve_randomized_par(pb, maxtime=5, printstep=3, hist=hist)
    println("\nRandom Par solve output is:")
    display(y_par)


    #########################################################
    ## Problem solve: asynchronous (parallelized) version of PH
    global y_async = solve_randomized_async(pb, maxtime=5, printstep=3*3, hist=hist)
    println("Asynchronous solve output is:")
    display(y_async)

    @show norm(y_sync - y_PH)
    @show norm(y_sync - y_par)
    @show norm(y_sync - y_async)

    return
end

main()

Tf=14
Df=10
In = 50 # no. of cars
# n_scen=8196
# #
# pA_val= zeros(n_scen,Tf*Df);
# pB_val= zeros(n_scen,Tf*Df);
# pU_val= zeros(n_scen,Df);
# pD_val= zeros(n_scen,Df);
# pC_val= zeros(n_scen,Df);
# pIp_val= zeros(n_scen,Df);
# pIm_val= zeros(n_scen,Df);
# p_charge=zeros(In*Df);
# SoC=zeros(In*Df);
#
# pA_val= y_direct[:,1:Tf*Df];
# pB_val= y_direct[:,Tf*Df+1:Tf*Df*2];
# pU_val= y_direct[:,Tf*Df*2+1:Tf*Df*2+Df];
# pD_val= y_direct[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df];
# pC_val= y_direct[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df];
# pIp_val= y_direct[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df];
# pIm_val= y_direct[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df];
# p_ch_val=y_direct[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df];
# SoC_val=y_direct[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2];
#
# pA_PH= zeros(n_scen,Tf*Df);
# pB_PH= zeros(n_scen,Tf*Df);
# pU_PH= zeros(n_scen,Df);
# pD_PH= zeros(n_scen,Df);
# pC_PH= zeros(n_scen,Df);
# pIp_PH= zeros(n_scen,Df);
# pIm_PH= zeros(n_scen,Df);
# p_ch_PH=zeros(In*Df);
# SoC_PH=zeros(In*Df);
#
# pA_PH= y_PH[:,1:Tf*Df];
# pB_PH= y_PH[:,Tf*Df+1:Tf*Df*2];
# pU_PH= y_PH[:,Tf*Df*2+1:Tf*Df*2+Df];
# pD_PH= y_PH[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df];
# pC_PH= y_PH[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df];
# pIp_PH= y_PH[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df];
# pIm_PH= y_PH[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df];
# p_ch_PH=y_PH[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df];
# SoC_PH=y_PH[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2];
#
# pA_sync= zeros(n_scen,Tf*Df);
# pB_sync= zeros(n_scen,Tf*Df);
# pU_sync= zeros(n_scen,Df);
# pD_sync= zeros(n_scen,Df);
# pC_sync= zeros(n_scen,Df);
# pIp_sync= zeros(n_scen,Df);
# pIm_sync= zeros(n_scen,Df);
# p_ch_sync=zeros(In*Df);
# SoCsync=zeros(In*Df);
#
# pA_sync= y_sync[:,1:Tf*Df];
# pB_sync= y_sync[:,Tf*Df+1:Tf*Df*2];
# pU_sync= y_sync[:,Tf*Df*2+1:Tf*Df*2+Df];
# pD_sync= y_sync[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df];
# pC_sync= y_sync[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df];
# pIp_sync= y_sync[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df];
# pIm_sync= y_sync[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df];
# p_ch_sync=y_sync[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df];
# SoC_sync=y_sync[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2];
#
# pA_par= zeros(n_scen,Tf*Df);
# pB_par= zeros(n_scen,Tf*Df);
# pU_par= zeros(n_scen,Df);
# pD_par= zeros(n_scen,Df);
# pC_par= zeros(n_scen,Df);
# pIp_par= zeros(n_scen,Df);
# pIm_par= zeros(n_scen,Df);
# p_ch_par=zeros(In*Df);
# SoC_par=zeros(In*Df);
#
# pA_par= y_par[:,1:Tf*Df];
# pB_par= y_par[:,Tf*Df+1:Tf*Df*2];
# pU_par= y_par[:,Tf*Df*2+1:Tf*Df*2+Df];
# pD_par= y_par[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df];
# pC_par= y_par[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df];
# pIp_par= y_par[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df];
# pIm_par= y_par[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df];
# p_ch_par=y_par[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df];
# SoC_par=y_par[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2];
#
pA_async= zeros(n_scen,Tf*Df);
pB_async= zeros(n_scen,Tf*Df);
pU_async= zeros(n_scen,Df);
pD_async= zeros(n_scen,Df);
pC_async= zeros(n_scen,Df);
pIp_async= zeros(n_scen,Df);
pIm_async= zeros(n_scen,Df);
p_ch_async=zeros(In*Df);
SoC_async=zeros(In*Df);

pA_async= y_async[:,1:Tf*Df];
pB_async= y_async[:,Tf*Df+1:Tf*Df*2];
pU_async= y_async[:,Tf*Df*2+1:Tf*Df*2+Df];
pD_async= y_async[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df];
pC_async= y_async[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df];
pIp_async= y_async[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df];
pIm_async= y_async[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df];
p_ch_async=y_async[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df];
SoC_async=y_async[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2];

# plots
plotly()

pA = Dict()
pB = Dict()
for i in 1:10
    pA[i] = pA_async[:, i:Df:end]
    display(bar(mean(pA[i], dims=1)', title="pA DP $i"))
    pB[i] = pB_async[:, i:Df:end]
    display(bar(mean(pB[i], dims=1)', title="pB DP $i"))
end

display(bar(mean(pU_async, dims=1)', title="pU DPs"))
display(bar(mean(pD_async, dims=1)', title="pD DPs"))

display(plot(mean(pC_async, dims=1)', title="pC DPs"))
display(plot(mean(pIm_async, dims=1)', title="pIm DPs"))
display(plot(mean(pIp_async, dims=1)', title="pIp DPs"))

p_ch = Dict()
SoC = Dict()
plt_SoC = plot()
plt_p_ch = plot()
for i in 1:10
    p_ch[i] = p_ch_async[:, i:In:end]
    # display(plot(mean(p_ch[i], dims=1)', title="p_ch EV $i"))
    SoC[i] = SoC_async[:, i:In:end]
    # display(plot(mean(SoC[i], dims=1)', title="SoC EV $i"))
    plot!(plt_SoC, mean(SoC[i], dims=1)', label="SoC $i")
    plot!(plt_p_ch, mean(p_ch[i], dims=1)', label="p_ch $i")
end

display(plt_SoC)
display(plt_p_ch)

pU = Dict()
pD = Dict()
for i in 1:10
    pU[i] = pU_async[:, i:Df:end]
    # display(bar(mean(pA[i], dims=1)', title="pA DP $i"))
    pD[i] = pD_async[:, i:Df:end]
    # display(bar(mean(pB[i], dims=1)', title="pB DP $i"))
end
lambda_f=0.5

cost=(1/8192)*(sum(sum(price_scen_from[1]*pB[1]'+price_scen_from[2]*pB[2]'+price_scen_from[3]*pB[3]'+price_scen_from[4]*pB[4]'+price_scen_from[5]*pB[5]'+price_scen_from[6]*pB[6]'+
price_scen_from[7]*pB[7]'+price_scen_from[8]*pB[8]'+price_scen_from[9]*pB[9]'+price_scen_from[10]*pB[10]'))-sum(sum(price_scen_to[1]*pA[1]'+price_scen_to[2]*pA[2]'+price_scen_to[3]*pA[3]'
+price_scen_to[4]*pA[4]'+price_scen_to[5]*pA[5]'+price_scen_to[6]*pA[6]'+price_scen_to[7]*pA[7]'+price_scen_to[8]*pA[8]'+price_scen_to[9]*pA[9]'+price_scen_to[10]*pA[10]'))+
+sum(sum(price_reg_from[1]*pD[1]'+ price_reg_from[2]*pD[2]'+ price_reg_from[3]*pD[3]'+ price_reg_from[4]*pD[4]'+price_reg_from[5]*pD[5]'+price_reg_from[6]*pD[6]'+price_reg_from[7]*pD[7]'+
price_reg_from[8]*pD[8]'+price_reg_from[9]*pD[9]'+price_reg_from[10]*pD[10]'-(price_reg_to[1]*pU[1]'+ price_reg_to[2]*pU[2]'+ price_reg_to[3]*pU[3]'+ price_reg_to[4]*pU[4]'+price_reg_to[5]*pU[5]'+price_reg_to[6]*pU[6]'+price_reg_to[7]*pU[7]'+
price_reg_to[8]*pU[8]'+price_reg_to[9]*pU[9]'+price_reg_to[10]*pU[10]') + lambda_Im_14*pIm_async' - lambda_Ip_14*pIp_async')))+(1/8192)*sum((pIp_async + pIm_async).*lambda_f)

display(cost)
