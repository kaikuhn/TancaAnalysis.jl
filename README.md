# TancaAnalysis.jl
Julia package to analyze the data recorded with the TancaDataAcquisition package

## Description

This project is the extension to the TancaDataAcquisition project. It is a package wirtten in julia, offering two functions to analyse the data recorded with the TancaDataAcquisition program.

## Get the Arduino Data

The function `readData(workingDir::String, parts::Int)` returns two StructArrays with data mainly recorded with the Arduino Uno:

```
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
```

### Usage example

```
using TancaAnalysis, Plots, Dates

data2, data3 = getArduinoData("testdata/", 3)

# data
time  = DateTime(1970, 1, 1) .+ Millisecond.(div.(data2.time, 10^6))
rate  = data2.rate
pAtm  = data2.pAtm

time_str = Dates.format.(time, "yyyy-mm-dd HH") 

# plot rate on the left y axis
plot(time_str, rate, color=:blue, label="Rate", ylabel="Rate / Hz", xlabel="Time", dpi=600)

# plot pressure on the right y axis
plot!(twinx(), time_str, pAtm, color=:red, label="Pressure", ylabel="Pressure / mbar")

savefig("RatePressure.png")
```

#### Output

![RatePressure](plots/RatePressure.png)

## Get the spectrum

The function `getHistogram(workingDir::String, bins::Int)` returns a list of Histograms of the Area under the mesured peaks for eeach hour:

```
    getHistogram(workingDir::String, bins::Int; maxVal::Int=nothing)::AbstractMatrix

Returns Matrix of Histograms, one for every hour and every channel.

# Arguments:
- `workingDir::String`: folder of all root-Files
- `bins::Int`: Number of bins for the Spectrum
- `maxVal::Int`: Maximum number of events for Histogram calculation

# Output:
- `HistogramMatrix(x1, y1, x2, y2, x3, y3)`
```

### Usage example

```
using TancaAnalysis, Plots

Hist = getHistogram("testdata/", 200; maxVal=1000000)

# plot histogram
plot(Hist[1,1], Hist[2,1], label="Histogram CH0", xlabel="∝Energy", ylabel="Density", dpi=600)
plot!(Hist[3,1], Hist[4,1], label="Histogram CH1")
plot!(Hist[5,1], Hist[6,1], label="Histogram CH2")

savefig("Histogram.png")
```

#### Output

![Histogram](plots/Histogram.png)