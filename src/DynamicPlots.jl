module DynamicPlots

export Plot, Figure, PlotSum, Line, Scatter, EmptyPlot
using DynamicObjects
using Plots


"""
A common base type for plots.
"""
@dynamic_type Plot 

initial_figure(::Plot) = plot()
figure(what::Plot) = figure!(initial_figure(what), what)
figure!(fig, ::Plot) = fig
Base.adjoint(what::Plot) = what
dir(what::Plot) = "figs"
path(what::Plot) = "$(what.dir)/$(hash(what)).png"
function markdown(what::Plot)
    if !isfile(what.path)
        if !isdir(what.dir)
            mkpath(what.dir)
        end
        png(what.figure, what.path)
    end
    "![]($(what.path))" 
end

@dynamic_object Figure <: Plot plots::AbstractArray
subplots(what::Figure) = figure.(what.plots')
no_plots(what::Figure) = length(what.plots)
no_rows(what::Figure) = size(what.plots, 1)
no_cols(what::Figure) = size(what.plots, 2)
figure_kwargs(what::Figure) = (
    layout=(what.no_rows, what.no_cols), 
    size=(800, 800 * what.no_rows / what.no_cols)
)
initial_figure(what::Figure) = plot(what.subplots...; what.figure_kwargs...)

@dynamic_object PlotSum <: Plot summands::AbstractArray
# no_plots(what::PlotSum) = length(what.summands)
function figure!(fig, what::PlotSum)
    for summand in what.summands figure!(fig, summand) end
    fig
end
summands(what::Plot) = [what]
Base.:+(lhs::Plot, rhs::Plot) = PlotSum([lhs.summands..., rhs.summands...])

@dynamic_object Line <: Plot x y
figure!(fig, what::Line) = (plot!(fig, what.x, what.y, label=""); fig)

@dynamic_object Scatter <: Plot x y
figure!(fig, what::Scatter) = (scatter!(fig, what.x, what.y, label=""); fig) 

@dynamic_object EmptyPlot <: Plot x y
initial_figure(::EmptyPlot) = plot(xaxis=false, yaxis=false, xticks=false, yticks=false)
figure!(fig, ::EmptyPlot) = fig


PairPlot(what, i, j) = i < j ? ScatterPlot(
    what.unconstrained_draws[:, i], what.unconstrained_draws[:, j]
) : EmptyPlot()

# What is actually the best way to show plots?

# Base.show(io::IO, what::Plot) = display(what.markdown) 
# Base.display(how, what::Plot) = display(what.markdown)
end
  