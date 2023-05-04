module DynamicPlots

export Plot, Figure, Plotter, PlotSum, Line, Scatter, Histogram, EmptyPlot
# export PairPlot
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
plot_args(what::Plot) = Tuple([])
plot_kwargs(what::Plot) = (label="",)

function markdown(what::Plot)
    if !isfile(what.path)
        mkpath(what.dir)
        println("Saving $(what.path).")
        png(what.figure, what.path)
    end
    Markdown.parse("![$(what.alt_text)]($(what.path))")
end
Base.show(io::IO, mime::MIME"text/markdown", what::Plot) = show(io, mime, what.markdown)

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
Base.adjoint(what::Figure) = DynamicObjects.update(what, plots=what.plots')
Base.:+(lhs::Figure, rhs::Figure) = DynamicObjects.update(lhs, plots=lhs.plots .+ rhs.plots)

@dynamic_object Plotter <: Plot func::Function plot_args
figure!(fig, what::Plotter) = (what.func(fig, what.plot_args...; what.plot_kwargs...); fig) 

@dynamic_object PlotSum <: Plot summands::AbstractArray
function figure!(fig, what::PlotSum)
    for summand in what.summands figure!(fig, summand, what.plot_args...; what.plot_kwargs...) end
    fig
end
summands(what::Plot) = [what]
Base.:+(lhs::Plot, rhs::Plot) = PlotSum([lhs.summands..., rhs.summands...])

@dynamic_object Line <: Plot x y
figure!(fig, what::Line) = (plot!(fig, what.x, what.y, what.plot_args...; what.plot_kwargs...); fig)

@dynamic_object Scatter <: Plot x y
figure!(fig, what::Scatter) = (scatter!(fig, what.x, what.y, what.plot_args...; what.plot_kwargs...); fig) 

@dynamic_object Histogram <: Plot x y
figure!(fig, what::Scatter) = (histogram!(fig, what.x, what.plot_args...; what.plot_kwargs...); fig) 


@dynamic_object EmptyPlot <: Plot x y
initial_figure(::EmptyPlot) = plot(xaxis=false, yaxis=false, xticks=false, yticks=false)
figure!(fig, ::EmptyPlot) = fig

end
  