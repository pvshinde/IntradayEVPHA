using Distributed
using Statistics

@everywhere using JuMP, RandomizedProgressiveHedging

using GLPK, LinearAlgebra
using XLSX

# cd("./scenarios_10_DPs")

table1=XLSX.readxlsx("price_to_1.xlsx")
sh1=table1["Sheet1"]
price_scenarios_1=sh1["B2:M2049"]
price_scenarios_1=convert(Array{Float64,2},price_scenarios_1)

table1=XLSX.readxlsx("price_to_2.xlsx")
sh1=table1["Sheet1"]
price_scenarios_2=sh1["B2:M2049"]
price_scenarios_2=convert(Array{Float64,2},price_scenarios_2)

table1=XLSX.readxlsx("price_to_3.xlsx")
sh1=table1["Sheet1"]
price_scenarios_3=sh1["B2:M2049"]
price_scenarios_3=convert(Array{Float64,2},price_scenarios_3)

table1=XLSX.readxlsx("price_to_4.xlsx")
sh1=table1["Sheet1"]
price_scenarios_4=sh1["B2:M2049"]
price_scenarios_4=convert(Array{Float64,2},price_scenarios_4)

table1=XLSX.readxlsx("price_to_5.xlsx")
sh1=table1["Sheet1"]
price_scenarios_5=sh1["B2:M2049"]
price_scenarios_5=convert(Array{Float64,2},price_scenarios_5)

table1=XLSX.readxlsx("price_to_6.xlsx")
sh1=table1["Sheet1"]
price_scenarios_6=sh1["B2:M2049"]
price_scenarios_6=convert(Array{Float64,2},price_scenarios_6)

table1=XLSX.readxlsx("price_to_7.xlsx")
sh1=table1["Sheet1"]
price_scenarios_7=sh1["B2:M2049"]
price_scenarios_7=convert(Array{Float64,2},price_scenarios_7)

table1=XLSX.readxlsx("price_to_8.xlsx")
sh1=table1["Sheet1"]
price_scenarios_8=sh1["B2:M2049"]
price_scenarios_8=convert(Array{Float64,2},price_scenarios_8)

table1=XLSX.readxlsx("price_to_9.xlsx")
sh1=table1["Sheet1"]
price_scenarios_9=sh1["B2:M2049"]
price_scenarios_9=convert(Array{Float64,2},price_scenarios_9)

table1=XLSX.readxlsx("price_to_10.xlsx")
sh1=table1["Sheet1"]
price_scenarios_10=sh1["B2:M2049"]
price_scenarios_10=convert(Array{Float64,2},price_scenarios_10)

# create 2048 matrices each with row for DPs and columns for stages
scen_to_1 = zeros(10,12,2)
for i in 1:2
    scen_to_1[:,:,i]=[price_scenarios_1[i,:]'; price_scenarios_2[i,:]';price_scenarios_3[i,:]'; price_scenarios_4[i,:]';price_scenarios_5[i,:]'; price_scenarios_6[i,:]';
    price_scenarios_7[i,:]'; price_scenarios_8[i,:]';price_scenarios_9[i,:]'; price_scenarios_10[i,:]']
end

