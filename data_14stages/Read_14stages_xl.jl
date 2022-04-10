using JuMP, GLPK, LinearAlgebra
using XLSX

# cd("./scenarios_10_DPs")

price_scen_to = Dict()
for i in 1:10
    table_1=XLSX.readxlsx("price_to_$i.xlsx")
    sh1=table_1["Sheet1"]
    price_scenarios_to=sh1["B2:O8193"]
    price_scen_to[i]=convert(Array{Float64,2},price_scenarios_to)
end

price_scen_from = Dict()
for i in 1:10
    table_2=XLSX.readxlsx("price_from_$i.xlsx")
    sh2=table_2["Sheet1"]
    price_scenarios_from=sh2["B2:O8193"]
    price_scen_from[i]=convert(Array{Float64,2},price_scenarios_from)
end

price_reg_to = Dict()
for i in 1:10
    table3=XLSX.readxlsx("reg_price_to_$i.xlsx")
    sh3=table3["Sheet1"]
    price_scen_reg_to=sh3["B2:B8193"]
    price_reg_to[i]=convert(Array{Float64,2},price_scen_reg_to)
end

price_reg_from = Dict()
for i in 1:10
    table2=XLSX.readxlsx("reg_price_from_$i.xlsx")
    sh2=table2["Sheet1"]
    price_scen_reg_from=sh2["B2:B8193"]
    price_reg_from[i]=convert(Array{Float64,2},price_scen_reg_from)
end

# price_DA = [price_scenarios_1[1,1] price_scenarios_2[1,1] price_scenarios_3[1,1] price_scenarios_4[1,1] price_scenarios_5[1,1] price_scenarios_6[1,1] price_scenarios_7[1,1] price_scenarios_8[1,1] price_scenarios_9[1,1] price_scenarios_10[1,1]]

price_DA = [price_scen_to[1][1,1] price_scen_to[2][1,1] price_scen_to[3][1,1] price_scen_to[4][1,1] price_scen_to[5][1,1] price_scen_to[6][1,1] price_scen_to[7][1,1] price_scen_to[8][1,1] price_scen_to[9][1,1] price_scen_to[10][1,1]]

scen_reg_from = zeros(8192,10)
scen_reg_to = zeros(8192,10)

scen_reg_from = [price_reg_from[1] price_reg_from[2] price_reg_from[3] price_reg_from[4] price_reg_from[5] price_reg_from[6] price_reg_from[7] price_reg_from[8] price_reg_from[9] price_reg_from[10]]
scen_reg_to = [price_reg_to[1] price_reg_to[2] price_reg_to[3] price_reg_to[4] price_reg_to[5] price_reg_to[6] price_reg_to[7] price_reg_to[8] price_reg_to[9] price_reg_to[10]]

sigmaU_14=zeros(8192,10)
sigmaD_14=zeros(8192,10)
lambda_Ip_14=zeros(8192,10)
lambda_Im_14=zeros(8192,10)

for d = 1:10
    for w = 1:8192
        sigmaU_14[w,d] = scen_reg_from[w,d] - price_DA[d]
        sigmaD_14[w,d] = scen_reg_to[w,d] - price_DA[d]

        if sigmaD_14[w,d] < 0
            lambda_Ip_14[w,d] = scen_reg_to[w,d]
        elseif sigmaD_14[w,d] == 0
            lambda_Ip_14[w,d] = price_DA[d]
        end

        if sigmaU_14[w,d] > 0 # equation 8
            lambda_Im_14[w,d] = scen_reg_from[w,d]
        elseif sigmaU_14[w,d] == 0
            lambda_Im_14[w,d] = price_DA[d]
        end
    end
end
#
# # cd("..")
