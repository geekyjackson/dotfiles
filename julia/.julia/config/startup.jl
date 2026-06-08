if isinteractive()
    try
        @eval using BenchmarkTools
    catch e
        @warn "error while importing BenchmarkTools" e
    end
    
    try
        @eval using Revise
    catch e
        @warn "error while importing Revise" e
    end
end

