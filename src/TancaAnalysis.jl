module TancaAnalysis

using UnROOT, Statistics, StructArrays, Dates, Simpson

include("CollectRoot.jl")
include("Types.jl")
include("ArduinoData.jl")
include("Histogram.jl")

export getArduinoData, getHistogram

end # module TancaAnalysis
