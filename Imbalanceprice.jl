using JuMP, GLPK, LinearAlgebra
using MAT

Tf = 48 # no. of time slots
Wf = 20 # no. of scenarios

lambda_Im = zeros(Wf, Tf)
lambda_Ip = zeros(Wf, Tf)
# sigmaU = zeros(Wf, Tf)
# sigmaD = zeros(Wf, Tf)

#  lambda_A, lambda_U, lambda_D, TT, t0, SOC_0 inputs from .mat files
DAvars = matread("generate_resevation.mat")
RTvars = matread("regulating.mat")

lambda_U = get(RTvars,"priceup",3) #up regulation price for time t in scenario w
lambda_D = get(RTvars,"pricedown",3)  #down regulation price for time t in scenario w
lambda_A = get(DAvars,"lambda_A",3) #spot price for time t in scenario w

sigmaU = get(RTvars,"sigplus",3)
sigmaD = get(RTvars,"sigminus",3)

Q = get(DAvars,"Q",3)
SoC_init = get(DAvars,"SOC_0",3)
d0 = get(DAvars,"t0",3)
DD = get(DAvars,"TT",3)

for w = 1:Wf
    for t = 1:Tf
        # sigmaU[w, t] == lambda_U[w, t] - lambda_A[w, t] #equation 5
        # sigmaD[w, t] == lambda_D[w, t] - lambda_A[w, t] # equation 6

        if sigmaD[w, t] < 0   # equation 7
            lambda_Ip[w, t] = lambda_D[w, t]
        else sigmaD[w, t] == 0
            lambda_Ip[w, t] = lambda_A[w, t]
        end

        if sigmaU[w, t] < 0 # equation 8
            lambda_Im[w, t] = lambda_U[w, t]
        else sigmaU[w, t] == 0
            lambda_Im[w, t] = lambda_A[w, t]
        end
    end
end
