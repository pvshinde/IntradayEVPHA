using JuMP, GLPK, LinearAlgebra
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
