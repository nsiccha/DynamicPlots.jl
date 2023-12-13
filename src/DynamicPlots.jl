module DynamicPlots

export Plot, Figure, Plotter, PlotSum, Line, Scatter, Histogram, EmptyPlot, Hline, Vline, Contourf
export PairPlot, PairPlots, ECDFPlot
export add_description
# export PairPlot
using DynamicObjects
using Plots
using Statistics, LinearAlgebra
import Markdown

"""
A common base type for plots.
"""
@dynamic_type Plot 
Base.show(io::IO, mime::MIME"text/markdown", what::Plot) = show(io, mime, what.markdown)
Base.show(io::IO, mime::MIME"image/png", what::Plot) = show(io, mime, what.figure)

initial_figure(::Plot) = plot()
figure(what::Plot) = figure!(what.initial_figure, what)
# figure!(fig, ::Plot) = fig
figure!(fig, what::Plot, args...; kwargs...) = (
    what.func(fig, what.plot_args..., args...; what.plot_kwargs..., kwargs...); 
    fig
) 
do_nothing(args...; kwargs...) = nothing
func(::Plot) = do_nothing
plot_args(::Plot) = Tuple([])
auto_plot_keys(::Plot) = [
    :label, 
    :alpha, :color, :marker, :markersize, :markerstrokewidth,
    :xaxis, :yaxis, :xscale, :yscale, :xlabel, :ylabel,
    :xlim, :ylim,
    :legend, :colorbar, :title, :plot_title, :link, :levels, :c, :fillrange
]
default_plot_kwargs(::Plot) = (label="", markerstrokewidth=0)
auto_plot_kwargs(what::Plot) = (;[
    [key, getproperty(what, key)] 
    for key in what.auto_plot_keys if hasproperty(what, key)
]...)
extra_plot_kwargs(::Plot) = NamedTuple()
plot_kwargs(what::Plot) = merge(
    what.default_plot_kwargs, 
    what.auto_plot_kwargs, 
    what.extra_plot_kwargs
)
Base.adjoint(what::Plot) = what
set_figs_path!(path::AbstractString) = (ENV["DYNAMIC_FIGS"] = path)
dir(::Plot) = get(ENV, "DYNAMIC_FIGS", joinpath(pwd(), "figs"))
set_md_path!(path::AbstractString) = (ENV["DYNAMIC_MD"] = path)
md_dir(::Plot) = get(ENV, "DYNAMIC_MD", "./figs")
stem(what::Plot) = hash(what)
extension(what::Plot) = "png"
Base.basename(what::Plot) = "$(what.stem).$(what.extension)"
path(what::Plot) = joinpath(what.dir, what.basename)
md_path(what::Plot) = joinpath(what.md_dir, what.basename)
alt_text(what::Plot) = ""

function markdown(what::Plot)
    if !isfile(what.path)
        mkpath(what.dir)
        @debug "Saving $(what.path)."
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

auto_figure_keys(f::Figure) = vcat(
    auto_plot_keys(f),
    [:layout, :size, :margin]
)
default_figure_kwargs(what::Figure) = (
    layout=(what.no_rows, what.no_cols), 
    size=(what.no_cols * what.plot_width, what.no_rows * what.plot_height),
    margin=(10, :mm)
)
auto_figure_kwargs(what::Figure) = (;[
    [key, getproperty(what, key)] 
    for key in what.auto_figure_keys if hasproperty(what, key)
]...)
extra_figure_kwargs(::Figure) = NamedTuple()
figure_kwargs(::Plot) = NamedTuple()
figure_kwargs(what::Figure) = merge(
    what.default_figure_kwargs, 
    what.auto_figure_kwargs, 
    what.extra_figure_kwargs
)
initial_figure(what::Figure) = plot(what.subplots...; what.figure_kwargs...)
Base.adjoint(what::Figure) = DynamicObjects.update(what, plots=what.plots')
Base.:+(lhs::Figure, rhs::Figure) = DynamicObjects.update(lhs, plots=lhs.plots .+ rhs.plots)
Base.vcat(figures::Figure...) = DynamicObjects.update(figures[1], plots=vcat(getproperty.(figures, :plots)...))
Base.hcat(figures::Figure...) = DynamicObjects.update(figures[1], plots=hcat(getproperty.(figures, :plots)...))

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
func(::Line) = plot!
plot_args(what::Line) = (what.x, what.y)

@dynamic_object Scatter <: Plot x y
func(::Scatter) = scatter!
plot_args(what::Scatter) = (what.x, what.y)

@dynamic_object Histogram <: Plot x::AbstractArray
func(::Histogram) = histogram!
plot_args(what::Histogram) = (what.x, )

@dynamic_object Hline <: Plot y::AbstractArray
func(::Hline) = hline!
plot_args(what::Hline) = (what.y, )

@dynamic_object Vline <: Plot x::AbstractArray
func(::Vline) = vline!
plot_args(what::Vline) = (what.x, )

@dynamic_object EmptyPlot <: Plot x y
initial_figure(::EmptyPlot) = plot(xaxis=false, yaxis=false, xticks=false, yticks=false)

ECDFPlot(x::AbstractVector; kwargs...) = Line(sort(x), range(0, 1, length(x)); title="ECDF", kwargs...)

@dynamic_object Contourf <: Plot x y z
func(::Contourf) = contourf!
plot_args(what::Contourf) = (what.x, what.y, what.z)

PairPlot(samples::AbstractMatrix, i, j; histogram=true, kwargs...) = if i < j 
    EmptyPlot() + Scatter(samples[i, :], samples[j, :], alpha=.25, kwargs...)
elseif histogram && i == j 
    Histogram(samples[i,:]) 
else
    EmptyPlot()
end

PairPlots(samples::AbstractMatrix; n=min(8,size(samples, 1)), idxs=trunc.(Int, range(1, size(samples, 1), n)), show_svd=false, kwargs...) = if show_svd 
    m = mean(samples, dims=2)
    U, S, V = svd(cov(samples'))
    svd_samples = Diagonal(sqrt.(S)) \ U' * (samples .- m)
    PairPlots(samples; idxs=idxs, show_svd=false, kwargs...) + 
    PairPlots(svd_samples; idxs=idxs, show_svd=false, histogram=false, kwargs...)'
else 
    Figure([
        PairPlot(samples, i, j; kwargs...)
        for j in idxs, i in idxs
    ])
end

add_description(f::Figure, d::AbstractString) = begin 
    figure_kwargs = f.figure_kwargs
    plot_title = d
    plot_title_height = 40 * (2+count("\n", d))
    size = (figure_kwargs.size[1], figure_kwargs.size[2] + plot_title_height)
    update(f, figure_kwargs=(
        f.figure_kwargs..., 
        plot_title=plot_title,
        # plot_titlefonthalign=:left, 
        plot_titlelocation=:left,
        plot_titlevspan=plot_title_height/size[2],
        size=size
    ))
end
add_description(d::AbstractString) = Base.Fix2(add_description, d)

end
  