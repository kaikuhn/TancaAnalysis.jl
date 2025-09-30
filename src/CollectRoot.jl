
# src/CollectRoot.jl

# collect all .root files recursively from one directory
function collectRoot(folderPath::String)::Vector{String}
    
    rootFiles = String[]

    for (dirpath, dirs, files) in walkdir(folderPath)
        for f in files
            if endswith(f, ".root")
                push!(rootFiles, joinpath(dirpath, f))
            end
        end
    end

    return rootFiles
end