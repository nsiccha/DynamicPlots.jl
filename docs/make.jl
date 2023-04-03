using Documenter
push!(LOAD_PATH,"src/")
using DynamicPlots

makedocs(
    sitename = "DynamicPlots",
    format = Documenter.HTML(),
    modules = [DynamicPlots]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/nsiccha/DynamicPlots.jl.git"
)
