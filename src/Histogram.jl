
# helper function to calculate the histogram
function historam!(histogram::Vector{Float64}, values::Vector{Float64}, bins::Int)::AbstractRange

    min, max = quantile(values, [0.01, 0.99])
    diff = max - min

    @inbounds @simd for value in values
        index = Int(floor(Int, bins * (value - min) / diff)) + 1
        if 1 <= index <= bins
            histogram[index] += 1
        end
    end

    return range(start=min, stop=max, length=bins)
end


"""
    getHistogram(workingDir::String, bins::Int; maxVal::Int=nothing)::AbstractMatrix

Returns Matrix of Histograms, one for every hour and every channel.

# Arguments:
- `workingDir::String`: folder of all root-Files
- `bins::Int`: Number of bins for the Spectrum
- `maxVal::Int`: Maximum number of events for Histogram calculation

# Output:
- `HistogramMatrix(x1, y1, x2, y2, x3, y3)`
"""
function getHistogram(workingDir::String, bins::Int; maxVal::Int=0)::AbstractMatrix

    # get all root files in the folder
    rootFiles = collectRoot(workingDir)

    # collect data
    HistogramMatrix = Matrix{Any}(undef, 6, length(rootFiles))

    # for each file
    Threads.@threads for i in eachindex(rootFiles)

        # file
        fname = rootFiles[i]

        #status
        println("Status: " * fname)

        # read data
        ROOTFile(fname) do f
            
            tree1 = LazyTree(f, "data1")

            # container for Integartion Values
            lenTree = (length(tree1) > maxVal > 0) ? maxVal : length(tree1)
            IntValues1 = Vector{Float64}(undef, lenTree)
            IntValues2 = Vector{Float64}(undef, lenTree)
            IntValues3 = Vector{Float64}(undef, lenTree)

            # iterate over events of data1
            @inbounds for i in 1:lenTree
                IntValues1[i] = simpson(mean(@view tree1[i].ch0[1:20]) .- @view tree1[i].ch0[20:end])
                IntValues2[i] = simpson(mean(@view tree1[i].ch1[1:20]) .- @view tree1[i].ch1[20:end])
                IntValues3[i] = simpson(mean(@view tree1[i].ch2[1:20]) .- @view tree1[i].ch2[20:end])
            end

            # allocate histogram
            Histogram1 = zeros(Float64, bins)
            Histogram2 = zeros(Float64, bins)
            Histogram3 = zeros(Float64, bins)

            # calculate histogram
            HistogramMatrix[1,i] = historam!(Histogram1, IntValues1, bins)
            HistogramMatrix[3,i] = historam!(Histogram2, IntValues2, bins)
            HistogramMatrix[5,i] = historam!(Histogram3, IntValues3, bins)

            # save histogram
            HistogramMatrix[2,i] = Histogram1/maximum(Histogram1)
            HistogramMatrix[4,i] = Histogram2/maximum(Histogram2)
            HistogramMatrix[6,i] = Histogram3/maximum(Histogram3)
        
        end

    end

    return HistogramMatrix

end