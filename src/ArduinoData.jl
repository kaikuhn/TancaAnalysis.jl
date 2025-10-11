
# src/ReadData.jl

# helper function to assign time to part
function calculateIndex(startTime::Int, timeStamp::Int, parts::Int)::Union{Int,Nothing}
    timeSpan = 60*60*10^9
    index = ceil(Int, (timeStamp - startTime) / timeSpan * parts)
    return (1 <= index <= parts) ? index : nothing
end


"""
    getArduinoData(workingDir::String, parts::Int)

Reads all the root Data created by the TancaDataAcquisition program from one woking directory.

# Arguments:
- `workingDir::String`: folder of all root-Files
- `parts::Int`: Number of Parts each hour is devided in for mean values

# Output:
- `StructArrays(containerData2)`
- `StructArrays(containerData3)`

# Structure:
struct Data2\n
\t time::Int
\t pAtm::Float64
\t rate::Float64 \n
end


struct Data3 \n
\t time::Int
\t t1::Float64
\t t2::Float64
\t t3::Float64
\t t4::Float64
\t h1::Float64
\t h2::Float64
\t h3::Float64
\t h4::Float64 \n
end
"""
function getArduinoData(workingDir::String, parts::Int)

    # get all root files in the folder
    rootFiles = collectRoot(workingDir)

    # container for data
    containerData2 = Data2[]
    containerData3 = Data3[]

    # for each file
    for i in eachindex(rootFiles)

        # file
        fname = rootFiles[i]

        # status
        println("Status: " * fname)

        # calculate start time
        year  = parse(Int, fname[end-23:end-20])
        month = parse(Int, fname[end-18:end-17])
        day   = parse(Int, fname[end-15:end-14])
        hour  = parse(Int, fname[end-12:end-11])

        startTime = DateTime(year, month, day, hour)
        startTimeInNs = round(Int, Dates.value(startTime - DateTime(1970,1,1))) * 10^6

        # prepare data containers
        ts_data2 = zeros(UInt128, parts)
        rate, pressure = [zeros(Float64, parts) for _ in 1:2]

        ts_data3 = zeros(UInt128, parts)
        t1, t2, t3, t4, h1, h2, h3, h4 = [zeros(Float64, parts) for _ in 1:8]

        # prepare counts
        count2 = zeros(Int, parts)
        count3 = zeros(Int, parts)

        # read data
        ROOTFile(fname) do f

            tree2 = LazyTree(f, "data2")
            tree3 = LazyTree(f, "data3")

            # iterate over events of data2
            for event in tree2
                index = calculateIndex(startTimeInNs, event.ts_data2, parts)

                if (!isnothing(index) && !isnan(event.rate) && !isnan(event.pressure))
                    ts_data2[index] += UInt128(event.ts_data2)
                    rate[index] += event.rate
                    pressure[index] += event.pressure
                    
                    count2[index] += 1
                end
            end

            # iterate over events of data3
            for event in tree3
                index = calculateIndex(startTimeInNs, event.ts_data3, parts)

                if (!isnothing(index))
                    ts_data3[index] += UInt128(event.ts_data3)
                    t1[index] += event.tanca_t1
                    t2[index] += event.tanca_t2
                    t3[index] += event.tanca_t3
                    t4[index] += event.tanca_t4
                    h1[index] += event.tanca_h1
                    h2[index] += event.tanca_h2
                    h3[index] += event.tanca_h3
                    h4[index] += event.tanca_h4

                    count3[index] += 1
                end
            end

        end

        for (index, count) in enumerate(count2)
            if (count != 0)
                push!(containerData2,
                    Data2(
                        round(Int, ts_data2[index] / count), 
                        pressure[index] / count, 
                        rate[index] / count
                    )
                )
            end
        end

        for (index, count) in enumerate(count3)
            if (count != 0)
                push!(containerData3,
                    Data3(
                        round(Int, ts_data3[index] / count),
                        t1[index] / count,
                        t2[index] / count,
                        t3[index] / count,
                        t4[index] / count,
                        h1[index] / count,
                        h2[index] / count,
                        h3[index] / count,
                        h4[index] / count
                    )
                )
            end
        end
    end

    return StructArray(containerData2), StructArray(containerData3)

end
