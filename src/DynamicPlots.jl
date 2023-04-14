module DynamicPlots

export Plot, Figure, PlotSum, Line, Scatter, EmptyPlot#, PairPlot
using DynamicObjects
using Plots
import Markdown

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
alt_text(what::Plot) = ""
function markdown(what::Plot)
    if !isfile(what.path)
        if !isdir(what.dir)
            mkpath(what.dir)
        end
        println("Saving $(what.path).")
        png(what.figure, what.path)
    end
    Markdown.parse("![$(what.alt_text)]($(what.path))")
end

@dynamic_object Figure <: Plot plots::AbstractArray
subplots(what::Figure) = figure.(what.plots')
no_plots(what::Figure) = length(what.plots)
no_rows(what::Figure) = size(what.plots, 1)
no_cols(what::Figure) = size(what.plots, 2)
plot_width(what::Figure) = 400
plot_height(what::Figure) = what.plot_width
figure_kwargs(what::Figure) = (
    layout=(what.no_rows, what.no_cols), 
    size=(what.no_cols * what.plot_width, what.no_rows * what.plot_height)
)
extra_figure_kwargs(what::Figure) = NamedTuple()
initial_figure(what::Figure) = plot(what.subplots...; what.figure_kwargs..., what.extra_figure_kwargs...)

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




# What is actually the best way to show plots?

Base.show(io::IOContext{IOBuffer}, what::Plot) = display(what.markdown)
# Base.display(how, what::Plot) = display(what.markdown)
end
  