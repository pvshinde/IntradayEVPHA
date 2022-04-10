using JuMP, GLPK, LinearAlgebra
using XLSX

# cd("./scenarios_10_DPs")


price_scen_to = Dict()
for i in 1:10
    table_1=XLSX.readxlsx("data_12stages\\data_price_to\\price_to_$i.xlsx")
    sh1=table_1["Sheet1"]
    price_scenarios_to=sh1["B2:M2049"]
    price_scen_to[i]=convert(Array{Float64,2},price_scenarios_to)
end

price_scen_from = Dict()
for i in 1:10
    table_2=XLSX.readxlsx("data_12stages\\data_price_from\\price_from_$i.xlsx")
    sh2=table_2["Sheet1"]
    price_scenarios_from=sh2["B2:M2049"]
    price_scen_from[i]=convert(Array{Float64,2},price_scenarios_from)
end

price_reg_to = Dict()
for i in 1:10
    table3=XLSX.readxlsx("data_12stages\\data_reg_price_to\\reg_price_to_$i.xlsx")
    sh3=table3["Sheet1"]
    price_scen_reg_to=sh3["B2:B2049"]
    price_reg_to[i]=convert(Array{Float64,2},price_scen_reg_to)
end

price_reg_from = Dict()
for i in 1:10
    table2=XLSX.readxlsx("data_12stages\\data_reg_price_from\\reg_price_from_$i.xlsx")
    sh4=table2["Sheet1"]
    price_scen_reg_from=sh4["B2:B2049"]
    price_reg_from[i]=convert(Array{Float64,2},price_scen_reg_from)
end

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
