using Plots
using XLSX
using LaTeXStrings


## Plot one -- price scenarios
table=XLSX.readxlsx("price_to_10.xlsx")
sh1=table["Sheet1"]
price_scenarios_10=sh1["B2:M2049"]
price_scenarios_10=convert(Array{Float64,2},price_scenarios_10)

# pgfplots()

plot(
    [0:10],
    price_scenarios_10[:, 2:end]',
    # layout = grid(4, 1),
    size = (500, 450),
    legend = false,
    # label = ["Price"],
    # ylabel = ["SEK/MWh"],
    framestyle = :box,
    # title = ["(a)" "(b)" "(c)" "(d)"],
    # titleloc = :center,
    # titlefont = font(8),
    xaxis = (L"Stage", (0,10), 0:1:10, font(10, "Computer Modern")),
    yaxis = (L"Price~~[Euro/MWh]", font(10, "Computer Modern")),
    # minorgrid=true
    yminorgrid=true
)


savefig("plots/price_input_10.pdf")

## plot 2 -- selling all DPs
plot_font = "Computer Modern"
default(fontfamily=plot_font,
        linewidth=2, framestyle=:box, label=nothing, grid=false)
scalefontsizes(1.3)

labels =["DP$i" for i in 1:10] 
plt = plot(legendfontsize=10, legendfontfamily=plot_font)
# plt = plot()
for i in 1:10
    plot!(plt,
        [1:14],
        mean(pA[i], dims=1)',
        size = (500, 350),
        framestyle = :box,
        label = labels[i],
        xaxis = (L"Stage", (1,14), 1:1:14, font(10, "Computer Modern")),
        yaxis = (L"Volume~~[kWh]", font(10, "Computer Modern")),
        grid=true
    )
end

savefig("plots/selling_all_DPs.pdf")

## plot 3 -- 
# Plot 2: Subplot i) SOC and pcharging of first 10 EVs  
# X axis: delivery products
# Y axis: battery levels (SOC) or kWh (charging load)
# Subplot ii)  aggregate charging pattern (not so much fun but we can put both if required) of the whole fleet
# X axis: delivery products
# Y axis: kWh (charging)

for j in 0:4
    labels =["EV$(i + j*10)" for i in 1:10] 
    plt = plot(legendfontsize=10, legendfontfamily=plot_font, legend=:topleft)
    # plt = plot()
    for i in 1:10
        plot!(plt,
            [1:10],
            mean(SoC[i + j*10], dims=1)',
            size = (500, 350),
            framestyle = :box,
            label = labels[i],
            xaxis = (L"DP", (1,10), 1:1:10, font(10, "Computer Modern")),
            yaxis = (L"SoC~~[kWh]", font(10, "Computer Modern")),
            grid=true
        )
    end
    ylims!((0,40))
    savefig("plots/EVs_SoC_$j.pdf")
    display(plt)
end

plt = Dict()
for j in 0:4
    labels =["EV$(i + j*10)" for i in 1:10] 
    plt[j] = plot(legendfontsize=10, legendfontfamily=plot_font, legend=:topleft)
    # plt = plot()
    for i in 1:10
        plot!(plt[j],
            [1:10],
            mean(p_ch[i + j*10], dims=1)',
            size = (500, 300),
            framestyle = :box,
            label = labels[i],
            xaxis = (L"DP", (1,10), 1:1:10, font(10, "Computer Modern")),
            yaxis = (L"Charging~Power~[kW]", font(10, "Computer Modern")),
            grid=true
        )
    end
    ylims!((0,13))
    savefig("plots/EVs_p_ch_$j.pdf")
    display(plt[j])
end

## aggregated charging pattern
plt_agg = plot(legendfontsize=10, legendfontfamily=plot_font, legend=:topleft)
agg_p_ch = reduce(+, [mean(p_ch[i], dims=1) for i in 1:50])

plot!(plt_agg,
    [1:10],
    agg_p_ch',
    size = (500, 300),
    framestyle = :box,
    xaxis = (L"DP", (1,10), 1:1:10, font(10, "Computer Modern")),
    yaxis = (L"Charging~Power~[kW]", font(10, "Computer Modern")),
    grid=true
)

# ylims!((0,13))
savefig("plots/agg_charging.pdf")
display(plt_agg)

## alternative with two y axes

labels =["EV$(i + 30)" for i in 1:10] 
plt = plot(legendfontsize=8, legendfontfamily=plot_font, legend=:topleft, ylims=(0,14))
for i in 1:10
    plot!(plt,
        [1:10],
        mean(p_ch[i + 3*10], dims=1)',
        size = (500, 350),
        framestyle = :box,
        label = labels[i],
        xaxis = (L"DP", (1,10), 1:1:10, font(10, "Computer Modern")),
        yaxis = (L"Charging~Power~[kW]", font(10, "Computer Modern")),
        grid=true,
        left_margin = 5Plots.mm, right_margin = 15Plots.mm
    )
end


p = twinx()
plot!(p,
    [1:10],
    agg_p_ch',
    size = (500, 350),
    framestyle = :box,
    xaxis = (L"DP", (1,10), 1:1:10, font(10, "Computer Modern")),
    yaxis = (L"Aggregated~Charging~Power~[kW]", font(10, "Computer Modern")),
    grid=:off,
    label = "Aggregated",
    ylims=(0,100),
    legendfontsize=8,
    linestyle = :dash,
    linecolor = :red,
    # y_foreground_color_axis=:red,
    left_margin = 5Plots.mm, right_margin = 15Plots.mm
)

savefig("./plots/EV_charging_2_ax.pdf")

# a = 1:10
# b = rand(10)
# plot(a,b, label = "randData", ylabel = "Rand data",color = :red, 
    # legend = :topleft, grid = :off, xlabel = "numbers",left_margin = 5Plots.mm, right_margin = 15Plots.mm)
# plot!(p,a,log.(a), label = L"log(x)", legend = :topright, 
    #  box = :on, grid = :off, ylabel = "y label 2",left_margin = 5Plots.mm, right_margin = 15Plots.mm)