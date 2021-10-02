using Distributed
using Statistics

@everywhere using JuMP, RandomizedProgressiveHedging


# include("simple_trialEV.jl")
# include("Simplified_EV.jl")
# include("Automated_pricesEV.jl")
# include("build_priceEV.jl")
# include("Full_EV_version.jl")
using Ipopt
using Plots

function main()
    pb = build_simpleexampleEV()

    hist=OrderedDict{Symbol, Any}(
        :approxsol => zeros(2048,1290)
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

    #########################################################
    # Problem solve: classical PH algo, as in Ruszczynski book, p. 203
    global y_PH = solve_progressivehedging(pb, maxtime=500, printstep=10, hist=hist)
    println("\nSequential solve output is:")
    display(y_PH)
    println("")

    # #########################################################
    Problem solve: synchronous (un parallelized) version of PH
    global y_sync = solve_randomized_sync(pb, maxtime=5, printstep=3*3, hist=hist)
    println("\nSynchronous solve output is:")
    display(y_sync)

    #########################################################
    # Problem solve: synchronous (parallelized) version of PH
    global y_par = solve_randomized_par(pb, maxtime=5, printstep=3, hist=hist)
    println("\nRandom Par solve output is:")
    display(y_par)


    ########################################################
    Problem solve: asynchronous (parallelized) version of PH
    global y_async = solve_randomized_async(pb, maxtime=5, printstep=3*3, hist=hist)
    println("Asynchronous solve output is:")
    display(y_async)

    return
end

main()
#
Tf=12
Df=10
In = 50 # no. of cars
n_scen=2048

pA_val= zeros(n_scen,Tf*Df);
pB_val= zeros(n_scen,Tf*Df);
pU_val= zeros(n_scen,Df);
pD_val= zeros(n_scen,Df);
pC_val= zeros(n_scen,Df);
pIp_val= zeros(n_scen,Df);
pIm_val= zeros(n_scen,Df);
p_charge=zeros(In*Df);
SoC=zeros(In*Df);

pA_val= y_direct[:,1:Tf*Df];
pB_val= y_direct[:,Tf*Df+1:Tf*Df*2];
pU_val= y_direct[:,Tf*Df*2+1:Tf*Df*2+Df];
pD_val= y_direct[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df];
pC_val= y_direct[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df];
pIp_val= y_direct[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df];
pIm_val= y_direct[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df];
p_ch_val=y_direct[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df];
SoC_val=y_direct[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2];

pA_PH= zeros(n_scen,Tf*Df);
pB_PH= zeros(n_scen,Tf*Df);
pU_PH= zeros(n_scen,Df);
pD_PH= zeros(n_scen,Df);
pC_PH= zeros(n_scen,Df);
pIp_PH= zeros(n_scen,Df);
pIm_PH= zeros(n_scen,Df);
p_ch_PH=zeros(In*Df);
SoC_PH=zeros(In*Df);

pA_PH= y_PH[:,1:Tf*Df];
pB_PH= y_PH[:,Tf*Df+1:Tf*Df*2];
pU_PH= y_PH[:,Tf*Df*2+1:Tf*Df*2+Df];
pD_PH= y_PH[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df];
pC_PH= y_PH[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df];
pIp_PH= y_PH[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df];
pIm_PH= y_PH[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df];
p_ch_PH=y_PH[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df];
SoC_PH=y_PH[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2];

pA_sync= zeros(n_scen,Tf*Df);
pB_sync= zeros(n_scen,Tf*Df);
pU_sync= zeros(n_scen,Df);
pD_sync= zeros(n_scen,Df);
pC_sync= zeros(n_scen,Df);
pIp_sync= zeros(n_scen,Df);
pIm_sync= zeros(n_scen,Df);
p_ch_sync=zeros(In*Df);
SoCsync=zeros(In*Df);

pA_sync= y_sync[:,1:Tf*Df];
pB_sync= y_sync[:,Tf*Df+1:Tf*Df*2];
pU_sync= y_sync[:,Tf*Df*2+1:Tf*Df*2+Df];
pD_sync= y_sync[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df];
pC_sync= y_sync[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df];
pIp_sync= y_sync[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df];
pIm_sync= y_sync[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df];
p_ch_sync=y_sync[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df];
SoC_sync=y_sync[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2];

pA_par= zeros(n_scen,Tf*Df);
pB_par= zeros(n_scen,Tf*Df);
pU_par= zeros(n_scen,Df);
pD_par= zeros(n_scen,Df);
pC_par= zeros(n_scen,Df);
pIp_par= zeros(n_scen,Df);
pIm_par= zeros(n_scen,Df);
p_ch_par=zeros(In*Df);
SoC_par=zeros(In*Df);

pA_par= y_par[:,1:Tf*Df];
pB_par= y_par[:,Tf*Df+1:Tf*Df*2];
pU_par= y_par[:,Tf*Df*2+1:Tf*Df*2+Df];
pD_par= y_par[:,Tf*Df*2+Df+1:Tf*Df*2+2*Df];
pC_par= y_par[:,Tf*Df*2+2*Df+1:Tf*Df*2+3*Df];
pIp_par= y_par[:,Tf*Df*2+3*Df+1:Tf*Df*2+4*Df];
pIm_par= y_par[:,Tf*Df*2+4*Df+1:Tf*Df*2+5*Df];
p_ch_par=y_par[:,Tf*Df*2+5*Df+1:Tf*Df*2+5*Df+In*Df];
SoC_par=y_par[:,Tf*Df*2+5*Df+In*Df+1:Tf*Df*2+5*Df+In*Df*2];

pDA_async= zeros(n_scen,Tf*Df);
pA_async= zeros(n_scen,Tf*Df);
pB_async= zeros(n_scen,Tf*Df);
pU_async= zeros(n_scen,Df);
pD_async= zeros(n_scen,Df);
pC_async= zeros(n_scen,Df);
pIp_async= zeros(n_scen,Df);
pIm_async= zeros(n_scen,Df);
p_ch_async=zeros(In*Df);
SoC_async=zeros(In*Df);

pDA_async= y_async[:,1:Tf*Df];
pA_async= y_async[:,Tf*Df+1:Tf*Df*2];
pB_async= y_async[:,Tf*Df*2+1:Tf*Df*3];
pU_async= y_async[:,Tf*Df*3+1:Tf*Df*3+Df];
pD_async= y_async[:,Tf*Df*3+Df+1:Tf*Df*3+2*Df];
pC_async= y_async[:,Tf*Df*3+2*Df+1:Tf*Df*3+3*Df];
pIp_async= y_async[:,Tf*Df*3+3*Df+1:Tf*Df*3+4*Df];
pIm_async= y_async[:,Tf*Df*3+4*Df+1:Tf*Df*3+5*Df];
p_ch_async=y_async[:,Tf*Df*3+5*Df+1:Tf*Df*3+5*Df+In*Df];
SoC_async=y_async[:,Tf*Df*3+5*Df+In*Df+1:Tf*Df*3+5*Df+In*Df*2];

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

# # plots
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
#
# cost=(1/4096)*(sum(sum(price_scenarios_from_1*pB[1]'+price_scenarios_from_2*pB[2]'+price_scenarios_from_3*pB[3]'+price_scenarios_from_4*pB[4]'+price_scenarios_from_5*pB[5]'+price_scenarios_from_6*pB[6]'+
# price_scenarios_from_7*pB[7]'+price_scenarios_from_8*pB[8]'+price_scenarios_from_9*pB[9]'+price_scenarios_from_10*pB[10]'))-sum(sum(price_scenarios_1*pA[1]'+price_scenarios_2*pA[2]'+price_scenarios_3*pA[3]'
# +price_scenarios_4*pA[4]'+price_scenarios_5*pA[5]'+price_scenarios_6*pA[6]'+price_scenarios_7*pA[7]'+price_scenarios_8*pA[8]'+price_scenarios_9*pA[9]'+price_scenarios_10*pA[10]'))+
# +sum(sum(price_reg_from_1*pD[1]'+ price_reg_from_2*pD[2]'+ price_reg_from_3*pD[3]'+ price_reg_from_4*pD[4]'+price_reg_from_5*pD[5]'+price_reg_from_6*pD[6]'+price_reg_from_7*pD[7]'+
# price_reg_from_8*pD[8]'+price_reg_from_9*pD[9]'+price_reg_from_10*pD[10]'-(price_reg_to_1*pU[1]'+ price_reg_to_2*pU[2]'+ price_reg_to_3*pU[3]'+ price_reg_to_4*pU[4]'+price_reg_to_5*pU[5]'+price_reg_to_6*pU[6]'+price_reg_to_7*pU[7]'+
# price_reg_to_8*pU[8]'+price_reg_to_9*pU[9]'+price_reg_to_10*pU[10]') + lambda_Im*pIm_async' - lambda_Ip*pIp_async')))+(1/2048)*sum((pIp_async + pIm_async).*lambda_f)
#
# cost=(1/12)*(sum(sum(pB[1]'*price_scenarios_from_1+pB[2]'*price_scenarios_from_2+pB[3]'*price_scenarios_from_3+pB[4]'*price_scenarios_from_4+pB[5]'*price_scenarios_from_5+pB[6]'*price_scenarios_from_6+pB[7]'*price_scenarios_from_7+pB[8]'*price_scenarios_from_8+pB[9]'*price_scenarios_from_9+pB[10]'*price_scenarios_from_10))
# -sum(sum(pA[1]'*price_scenarios_1+pA[2]'*price_scenarios_2+pA[3]'*price_scenarios_3+pA[4]'*price_scenarios_4+pA[5]'*price_scenarios_5+pA[6]'*price_scenarios_6+pA[7]'*price_scenarios_7+pA[8]'*price_scenarios_8+pA[9]'*price_scenarios_9+pA[10]'*price_scenarios_10))+sum(sum(pD[1]'*price_reg_from_1+ pD[2]'*price_reg_from_2+
#  pD[3]'*price_reg_from_3+ pD[4]'*price_reg_from_4+pD[5]'*price_reg_from_5+pD[6]'*price_reg_from_6+pD[7]'*price_reg_from_7+
# pD[8]'*price_reg_from_8+pD[9]'*price_reg_from_9+pD[10]'*price_reg_from_10-(pU[1]'*price_reg_to_1+ pU[2]'*price_reg_to_2+ pU[3]'*price_reg_to_3+ pU[4]'*price_reg_to_4+pU[5]'*price_reg_to_5+pU[6]'*price_reg_to_6+pU[7]'price_reg_to_7+pU[8]'*price_reg_to_8+pU[9]'*price_reg_to_9+pU[10]'*price_reg_to_10)
# + pIm_async'*lambda_Im - pIp_async'*lambda_Ip)))+(1/2048)*sum((pIp_async + pIm_async).*lambda_f)

# cost=(1/12)*(sum(sum(pB[1]'*price_scenarios_from_1+pB[2]'*price_scenarios_from_2+pB[3]'*price_scenarios_from_3+pB[4]'*price_scenarios_from_4+pB[5]'*price_scenarios_from_5+pB[6]'*price_scenarios_from_6+pB[7]'*price_scenarios_from_7+pB[8]'*price_scenarios_from_8+pB[9]'*price_scenarios_from_9+pB[10]'*price_scenarios_from_10))
# -sum(sum(pA[1]'*price_scenarios_1+pA[2]'*price_scenarios_2+pA[3]'*price_scenarios_3+pA[4]'*price_scenarios_4+pA[5]'*price_scenarios_5+pA[6]'*price_scenarios_6+pA[7]'*price_scenarios_7+pA[8]'*price_scenarios_8+pA[9]'*price_scenarios_9+pA[10]'*price_scenarios_10)))+
# + (1/12)*sum((pIm_async'*lambda_Im - pIp_async'*lambda_Ip))+(1/2048)*sum((pIp_async + pIm_async).*lambda_f)

cost=(1/2048)*(sum(sum(price_scenarios_from_1*pB[1]'+price_scenarios_from_2*pB[2]'+price_scenarios_from_3*pB[3]'+price_scenarios_from_4*pB[4]'+price_scenarios_from_5*pB[5]'+price_scenarios_from_6*pB[6]'+
price_scenarios_from_7*pB[7]'+price_scenarios_from_8*pB[8]'+price_scenarios_from_9*pB[9]'+price_scenarios_from_10*pB[10]'))-sum(sum(price_scenarios_1*pA[1]'+price_scenarios_2*pA[2]'+price_scenarios_3*pA[3]'
+price_scenarios_4*pA[4]'+price_scenarios_5*pA[5]'+price_scenarios_6*pA[6]'+price_scenarios_7*pA[7]'+price_scenarios_8*pA[8]'+price_scenarios_9*pA[9]'+price_scenarios_10*pA[10]'))+
+sum(sum(price_reg_from_1*pD[1]'+ price_reg_from_2*pD[2]'+ price_reg_from_3*pD[3]'+ price_reg_from_4*pD[4]'+price_reg_from_5*pD[5]'+price_reg_from_6*pD[6]'+price_reg_from_7*pD[7]'+
price_reg_from_8*pD[8]'+price_reg_from_9*pD[9]'+price_reg_from_10*pD[10]'-(price_reg_to_1*pU[1]'+ price_reg_to_2*pU[2]'+ price_reg_to_3*pU[3]'+ price_reg_to_4*pU[4]'+price_reg_to_5*pU[5]'+price_reg_to_6*pU[6]'+price_reg_to_7*pU[7]'+
price_reg_to_8*pU[8]'+price_reg_to_9*pU[9]'+price_reg_to_10*pU[10]') + lambda_Im*pIm_async' - lambda_Ip*pIp_async')))+(1/2048)*sum((pIp_async + pIm_async).*lambda_f)
#

display(cost)