table1=XLSX.readxlsx("price_from_1.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_1=sh1["B2:M2049"]
price_scenarios_from_1=convert(Array{Float64,2},price_scenarios_from_1)

table1=XLSX.readxlsx("price_from_2.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_2=sh1["B2:M2049"]
price_scenarios_from_2=convert(Array{Float64,2},price_scenarios_from_2)

table1=XLSX.readxlsx("price_from_3.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_3=sh1["B2:M2049"]
price_scenarios_from_3=convert(Array{Float64,2},price_scenarios_from_3)

table1=XLSX.readxlsx("price_from_4.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_4=sh1["B2:M2049"]
price_scenarios_from_4=convert(Array{Float64,2},price_scenarios_from_4)

table1=XLSX.readxlsx("price_from_5.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_5=sh1["B2:M2049"]
price_scenarios_from_5=convert(Array{Float64,2},price_scenarios_from_5)

table1=XLSX.readxlsx("price_from_6.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_6=sh1["B2:M2049"]
price_scenarios_from_6=convert(Array{Float64,2},price_scenarios_from_6)

table1=XLSX.readxlsx("price_from_7.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_7=sh1["B2:M2049"]
price_scenarios_from_7=convert(Array{Float64,2},price_scenarios_from_7)

table1=XLSX.readxlsx("price_from_8.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_8=sh1["B2:M2049"]
price_scenarios_from_8=convert(Array{Float64,2},price_scenarios_from_8)

table1=XLSX.readxlsx("price_from_9.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_9=sh1["B2:M2049"]
price_scenarios_from_9=convert(Array{Float64,2},price_scenarios_from_9)

table1=XLSX.readxlsx("price_from_10.xlsx")
sh1=table1["Sheet1"]
price_scenarios_from_10=sh1["B2:M2049"]
price_scenarios_from_10=convert(Array{Float64,2},price_scenarios_from_10)

# reg from prices
table2=XLSX.readxlsx("reg_price_from_1.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg1=sh2["B2:B2049"]
price_reg_from_1=convert(Array{Float64,2},price_scenarios_reg1)

table2=XLSX.readxlsx("reg_price_from_2.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg2=sh2["B2:B2049"]
price_reg_from_2=convert(Array{Float64,2},price_scenarios_reg2)

table2=XLSX.readxlsx("reg_price_from_3.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg3=sh2["B2:B2049"]
price_reg_from_3=convert(Array{Float64,2},price_scenarios_reg3)

table2=XLSX.readxlsx("reg_price_from_4.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg4=sh2["B2:B2049"]
price_reg_from_4=convert(Array{Float64,2},price_scenarios_reg4)

table2=XLSX.readxlsx("reg_price_from_5.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg5=sh2["B2:B2049"]
price_reg_from_5=convert(Array{Float64,2},price_scenarios_reg5)

table2=XLSX.readxlsx("reg_price_from_6.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg6=sh2["B2:B2049"]
price_reg_from_6=convert(Array{Float64,2},price_scenarios_reg6)

table2=XLSX.readxlsx("reg_price_from_7.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg7=sh2["B2:B2049"]
price_reg_from_7=convert(Array{Float64,2},price_scenarios_reg7)

table2=XLSX.readxlsx("reg_price_from_8.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg8=sh2["B2:B2049"]
price_reg_from_8=convert(Array{Float64,2},price_scenarios_reg8)

table2=XLSX.readxlsx("reg_price_from_9.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg9=sh2["B2:B2049"]
price_reg_from_9=convert(Array{Float64,2},price_scenarios_reg9)

table2=XLSX.readxlsx("reg_price_from_10.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg10=sh2["B2:B2049"]
price_reg_from_10=convert(Array{Float64,2},price_scenarios_reg10)

#reg to prices
table2=XLSX.readxlsx("reg_price_to_1.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg1=sh2["B2:B2049"]
price_reg_to_1=convert(Array{Float64,2},price_scenarios_reg1)

table2=XLSX.readxlsx("reg_price_to_2.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg2=sh2["B2:B2049"]
price_reg_to_2=convert(Array{Float64,2},price_scenarios_reg2)

table2=XLSX.readxlsx("reg_price_to_3.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg3=sh2["B2:B2049"]
price_reg_to_3=convert(Array{Float64,2},price_scenarios_reg3)

table2=XLSX.readxlsx("reg_price_to_4.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg4=sh2["B2:B2049"]
price_reg_to_4=convert(Array{Float64,2},price_scenarios_reg4)

table2=XLSX.readxlsx("reg_price_to_5.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg5=sh2["B2:B2049"]
price_reg_to_5=convert(Array{Float64,2},price_scenarios_reg5)

table2=XLSX.readxlsx("reg_price_to_6.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg6=sh2["B2:B2049"]
price_reg_to_6=convert(Array{Float64,2},price_scenarios_reg6)

table2=XLSX.readxlsx("reg_price_to_7.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg7=sh2["B2:B2049"]
price_reg_to_7=convert(Array{Float64,2},price_scenarios_reg7)

table2=XLSX.readxlsx("reg_price_to_8.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg8=sh2["B2:B2049"]
price_reg_to_8=convert(Array{Float64,2},price_scenarios_reg8)

table2=XLSX.readxlsx("reg_price_to_9.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg9=sh2["B2:B2049"]
price_reg_to_9=convert(Array{Float64,2},price_scenarios_reg9)

table2=XLSX.readxlsx("reg_price_to_10.xlsx")
sh2=table2["Sheet1"]
price_scenarios_reg10=sh2["B2:B2049"]
price_reg_to_10=convert(Array{Float64,2},price_scenarios_reg10)

# price_reg_to = Dict()
# for i in 1:10
#     table2=XLSX.readxlsx("reg_price_to_$i.xlsx")
#     sh2=table2["Sheet1"]
#     price_scenarios_reg10=sh2["B2:B2049"]
#     price_reg_to[i]=convert(Array{Float64,2},price_scenarios_reg10)
# end

price_DA = [price_scenarios_1[1,1] price_scenarios_2[1,1] price_scenarios_3[1,1] price_scenarios_4[1,1] price_scenarios_5[1,1] price_scenarios_6[1,1] price_scenarios_7[1,1] price_scenarios_8[1,1] price_scenarios_9[1,1] price_scenarios_10[1,1]]

scen_reg_from = zeros(10,2048)
scen_reg_to = zeros(10,2048)

for w=1:2048
    scen_reg_from[:,w]=[price_reg_from_1[w]'; price_reg_from_2[w]'; price_reg_from_3[w]'; price_reg_from_4[w]';price_reg_from_5[w]'; price_reg_from_6[w]';price_reg_from_7[w]'; price_reg_from_8[w]';price_reg_from_9[w]'; price_reg_from_10[w]']
    scen_reg_to[:,w] = [price_reg_to_1[w]'; price_reg_to_2[w]'; price_reg_to_3[w]'; price_reg_to_4[w]';price_reg_to_5[w]'; price_reg_to_6[w]';price_reg_to_7[w]'; price_reg_to_8[w]';price_reg_to_9[w]'; price_reg_to_10[w]']
end

sigmaU=zeros(2048,10)
sigmaD=zeros(2048,10)
lambda_Ip=zeros(2048,10)
lambda_Im=zeros(2048,10)

for d = 1:10
    for w = 1:2048
        sigmaU[w,d] = scen_reg_from[d,w] - price_DA[d]
        sigmaD[w,d] = scen_reg_to[d,w] - price_DA[d]

        if sigmaD[w,d] < 0
            lambda_Ip[w,d] = scen_reg_to[d,w]
        elseif sigmaD[w,d] == 0
            lambda_Ip[w,d] = price_DA[d]
        end

        if sigmaU[w,d] > 0 # equation 8
            lambda_Im[w,d] = scen_reg_from[d,w]
        elseif sigmaU[w,d] == 0
            lambda_Im[w,d] = price_DA[d]
        end
    end
end

# cd("..")

# include("simple_trialEV.jl")
# include("Simplified_EV.jl")
# include("Automated_pricesEV.jl")
# include("build_priceEV.jl")
include("Full_EV_version.jl")
using Ipopt
using Plots

function main()
    pb = build_simpleexampleEV()

    hist=OrderedDict{Symbol, Any}(
        :approxsol => Float64[]
    )

    println("Full problem is:")
    println(pb)

    cvar_lev = 0.5
    pbcvar = cvar_problem(pb, cvar_lev)

    function callback(cvar_pb::Problem, x, hist)
        @assert hist !== nothing

        !haskey(hist, :cvarvalues) && (hist[:cvarvalues]=Float64[])

        fvalues = [objective_value(pb, x[:, 2:end], id_scen) for id_scen in 1:pb.nscenarios]
        model = Model(GLPK.Optimizer)

        @variable(model, eta)
        @variable(model, m[1:pb.nscenarios])
        @objective(model, Min, eta + 1/(1-cvar_lev) * sum(pb.probas[i] * m[i] for i in 1:pb.nscenarios))
        @constraint(model, m .>= 0 )
        @constraint(model, [i in 1:pb.nscenarios], m[i]>= fvalues[i] - eta)

        optimize!(model)

        eta_opt = JuMP.value(eta)
        push!(hist[:cvarvalues], eta_opt)
        @show(eta_opt)
    end

    #########################################################
    ## Problem solve: build and solve complete problem, exponential in constraints
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

    # # #########################################################
    # Problem solve: synchronous (un parallelized) version of PH
    # global y_sync = solve_randomized_sync(pb, maxtime=5, printstep=3*3, hist=hist)
    # println("\nSynchronous solve output is:")
    # display(y_sync)
    #
    # #########################################################
    # # Problem solve: synchronous (parallelized) version of PH
    # global y_par = solve_randomized_par(pb, maxtime=5, printstep=3, hist=hist)
    # println("\nRandom Par solve output is:")
    # display(y_par)
    #
    #
    # ########################################################
    # Problem solve: asynchronous (parallelized) version of PH
    global y_async = solve_randomized_async(pbcvar, maxtime=5, printstep=3*3, hist=hist, callback=callback)
    println("Asynchronous solve output is:")
    display(y_async)

    return
end

main()
#
Tf=12
Df=10
In = 20 # no. of cars
n_scen=2048

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
