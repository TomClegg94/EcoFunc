#Function that preforms the simualtions

"""
# Simulate

    simulate(p::Dict{Symbol,Any}, u0::Array{Float64},start::Int64=0, stop::Int64=500)

Preforms the simulation over a given time period.

## Arguments
- 'p::Dict{Symbol,Any}' : Dictionary containing parameters (see `make_parameters`).
- `u0::Array{Float64}` : Initial biomass period.
- 'start::Int64=0' : Starting timepoint.
- 'stop::Int64=500' : End timepoint.

"""

function simulate(p::Parameter, u0::Array{Float64},
    start::Int64=0, stop::Int64=500, col::Float64=1.0)

    @assert stop > start
    @assert length(u0) == p.n_sp
    @assert length(find(x -> isa(x,Cpool) , p.Eco)) == 1
    @assert length(find(x -> isa(x,Spool) , p.Eco)) == 1

    # Pre-allocate the timeseries matrix
    t = (float(start), float(stop))
    t_keep = collect(start:col:stop)

    # Perform the actual integration
    prob = DifferentialEquations.ODEProblem(dcdt, u0, t, p)
    sol = DifferentialEquations.solve(prob ,  dtmax = 1, saveat=t_keep, dense=false,
    save_timeseries=false, maxiters = 1e10)

    return(sol)
end
