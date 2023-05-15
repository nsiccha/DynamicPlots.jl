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
Base.show(io::IO, mime::MIME"text/markdown", what::Plot) = show(io, mime, what.markdown)

initial_figure(::Plot) = plot()
figure(what::Plot) = figure!(initial_figure(what), what)
# figure!(fig, ::Plot) = fig
figure!(fig, what::Plot, args...; kwargs...) = (
    what.func(fig, what.plot_args..., args...; what.plot_kwargs..., kwargs...); 
    fig
) 
do_nothing(args...; kwargs...) = nothing
func(::Plot) = do_nothing
plot_args(::Plot) = Tuple([])
plot_kwargs(::Plot) = (label="",)
Base.adjoint(what::Plot) = what
set_figs_path!(path::AbstractString) = (ENV["DYNAMIC_FIGS"] = path)
dir(::Plot) = get(ENV, "DYNAMIC_FIGS", joinpath(pwd(), "figs"))
md_dir(::Plot) = "/figs"
stem(what::Plot) = hash(what)
extension(what::Plot) = "png"
Base.basename(what::Plot) = "$(what.stem).$(what.extension)"
path(what::Plot) = joinpath(what.dir, what.basename)
md_path(what::Plot) = joinpath(what.md_dir, what.basename)
alt_text(what::Plot) = ""

function markdown(what::Plot)
    if !isfile(what.path)
        mkpath(what.dir)
        println("Saving $(what.path).")
        png(what.figure, what.path)
    end
    Markdown.parse("![$(what.alt_text)]($(what.md_path))")
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
Base.adjoint(what::Figure) = DynamicObjects.update(what, plots=what.plots')
Base.:+(lhs::Figure, rhs::Figure) = DynamicObjects.update(lhs, plots=lhs.plots .+ rhs.plots)

@dynamic_object Plotter <: Plot func::Function plot_args
# figure!(fig, what::Plotter) = (what.func(fig, what.plot_args...; what.plot_kwargs...); fig) 

@dynamic_object PlotSum <: Plot summands::AbstractArray
function figure!(fig, what::PlotSum, args...; kwargs...)
    for summand in what.summands 
        figure!(fig, summand, what.plot_args..., args...; kwargs...) 
    end
    fig
end
summands(what::Plot) = [what]
Base.:+(lhs::Plot, rhs::Plot) = PlotSum([lhs.summands..., rhs.summands...])

@dynamic_object Line <: Plot x y
func(what::Line) = plot!
plot_args(what::Line) = (what.x, what.y)

@dynamic_object Scatter <: Plot x y
func(what::Scatter) = scatter!
plot_args(what::Scatter) = (what.x, what.y)

@dynamic_object Histogram <: Plot x::AbstractArray
func(what::Histogram) = histogram!
plot_args(what::Histogram) = (what.x, )

@dynamic_object EmptyPlot <: Plot x y
initial_figure(::EmptyPlot) = plot(xaxis=false, yaxis=false, xticks=false, yticks=false)

end
  