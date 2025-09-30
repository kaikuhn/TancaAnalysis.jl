
# helper function to calculate the histogram
function historam!(histogram::Vector{Float64}, values::Vector{Float64}, bins::Int) 

    min, max = extrema(values)

    for value in values
        
        index = clamp(Int(floor(bins * (value - min) / (max - min))) + 1, 1, bins)
        histogram[index] += 1

    end
end


"""
    getSpectrum(workingDir::String)

Returns List of Spectrums, one for every hour.

# Arguments:
- `workingDir::String`: folder of all root-Files
- `bins::Int`: Number of bins for the Spectrum

# Output:
- `Array(Histogram)`
"""
function getHistogram(workingDir::String, bins::Int)

    # get all root files in the folder
    rootFiles = collectRoot(workingDir)

    # collect data
    HistogramList = Vector{Any}(undef, length(rootFiles))

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
            IntValues = Vector{Float64}(undef, length(tree1)*3)

            # iterate over events of data1
            index = 1
            for event in tree1
                for ch in (event.ch0, event.ch1, event.ch2)
                    IntValues[index] = simpson(mean(@view ch[1:20]) .- ch)
                    index += 1
                end
            end

            # allocate histogram
            Histogram = zeros(Float64, bins)

            # calculate histogram
            historam!(Histogram, IntValues, bins)

            # save histogram
            HistogramList[i] = Histogram/maximum(Histogram)
        
        end

    end

    return HistogramList

end